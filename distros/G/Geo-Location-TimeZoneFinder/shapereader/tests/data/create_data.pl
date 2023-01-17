#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Encode     qw(encode);
use List::Util qw(any reduce);
use Time::Piece;

my $SHPT_NULL        = 0;
my $SHPT_POINT       = 1;
my $SHPT_POLYLINE    = 3;
my $SHPT_POLYGON     = 5;
my $SHPT_MULTIPOINT  = 8;
my $SHPT_POINTZ      = 11;
my $SHPT_POLYLINEZ   = 13;
my $SHPT_POLYGONZ    = 15;
my $SHPT_MULTIPOINTZ = 18;
my $SHPT_POINTM      = 21;
my $SHPT_POLYLINEM   = 23;
my $SHPT_POLYGONM    = 25;
my $SHPT_MULTIPOINTM = 28;
my $SHPT_MULTIPATCH  = 31;

my %ENCODING_FOR = (
    0x13 => 'cp932',
    0x4d => 'cp936',
    0x4e => 'cp949',
    0x4f => 'cp950',
    0x57 => 'cp1252',
    0x58 => 'cp1252',
);

sub pack_dbf_field {
    my %h = (
        name           => q{},
        type           => 'C',
        length         => 0,
        decimal_places => 0,
        @_
    );

    my $bytes = pack 'a11aC20', $h{name}, $h{type}, (0) x 4, $h{length},
        $h{decimal_places}, (0) x 14;
    return $bytes;
}

sub get_field_size {
    my $field = shift;

    my $size = $field->{length};
    if ($field->{type} eq 'C') {
        $size |= ($field->{decimal_places} // 0) << 8;
    }
    return $size;
}

sub pack_dbf_header {
    my (%h) = @_;

    my @reserved = (0) x 20;
    $reserved[17] = $h{ldid};

    my @packed_fields = map { pack_dbf_field(%{$_}) } @{$h{fields}};

    $h{header_size} = reduce { $a + length $b } 33, @packed_fields;
    $h{record_size} = reduce { $a + get_field_size($b) } 1, @{$h{fields}};

    my $bytes = pack 'C4LS2C20', $h{version}, $h{year} - 1900, $h{month},
        $h{day}, $h{num_records}, $h{header_size}, $h{record_size}, @reserved;
    for my $field (@packed_fields) {
        $bytes .= $field;
    }
    $bytes .= "\r";

    return $bytes;
}

sub get_datetime {
    my $tp = shift;

    my $jd   = $tp->julian_day + 0.5;
    my $day  = int $jd;
    my $usec = 86400000 * ($jd - $day);

    return ($day, $usec);
}

sub write_dbf {
    my (%args) = @_;

    my $file   = $args{file};
    my %header = (
        version     => 0x03,
        year        => 2022,
        month       => 11,
        day         => 6,
        num_records => 0,
        header_size => 0,
        record_size => 0,
        ldid        => 0x57,
        fields      => [],
        %{$args{header}}
    );
    my @records = @{$args{records}};

    $header{num_records} = scalar @records;

    my $is_foxpro = any { $header{version} == $_ } (0x30, 0x31, 0x32);

    my $encoding = $ENCODING_FOR{$header{ldid}};
    my @fields   = @{$header{fields}};

    open my $fh, '>:raw', $file or die "Can't open $file: $!";
    print {$fh} pack_dbf_header(%header);
    for my $record (@records) {
        my @values  = @{$record};
        my $deleted = shift @values;
        print {$fh} pack 'A', $deleted;
        my $i = 0;
        for my $value (@values) {
            my $field  = $fields[$i];
            my $name   = $field->{name};
            my $type   = $field->{type};
            my $places = $field->{decimal_places} // 0;
            my $size   = get_field_size($field);
            my $bytes;
            if ($type eq 'C') {
                $bytes = pack "A$size",
                    defined $value ? encode($encoding, $value) : q{};
            }
            elsif ($type eq 'D') {
                $bytes
                    = pack "A$size", defined $value
                    ? sprintf "%0*s", $size, $value->ymd(q{})
                    : q{};
            }
            elsif ($type eq 'F' || $type eq 'N') {
                $bytes
                    = pack "A$size",
                    defined $value
                    ? sprintf "%*.*f", $size, $places, $value
                    : q{};
            }
            elsif ($type eq 'I' || $type eq '+') {
                $bytes = pack "l<", defined $value ? $value : 0;
            }
            elsif ($type eq 'L') {
                $bytes = pack "A", defined $value ? $value : q{ };
            }
            elsif ($type eq 'O' || ($type eq 'B' && $is_foxpro)) {
                $bytes = pack "d<", defined $value ? $value : 0.0;
            }
            elsif ($type eq 'T' || $type eq '@') {
                $bytes = pack "l<l<",
                    defined $value ? get_datetime($value) : 0 x 2;
            }
            elsif ($type eq 'Y') {
                $bytes = pack "q<", defined $value ? $value * 10**$places : 0;
            }
            elsif ($type eq '0' && $name eq '_NullFlags') {
                $bytes = pack "C$size", defined $value ? $value : 0 x $size;
            }
            else {
                die "Data type '$type' not supported";
            }
            print {$fh} $bytes;
            ++$i;
        }
    }
    print {$fh} "\x1a";
    close $fh;
    return;
}

sub pack_shp_header {
    my (%h) = @_;

    my $bytes = pack 'N7L2d<8', $h{file_code}, (0) x 5, $h{file_length},
        $h{version}, $h{shape_type}, $h{x_min}, $h{y_min}, $h{x_max},
        $h{y_max},   $h{z_min},      $h{z_max}, $h{m_min}, $h{m_max};

    return $bytes;
}

sub pack_null {
    my %h = (
        record_number => 0,
        shape_type    => $SHPT_NULL,
        @_
    );

    my $bytes = pack 'N2L', $h{record_number}, 2, $h{shape_type};

    return $bytes;
}

sub pack_point {
    my %h = (
        record_number => 0,
        shape_type    => $SHPT_POINT,
        point         => [0.0, 0.0],
        @_
    );

    my $bytes = pack 'N2Ld<2', $h{record_number}, 10, $h{shape_type},
        @{$h{point}}[0 .. 1];

    return $bytes;
}

sub pack_polygon {
    my %h = (
        record_number => 0,
        shape_type    => $SHPT_POLYGON,
        box           => [0.0, 0.0, 0.0, 0.0],
        parts         => [],
        @_
    );

    my @parts = map { scalar @{$_} } @{$h{parts}};
    unshift @parts, 0;
    pop @parts;

    my @points = map { @{$_} } map { @{$_} } @{$h{parts}};

    my $parts_count  = scalar @parts;
    my $points_count = scalar @points;

    my $content_length = (44 + 4 * $parts_count + 8 * $points_count) / 2;

    my $bytes = pack "N2Ld<4L2L${parts_count}d<${points_count}",
        $h{record_number}, $content_length, $h{shape_type},
        @{$h{box}}[0 .. 3], $parts_count, $points_count / 2, @parts, @points;

    return $bytes;
}

my %pack_shp_record = (
    $SHPT_NULL        => \&pack_null,
    $SHPT_POINT       => \&pack_point,
    $SHPT_POLYLINE    => undef,
    $SHPT_POLYGON     => \&pack_polygon,
    $SHPT_MULTIPOINT  => undef,
    $SHPT_POINTZ      => undef,
    $SHPT_POLYLINEZ   => undef,
    $SHPT_POLYGONZ    => undef,
    $SHPT_MULTIPOINTZ => undef,
    $SHPT_POINTM      => undef,
    $SHPT_POLYLINEM   => undef,
    $SHPT_POLYGONM    => undef,
    $SHPT_MULTIPOINTM => undef,
    $SHPT_MULTIPATCH  => undef,
);

sub pack_shp_record {
    my (%shape) = @_;

    return $pack_shp_record{$shape{shape_type}}->(%shape);
}

sub write_shp {
    my (%args) = @_;

    my $file   = $args{file};
    my %header = (
        file_code   => 9994,
        file_length => 0,
        version     => 1000,
        shape_type  => 0,
        x_min       => 0.0,
        y_min       => 0.0,
        x_max       => 0.0,
        y_max       => 0.0,
        z_min       => 0.0,
        z_max       => 0.0,
        m_min       => 0.0,
        m_max       => 0.0,
        %{$args{header}}
    );
    my @shapes = @{$args{shapes}};

    my $record_number = 0;
    for my $shape (@shapes) {
        $shape->{record_number} = $record_number;
        ++$record_number;
    }

    my @packed_shapes = map { pack_shp_record(%{$_}) } @shapes;

    my $size = reduce { $a + length $b } 0, @packed_shapes;
    $header{file_length} = (100 + $size) / 2;

    open my $fh, '>:raw', $file or die "Can't open $file: $!";
    print {$fh} pack_shp_header(%header);
    for my $record (@packed_shapes) {
        print {$fh} $record;
    }
    close $fh;
    return;
}

sub strptime {
    my $time = shift;

    return Time::Piece->strptime($time, "%Y-%m-%d %H:%M:%S");
}

write_dbf(
    file   => 'types.dbf',
    header => {
        version => 0x30,
        fields  => [
            {   name   => 'FESTIVAL',
                type   => 'C',
                length => 32,
            },
            {   name   => 'FROM',
                type   => 'D',
                length => 8,
            },
            {   name   => 'TO',
                type   => 'T',
                length => 8,
            },
            {   name   => 'LOCATION',
                type   => 'C',
                length => 254,
            },
            {   name           => 'LATITUDE',
                type           => 'F',
                length         => 10,
                decimal_places => 4,
            },
            {   name   => 'LONGITUDE',
                type   => 'B',
                length => 8,
            },
            {   name   => 'BANDS',
                type   => 'I',
                length => 4,
            },
            {   name           => 'ADMISSION',
                type           => 'N',
                length         => 4,
                decimal_places => 0,
            },
            {   name           => 'BEER_PRICE',
                type           => 'Y',
                length         => 8,
                decimal_places => 4,
            },
            {   name           => 'FOOD_PRICE',
                type           => 'N',
                length         => 8,
                decimal_places => 4,
            },
            {   name   => 'SOLD_OUT',
                type   => 'L',
                length => 1,
            },
        ],
    },
    records => [
        [   q{ },
            'Graspop Metal Meeting',
            strptime('2022-06-16 00:00:00'),
            strptime('2022-06-19 23:59:59'),
            'Dessel',
            51.2395,
            5.1132,
            129,
            249,
            5.50,
            8.25,
            'T',
        ],
        [   q{*},   undef, undef, undef, q{*} x 254, undef, -179.999999,
            -2**31, undef, -2**31 / 10_000,
            -1.23,  undef,
        ],
    ]
);

write_dbf(
    file   => 'polygon.dbf',
    header => {
        fields => [{
            name   => 'tzid',
            type   => 'C',
            length => 80,
        }],
    },
    records => [
        [q{ }, 'Rectangle'],
        [q{ }, 'Triangle'],
        [q{ }, 'America/Los_Angeles'],
        [q{ }, 'Africa/Juba'],
        [q{ }, 'Africa/Khartoum'],
        [q{ }, 'Europe/Oslo'],
    ]
);

write_shp(
    file   => 'polygon.shp',
    header => {
        shape_type => $SHPT_POLYGON,
        x_min      => -180.0,
        y_min      => -90.0,
        x_max      => 180.0,
        y_max      => 90.0,
    },
    shapes => [
        {    # rectangle
            shape_type => $SHPT_POLYGON,
            box        => [0, 0, 1, 1],
            parts      =>
                [[[0.2, 0.2], [0.2, 0.8], [0.8, 0.8], [0.8, 0.2], [0.2, 0.2]]]
        },
        {    # triangle with hole
            shape_type => $SHPT_POLYGON,
            box        => [0, 0, 1, 1],
            parts      => [
                [[0.2, 0.2], [0.5, 0.8], [0.8, 0.2], [0.2, 0.2]],
                [[0.4, 0.4], [0.5, 0.6], [0.6, 0.4], [0.4, 0.4]]
            ]
        },
        {    # America/Los_Angeles
            shape_type => $SHPT_POLYGON,
            box        => [-126, 33, -114, 49],
            parts      =>
                [[[-126, 33], [-126, 49], [-114, 49], [-114, 33], [-126, 33]]]
        },
        {    # Africa/Juba
            shape_type => $SHPT_POLYGON,
            box        => [23.45, 3.49, 35.95, 12.24],
            parts      => [[
                [23.45, 3.49],
                [23.45, 12.24],
                [35.95, 12.24],
                [35.95, 3.49],
                [23.45, 3.49]
            ]]
        },
        {    # Africa/Khartoum
            shape_type => $SHPT_POLYGON,
            box        => [21.81, 8.69, 39.06, 22.22],
            parts      => [[
                [21.81, 8.69],
                [21.81, 22.22],
                [39.06, 22.22],
                [39.06, 8.69],
                [21.81, 8.69]
            ]]
        },
        {    # Europe/Oslo
            shape_type => $SHPT_POLYGON,
            box        => [10, 59, 11, 60],
            parts      => [[[10, 59], [10, 60], [11, 60], [11, 59], [10, 59]]]
        },
    ]
);
