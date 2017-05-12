package Geo::Shapefile::Writer;
{
  $Geo::Shapefile::Writer::VERSION = '0.006';
}

# $Id: Writer.pm 17 2014-11-12 07:16:04Z xliosha@gmail.com $

# NAME: Geo::Shapefile::Writer
# ABSTRACT: simple pureperl shapefile writer


use 5.010;
use strict;
use warnings;

use utf8;
use autodie;
use Carp;

use XBase;
use List::Util qw/ min max /;



my %shape_type = (
    # extend
    NULL        => 0,
    POINT       => 1,
    POLYLINE    => 3,
    POLYGON     => 5,
);



{
my @default_attr_format = ( C => 64 );

sub _get_attr_format {
    my ($format) = @_;

    my @descr = !ref $format        ? ($format)
        : ref $format eq 'ARRAY'    ? @$format
        : ref $format eq 'HASH'     ? @$format{ qw/ name type length decimals / }
                                    : ();

    croak 'Bad format description'      if !$descr[0];

    @descr[1,2] = @default_attr_format  if !$descr[1];
    return \@descr;
}
}

sub new {
    my ($class, $name, $type, @attrs) = @_;

    my $shape_type = $shape_type{ uc($type || q{}) };
    croak "Invalid shape type: $type"  if !defined $shape_type;

    my $self = bless {
        NAME     => $name,
        TYPE     => $shape_type,
        RCOUNT   => 0,
        SHP_SIZE => 50,
        SHX_SIZE => 50,
    }, $class;

    my $header_data = $self->_get_header('SHP');

    open $self->{SHP}, '>:raw', "$name.shp";
    print {$self->{SHP}} $header_data; 

    open $self->{SHX}, '>:raw', "$name.shx";
    print {$self->{SHX}} $header_data; 

    unlink "$name.dbf"  if -f "$name.dbf";

    my @fields = map { _get_attr_format($_) } @attrs;
    $self->{DBF} = XBase->create(
        name            => "$name.dbf",
        field_names     => [ map { $_->[0] } @fields ],
        field_types     => [ map { $_->[1] } @fields ],
        field_lengths   => [ map { $_->[2] } @fields ],
        field_decimals  => [ map { $_->[3] } @fields ],
    );

    return $self;
}


{
my $header_size = 100;
# position, pack_type, object_field, default
my @header_fields = (
    [ 0,  'N', undef,   9994 ],             # magic
    [ 24, 'N', _SIZE => $header_size / 2 ], # file size in 16-bit words
    [ 28, 'L', undef,   1000 ],             # version
    [ 32, 'L', 'TYPE' ],
    [ 36, 'd', 'XMIN' ],
    [ 44, 'd', 'YMIN' ],
    [ 52, 'd', 'XMAX' ],
    [ 60, 'd', 'YMAX' ],
);

sub _get_header {
    my ($self, $file_type) = @_;

    my @use_fields =
        grep { defined $_->[2] }
        map {[ $_->[0], $_->[1], $_->[2] && ($self->{$_->[2]} // $self->{"$file_type$_->[2]"}) // $_->[3] ]}
        @header_fields;

    my $pack_string = join q{ }, map { sprintf '@%d%s', @$_[0,1] } (@use_fields, [$header_size, q{}]);
    return pack $pack_string, map { $_->[2] } @use_fields;
}
}



sub add_shape {
    my ($self, $data, @attributes) = @_;

    my ($xmin, $ymin, $xmax, $ymax);

    my $rdata;
    my $type = $self->{TYPE};

    if ($type == $shape_type{NULL} ) {
        $rdata = pack( 'L', $self->{TYPE} );
    }
    elsif ($type == $shape_type{POINT} ) {
        $rdata = pack( 'Ldd', $self->{TYPE}, @$data );
        ($xmin, $ymin, $xmax, $ymax) = ( @$data, @$data );
    }
    elsif ($type == $shape_type{POLYLINE} || $type == $shape_type{POLYGON} ) {
        my $rpart = q{};
        my $rpoint = q{};
        my $ipoint = 0;

        for my $line ( @$data ) {
            $rpart .= pack 'L', $ipoint;
            for my $point ( @$line ) {
                my ($x, $y) = @$point;
                $rpoint .= pack 'dd', $x, $y;
                $ipoint ++;
            }
        }

        $xmin = min map {$_->[0]} map {@$_} @$data;
        $ymin = min map {$_->[1]} map {@$_} @$data;
        $xmax = max map {$_->[0]} map {@$_} @$data;
        $ymax = max map {$_->[1]} map {@$_} @$data;

        $rdata = pack 'LddddLL', $self->{TYPE}, $xmin, $ymin, $xmax, $ymax, scalar @$data, $ipoint;
        $rdata .= $rpart . $rpoint;
    }
    

    my $attr0 = $attributes[0];
    if ( ref $attr0 eq 'HASH' ) {
        $self->{DBF}->set_record_hash( $self->{RCOUNT}, map {( uc($_) => $attr0->{$_} )} keys %$attr0 );
    }
    elsif ( ref $attr0 eq 'ARRAY' ) {
        $self->{DBF}->set_record( $self->{RCOUNT}, @$attr0 );
    }
    else {
        $self->{DBF}->set_record( $self->{RCOUNT}, @attributes );
    }

    $self->{RCOUNT} ++;

    print {$self->{SHX}} pack 'NN', $self->{SHP_SIZE}, length($rdata)/2;
    $self->{SHX_SIZE} += 4;

    print {$self->{SHP}} pack 'NN', $self->{RCOUNT}, length($rdata)/2;
    print {$self->{SHP}} $rdata;
    $self->{SHP_SIZE} += 4+length($rdata)/2;

    $self->{XMIN} = min grep {defined} ($xmin, $self->{XMIN});
    $self->{YMIN} = min grep {defined} ($ymin, $self->{YMIN});
    $self->{XMAX} = max grep {defined} ($xmax, $self->{XMAX});
    $self->{YMAX} = max grep {defined} ($ymax, $self->{YMAX});

    return $self;
}



sub finalize {
    my $self = shift;

    my $shp = $self->{SHP};
    seek $shp, 0, 0;
    print {$shp} $self->_get_header('SHP');
    close $shp;

    my $shx = $self->{SHX};
    seek $shx, 0, 0;
    print {$shx} $self->_get_header('SHX');
    close $shx;

    $self->{DBF}->close();

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::Shapefile::Writer - simple pureperl shapefile writer

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $shp_writer = Geo::Shapefile::Writer->new( 'summits', 'POINT',
        [ name => 'C', 100 ],
        [ elevation => 'N', 8, 0 ],
    );

    $shp_writer->add_shape( [86.925278, 27.988056], 'Everest', 8848 );
    $shp_writer->add_shape( [42.436944, 43.353056], { name => 'Elbrus', elevation => 5642 } );

    $shp_writer->finalize();

=head1 DESCRIPTION

Geo::Shapelib is cool, but not portable.

So here is an alternative, if you need just simple shp export.

=head1 METHODS

=head2 new

    my $shp_writer = Geo::Shapefile::Writer->new( $name, $type, @attr_descriptions );

Create object and 3 associated files.

Possible types: POINT, POLYLINE, POLYGON (more to be implemented).

Possible attribute description formats:

  * scalar - just field name

  * arrayref - [ $name, $type, $length, $decimals ]

  * hashref - { name => $name, type => 'N', length => 8,  decimals => 0 } - CAM::DBF-compatible 

Default C(64) will be used if field is not completely described

=head2 add_shape

    $shp_writer->add_shape( $shape, @attributes );

$shape depends on file type:

  * point: [$x,$y]

  * polyline or polygon: [ [[$x0,$y0], ...], \@part2, ... ] 

Attributes are array or arrayref: [$val1, $val2, ...] or hashref: { $name1 => $val1, ...}

=head2 finalize

    $shp_writer->finalize();

Update global fields, close files

=head1 AUTHOR

liosha <liosha@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by liosha.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
