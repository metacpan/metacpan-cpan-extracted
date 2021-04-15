package Geo::ShapeFile;

use strict;
use warnings;
use Carp;
use IO::File;
use Geo::ShapeFile::Shape;
use Config;
use List::Util qw /min max/;
use Scalar::Util qw/weaken/;
use Tree::R;

use constant ON_WINDOWS => ($^O eq 'MSWin32');
use if ON_WINDOWS, 'Win32::LongPath';

our $VERSION = '3.01';

my $little_endian_sys = unpack 'b', (pack 'S', 1 );

# Preloaded methods go here.
sub new {
    my $proto    = shift;
    my $filebase = shift || croak "Must specify filename!";
    my $args     = shift || {};  #  should check it's a haashref

    my $class = ref($proto) || $proto;
    my $self = {};

    $self->{filebase} = $filebase;
    #  should use a proper file name handler
    #  so we can deal with fred.ext referring to fred.ext.shp
    $self->{filebase} =~ s/\.\w{3}$//;

    $self->{_enable_caching} = {
        shp            => 1,
        dbf            => 1,
        shx            => 1,
        shapes_in_area => 1,
    };
    $self->{has_shx} = 0;
    $self->{has_shp} = 0;
    $self->{has_dbf} = 0;

    bless $self, $class;

    #  control overall caching
    if ($args->{no_cache}) {
        $self->{_no_cache} = 1;
    }

    #  not sure what this does - possible residual from early plans
    $self->{_change_cache} = {
        shape_type => undef,
        records    => undef,
        shp        => {},
        dbf        => {},
        shx        => {},
    };
    $self->{_object_cache} = {
        shp    => {},
        dbf    => {},
        shx    => {},
        shapes_in_area => {},
    };

    if ($self->file_exists ($self->{filebase} . '.shx')) {
        $self->_read_shx_header();
        $self->{has_shx} = 1;
    }

    if ($self->file_exists ($self->{filebase} . '.shp')) {
        $self->_read_shp_header();
        $self->{has_shp} = 1;
    }

    if ($self->file_exists ($self->{filebase} . '.dbf')) {
        $self->_read_dbf_header();
        $self->{has_dbf} = 1;
    }

    if (!$self->{has_dbf}) {
        croak "$self->{filebase}: shp and/or shx file do not exist or are invalid"
          if !($self->{has_shp} && $self->{has_shx});

        croak "$self->{filebase}.dbf does not exist or is invalid";
    }

    return $self;
}

sub get_file_size {
    my ($self, $file_name) = @_;

    my $file_size;

    if (-e $file_name) {
        $file_size = -s $file_name;
    }
    elsif (ON_WINDOWS) {
        my $stat = statL ($file_name)
          or die ("unable to get stat for $file_name ($^E)");
        $file_size = $stat->{size};
    }
    else {
        croak "$file_name does not exist or cannot be read, cannot get file size\n";
    }

    return $file_size;
}

sub file_exists {
    my ($self, $file_name) = @_;

    return 1 if -e $file_name;
    
    if (ON_WINDOWS) {
        return testL ('e', $file_name);
    }

    return;
}


sub _disable_all_caching {
    my $self = shift;
    #  a bit nuclear...
    foreach my $type (qw/shp shx dbf shapes_in_area/) {
        $self->{_enable_caching}{$type} = 0;
        $self->{_object_cache} = {};
        #$self->{_change_cache} = {};  #  need to work out what this is for
    }
    return;
}

sub caching {
    my $self = shift;
    my $what = shift;
    my $flag = shift;

    if (defined $flag) {
        $self->{_enable_caching}->{$what} = $flag;
    }
    return $self->{_enable_caching}->{$what};
}

sub cache {
    my ($self, $type, $obj, $cache) = @_;
    
    return if $self->{_no_cache};

    return $self->{_change_cache}->{$type}->{$obj}
      if $self->{_change_cache}->{$type} && $self->{_change_cache}->{$type}->{$obj};

    return if !$self->caching($type);

    if ($cache) {
        $self->{_object_cache}->{$type}->{$obj} = $cache;
    }
    return $self->{_object_cache}->{$type}->{$obj};
}

#  This will trigger the various caching
#  so we end up with the file in memory.
#  Not an issue for most files.
sub get_all_shapes {
    my $self = shift;

    my @shapes;

    foreach my $id (1 .. $self->shapes()) {
        my $shape = $self->get_shp_record($id);
        push @shapes, $shape;
    }

    return wantarray ? @shapes : \@shapes;
}

sub get_shapes_sorted {
    my $self   = shift;
    my $shapes = shift;
    my $sub    = shift;

    if (!defined $sub) {
        $sub = sub {
            my ($s1, $s2) = @_;
            return $s1->{shp_record_number} <=> $s2->{shp_record_number};
        };
    }

    if (!defined $shapes) {
        $shapes = $self->get_all_shapes;
    }

    my @sorted = sort {$sub->($a, $b)} @$shapes;

    return wantarray ? @sorted : \@sorted;
}

sub get_shapes_sorted_spatially {
    my $self   = shift;
    my $shapes = shift;
    my $sub    = shift;

    if (!defined $sub) {
        $sub = sub {
            my ($s1, $s2) = @_;
            return
                    $s1->x_min <=> $s2->x_min
                 || $s1->y_min <=> $s2->y_min
                 || $s1->x_max <=> $s2->x_max
                 || $s1->y_max <=> $s2->y_max
                 || $s1->shape_id <=> $s2->shape_id
                 ;
        };
    }

    return $self->get_shapes_sorted ($shapes, $sub);
}

sub build_spatial_index {
    my $self = shift;

    my $shapes = $self->get_all_shapes;

    my $rtree = Tree::R->new();
    foreach my $shape (@$shapes) {
        my @bbox = ($shape->x_min, $shape->y_min, $shape->x_max, $shape->y_max);
        $rtree->insert($shape, @bbox);
    }

    $self->{_spatial_index} = $rtree;

    return $rtree;
}

sub get_spatial_index {
    my $self = shift;
    return $self->{_spatial_index};
}


sub _read_shx_header {
    shift()->_read_shx_shp_header('shx', @_);
}

sub _read_shp_header {
    shift()->_read_shx_shp_header('shp', @_);
}

sub _read_shx_shp_header {
    my $self  = shift;
    my $which = shift;
    my $doubles;

    $self->{$which . '_header'} = $self->_get_bytes($which, 0, 100);
    (
        $self->{$which . '_file_code'}, $self->{$which . '_file_length'},
        $self->{$which . '_version'},   $self->{$which . '_shape_type'}, $doubles
    ) = unpack 'N x20 N V2 a64', $self->{$which . '_header'};

    (
        $self->{$which . '_x_min'}, $self->{$which . '_y_min'},
        $self->{$which . '_x_max'}, $self->{$which . '_y_max'},
        $self->{$which . '_z_min'}, $self->{$which . '_z_max'},
        $self->{$which . '_m_min'}, $self->{$which . '_m_max'},
    ) = (
        $little_endian_sys
            ? (unpack 'd8', $doubles )
            : (reverse unpack 'd8', scalar reverse $doubles)
    );

    return 1;
}

sub type_is {
    my $self = shift;
    my $type = shift;

    #  numeric code    
    return $self->shape_type == $type
      if ($type =~ /^[0-9]+$/);

    return (lc $self->type($self->shape_type)) eq (lc $type);
}

sub get_dbf_field_names {
    my $self = shift;

    croak 'dbf field names not loaded yet'
      if !defined $self->{dbf_field_names};

    #  make sure we return a copy
    my @fld_names = @{$self->{dbf_field_names}};

    return wantarray ? @fld_names : \@fld_names;
}

sub _read_dbf_header {
    my $self = shift;

    $self->{dbf_header} = $self->_get_bytes('dbf', 0, 12);
    (
        $self->{dbf_version},
        $self->{dbf_updated_year},
        $self->{dbf_updated_month},
        $self->{dbf_updated_day},
        $self->{dbf_num_records},
        $self->{dbf_header_length},
        $self->{dbf_record_length},
    ) = unpack 'C4 V v v', $self->{dbf_header};
    # unpack changed from c4 l s s to fix endianess problem
    # reported by Daniel Gildea

    my $ls = $self->{dbf_header_length}
           + $self->{dbf_num_records} * $self->{dbf_record_length};
    my $li = $self->get_file_size($self->{filebase} . '.dbf');

    # some shapefiles (such as are produced by the NOAA NESDIS) don't
    # have a end-of-file marker in their dbf files, Aleksandar Jelenak
    # says the ESRI tools don't have a problem with this, so we shouldn't
    # either
    my $last_byte = $self->_get_bytes('dbf', $li-1, 1);
    $ls ++ if ord $last_byte == 0x1A;

    croak "dbf: file wrong size (should be $ls, but found $li)"
      if $ls != $li;

    my $header = $self->_get_bytes('dbf', 32, $self->{dbf_header_length} - 32);
    my $count = 0;
    $self->{dbf_header_info} = [];

    while ($header) {
        my $tmp = substr $header, 0, 32, '';
        my $chr = substr $tmp, 0, 1;

        last if ord $chr == 0x0D;
        last if length ($tmp) < 32;

        my %tmp = ();
        (
            $tmp{name},
            $tmp{type},
            $tmp{size},
            $tmp{decimals}
        ) = unpack 'Z11 Z x4 C2', $tmp;

        $self->{dbf_field_info}->[$count] = {%tmp};

        $count++;
    }

    $self->{dbf_fields} = $count;
    croak "dbf: Not enough fields ($count < 1)"
      if $count < 1;

    my @template = ();
    foreach (@{$self->{dbf_field_info}}) {
        croak "dbf: Field $_->{name} too short ($_->{size} bytes)"
          if $_->{size} < 1;

        croak "dbf: Field $_->{name} too long ($_->{size} bytes)"
          if $_->{size} > 4000;

        push @template, 'A' . $_->{size};
    }
    $self->{dbf_record_template} = join ' ', @template;

    my @field_names = ();
    foreach (@{$self->{dbf_field_info}}) {
        push @field_names, $_->{name};
    }
    $self->{dbf_field_names} = [@field_names];

    #  should return field names?  
    return 1;
}

#  needed now there is Geo::ShapeFile::Writer?
sub _generate_dbf_header {
    my $self = shift;

    #$self->{dbf_header} = $self->_get_bytes('dbf',0,12);
    (
        $self->{dbf_version},
        $self->{dbf_updated_year},
        $self->{dbf_updated_month},
        $self->{dbf_updated_day},
        $self->{dbf_num_records},
        $self->{dbf_header_length},
        $self->{dbf_record_length},
    ) = unpack 'C4 V v v', $self->{dbf_header};

    $self->{_change_cache}->{dbf_cache}->{header}
      = pack
        'C4 V v v',
        3,
        (localtime)[5],
        (localtime)[4]+1,
        (localtime)[3],
        0, # TODO - num_records,
        0, # TODO - header_length,
        0, # TODO - record_length,
    ;
}

sub get_dbf_field_info {
    my $self = shift;
    
    my $header = $self->{dbf_field_info};
    
    return if !$header;
    
    #  Return a deep copy to avoid callers
    #  messing up the internals
    my @hdr;
    foreach my $field (@$header) {
        my %h = %$field;
        push @hdr, \%h;
    }

    return wantarray ? @hdr : \@hdr;
}

sub get_dbf_record {
    my $self  = shift;
    my $entry = shift;

    my $dbf = $self->cache('dbf', $entry);

    if (!$dbf) {
        $entry--; # make entry 0-indexed

        my $record = $self->_get_bytes(
            'dbf',
            $self->{dbf_header_length}+($self->{dbf_record_length} * $entry),
            $self->{dbf_record_length}+1, # +1 for deleted flag
        );
        my ($del, @data) = unpack 'c' . $self->{dbf_record_template}, $record;

        map { s/^\s*//; s/\s*$//; } @data;

        my %record;
        @record{@{$self->{dbf_field_names}}} = @data;
        $record{_deleted} = (ord $del == 0x2A);
        $dbf = {%record};
        $self->cache('dbf', $entry + 1, $dbf);
    }

    return wantarray ? %{$dbf} : $dbf;
}

#  needed?  not called anywhere
sub _set_dbf_record {
    my $self   = shift;
    my $entry  = shift;
    my %record = @_;

    $self->{_change_cache}->{dbf}->{$entry} = {%record};
}

sub _get_shp_shx_header_value {
    my $self = shift;
    my $val  = shift;

    if (!defined($self->{'shx_' . $val}) && !defined($self->{'shp_' . $val})) {
        $self->_read_shx_header();  #  ensure we load at least one of the headers
    }

    return defined($self->{'shx_' . $val})
      ? $self->{'shx_' . $val}
      : $self->{'shp_' . $val};
}

#  factory these
sub x_min { shift()->_get_shp_shx_header_value('x_min'); }
sub x_max { shift()->_get_shp_shx_header_value('x_max'); }
sub y_min { shift()->_get_shp_shx_header_value('y_min'); }
sub y_max { shift()->_get_shp_shx_header_value('y_max'); }
sub z_min { shift()->_get_shp_shx_header_value('z_min'); }
sub z_max { shift()->_get_shp_shx_header_value('z_max'); }
sub m_min { shift()->_get_shp_shx_header_value('m_min'); }
sub m_max { shift()->_get_shp_shx_header_value('m_max'); }

sub upper_left_corner {
    my $self = shift;

    return Geo::ShapeFile::Point->new(X => $self->x_min, Y => $self->y_max);
}

sub upper_right_corner {
    my $self = shift;

    return Geo::ShapeFile::Point->new(X => $self->x_max, Y => $self->y_max);
}

sub lower_right_corner {
    my $self = shift;

    return Geo::ShapeFile::Point->new(X => $self->x_max, Y => $self->y_min);
}

sub lower_left_corner {
    my $self = shift;

    return Geo::ShapeFile::Point->new(X => $self->x_min, Y => $self->y_min);
}

sub height {
    my $self = shift;

    return if !$self->records;

    return $self->y_max - $self->y_min;
}

sub width {
    my $self = shift;

    return if !$self->records;

    return $self->x_max - $self->x_min;
}

sub corners {
    my $self = shift;

    return (
        $self->upper_left_corner,
        $self->upper_right_corner,
        $self->lower_right_corner,
        $self->lower_left_corner,
    );
}

sub area_contains_point {
    my $self  = shift;
    my $point = shift;

    my ($x_min, $y_min, $x_max, $y_max) = @_;

    my $x = $point->get_x;
    my $y = $point->get_y;

    my $result =
        ($x >= $x_min) &&
        ($x <= $x_max) &&
        ($y >= $y_min) &&
        ($y <= $y_max);

    return $result;
}

sub bounds_contains_point {
    my $self  = shift;
    my $point = shift;

    return $self->area_contains_point (
        $point,
        $self->x_min, $self->y_min,
        $self->x_max, $self->y_max,
    );
}

sub file_version {
    shift()->_get_shp_shx_header_value('version');
}

sub shape_type {
    my $self = shift;

    return $self->{_change_cache}->{shape_type}
      if defined $self->{_change_cache}->{shape_type};

    return $self->_get_shp_shx_header_value('shape_type');
}

sub shapes {
    my $self = shift;

    return $self->{_change_cache}->{records}
      if defined $self->{_change_cache}->{records};

    if (!$self->{shx_file_length}) {
        $self->_read_shx_header();
    }

    my $filelength = $self->{shx_file_length};
    $filelength   -= 50; # don't count the header

    return $filelength / 4;
}

sub records {
    my $self = shift;

    return $self->{_change_cache}->{records}
      if defined $self->{_change_cache}->{records};

    if ($self->{shx_file_length}) {
        my $filelength = $self->{shx_file_length};
        $filelength   -= 50; # don't count the header
        return $filelength / 4;
    }
    #  should perhaps just return dbf_num_records if we get this far?  
    elsif ($self->{dbf_num_records}) {
        return $self->{dbf_num_records};
    }

    return 0;
}

sub shape_type_text {
    my $self = shift;

    return $self->type($self->shape_type());
}

sub get_shx_record_header {
    shift()->get_shx_record(@_);
}

sub get_shx_record {
    my $self  = shift;
    my $entry = shift;

    croak 'must specify entry index'
      if !$entry;

    my $shx = $self->cache('shx', $entry);

    if (!$shx) {
        my $record = $self->_get_bytes('shx', (($entry - 1) * 8) + 100, 8);
        $shx = [unpack 'N N', $record];
        $self->cache('shx', $entry, $shx);
    }

    return @{$shx};
}

sub get_shp_record_header {
    my $self = shift;
    my $entry = shift;

    my($offset) = $self->get_shx_record($entry);

    my $record = $self->_get_bytes('shp', $offset * 2, 8);
    my ($number, $content_length) = unpack 'N N', $record;

    return ($number, $content_length);
}


#  returns indexes, not objects - need to change that or add method for shape_objects_in_area
sub shapes_in_area {
    my $self = shift;
    my @area = @_; # x_min, y_min, x_max, y_max,

    if (my $sp_index = $self->get_spatial_index) {
        my $shapes = [];
        $sp_index->query_partly_within_rect (@area, $shapes);
        my @indexes;
        foreach my $shape (@$shapes) {
            push @indexes, $shape->shape_id;
        }
        return wantarray ? @indexes : \@indexes;
    }

    my @results = ();
    SHAPE:
    foreach my $shp_id (1 .. $self->shapes) {
        my ($offset, $content_length) = $self->get_shx_record($shp_id);
        my $type = unpack 'V', $self->_get_bytes ('shp', $offset * 2 + 8, 4);

        next SHAPE if $self->type($type) eq 'Null';

        if ($self->type($type) =~ /^Point/) {
            my $bytes = $self->_get_bytes('shp', $offset * 2 + 12, 16);
            my ($x, $y) = (
                $little_endian_sys
                    ? (unpack 'dd', $bytes )
                    : (reverse unpack 'dd', scalar reverse $bytes)
            );
            my $pt = Geo::ShapeFile::Point->new(X => $x, Y => $y);
            if ($self->area_contains_point($pt, @area)) {
                push @results, $shp_id;
            }
        }
        elsif ($self->type($type) =~ /^(PolyLine|Polygon|MultiPoint|MultiPatch)/) {
            my $bytes = $self->_get_bytes('shp', ($offset * 2) + 12, 32);
            my @p = (
                $little_endian_sys
                    ? (unpack 'd4', $bytes )
                    : (reverse unpack 'd4', scalar reverse $bytes )
            );
            if ($self->check_in_area(@p, @area)) {
                push @results, $shp_id;
            }
        }
        else {
            print 'type=' . $self->type($type) . "\n";
        }
    }

    return wantarray ? @results : \@results;
}

sub check_in_area {
    my $self = shift;
    my (
        $x1_min, $y1_min, $x1_max, $y1_max,
        $x2_min, $y2_min, $x2_max, $y2_max,
    ) = @_;

    my $result = !(
           $x1_min > $x2_max
        or $x1_max < $x2_min
        or $y1_min > $y2_max
        or $y1_max < $y2_min
    );

    return $result;
}

#  SWL: not used anymore - remove?
sub _between {
    my $self  = shift;
    my $check = shift;

    #  ensure min then max
    if ($_[0] > $_[1]) {
        @_ = reverse @_;
    }

    return ($check >= $_[0]) && ($check <= $_[1]);
}

sub bounds {
    my $self = shift;

    return (
        $self->x_min, $self->y_min,
        $self->x_max, $self->y_max,
    );
}

# is this ever called?  
sub _extract_ints {
    my $self = shift;
    my $end = shift;
    my @what = @_;

    my $template = ($end =~ /^l/i) ? 'V': 'N';

    $self->_extract_and_unpack(4, $template, @what);
    foreach (@what) {
        $self->{$_} = $self->{$_};
    }
}

sub get_shp_record {
    my $self  = shift;
    my $entry = shift;

    my $shape = $self->cache('shp', $entry);
    if (!$shape) {
        my($offset, $content_length) = $self->get_shx_record($entry);

        my $record = $self->_get_bytes('shp', $offset * 2, $content_length * 2 + 8);

        $shape = Geo::ShapeFile::Shape->new();
        $shape->parse_shp($record);
        $self->cache('shp', $entry, $shape);
    }

    return $shape;
}

sub shx_handle {
    shift()->_get_handle('shx');
}

sub shp_handle {
    shift()->_get_handle('shp');
}

sub dbf_handle {
    shift()->_get_handle('dbf');
}

sub _get_handle {
    my $self  = shift;
    my $which = shift;

    my $han = $which . '_handle';

    if (!$self->{$han}) {
        my $file = join '.', $self->{filebase}, $which;
        if (-e $file) {
            $self->{$han} = IO::File->new;
            croak "Couldn't get file handle for $file: $!"
              if not $self->{$han}->open($file, O_RDONLY | O_BINARY);
        }
        elsif (ON_WINDOWS) {
            my $fh;
            openL (\$fh, '<', $file)
              or croak ("unable to open $file ($^E)");
            #$fh = IO::File->new_from_fd ($fh);
            $self->{$han} = $fh;
        }
        binmode $self->{$han}; # fix windows bug reported by Patrick Dughi
    }

    return $self->{$han};
}

sub _get_bytes {
    my $self   = shift;
    my $file   = shift;
    my $offset = shift;
    my $length = shift;

    my $handle = $file . '_handle';
    my $h = $self->$handle();
    $h->seek ($offset, 0)
      || croak "Couldn't seek to $offset for $file";

    my $tmp;
    my $res = $h->read($tmp, $length);

    croak "Couldn't read $length bytes from $file at offset $offset ($!)"
      if !defined $res;

    croak "EOF reading $length bytes from $file at offset $offset"
      if $res == 0;

    return $tmp;
}


sub type {
    my $self  = shift;
    my $shape = shift;

    #  should make this a package lexical
    my %shape_types = qw(
        0   Null
        1   Point
        3   PolyLine
        5   Polygon
        8   MultiPoint
        11  PointZ
        13  PolyLineZ
        15  PolygonZ
        18  MultiPointZ
        21  PointM
        23  PolyLineM
        25  PolygonM
        28  MultiPointM
        31  MultiPatch
    );

    return $shape_types{$shape};
}

sub find_bounds {
    my $self    = shift;
    my @objects = @_;

    return if !scalar @objects;

    my $obj1 = shift @objects;

    #  assign values from first object to start
    my $x_min = $obj1->x_min();
    my $y_min = $obj1->y_min();
    my $x_max = $obj1->x_max();
    my $y_max = $obj1->y_max();


    foreach my $obj (@objects) {
        $x_min = min ($x_min, $obj->x_min());
        $y_min = min ($y_min, $obj->y_min());
        $x_max = max ($x_max, $obj->x_max());
        $y_max = max ($y_max, $obj->y_max());
    }

    my %bounds = (
        x_min => $x_min,
        y_min => $y_min,
        x_max => $x_max,
        y_max => $y_max,
    );

    return %bounds;
}

# XML::Generator::SVG::ShapeFile fails because it is calling this method
# and it does not exist in 2.52 and earlier
sub DESTROY {}


1;
__END__

=head1 NAME

Geo::ShapeFile - Perl extension for handling ESRI GIS Shapefiles.

=head1 SYNOPSIS

  use Geo::ShapeFile;

  my $shapefile = Geo::ShapeFile->new('roads');

  #  note that IDs are 1-based
  foreach my $id (1 .. $shapefile->shapes()) {
    my $shape = $shapefile->get_shp_record($id);
    # see Geo::ShapeFile::Shape docs for what to do with $shape

    my %db = $shapefile->get_dbf_record($id);
  }
  
  #  As before, but do not cache any data.
  #  Useful if you have large files and only need to access
  #  each shape once or a small nmber of times.
  my $shapefile = Geo::ShapeFile->new('roads', {no_cache => 1});


=head1 ABSTRACT

The Geo::ShapeFile module reads ESRI ShapeFiles containing GIS mapping
data, it has support for shp (shape), shx (shape index), and dbf (data
base) formats.

=head1 DESCRIPTION

The Geo::ShapeFile module reads ESRI ShapeFiles containing GIS mapping
data, it has support for shp (shape), shx (shape index), and dbf (data
base) formats.

=head1 METHODS

=over 4

=item new ($filename_base)

=item new ($filename_base, {no_cache => 1})

Creates a new shapefile object.  The first argument is the basename
for your data (there is no need to include the extension, the module will automatically
find the extensions it supports).  For example if you have data files called
roads.shp, roads.shx, and roads.dbf, use C<< Geo::ShapeFile->new("roads"); >> to
create a new object, and the module will load the data it needs from the
files as it needs it.

The second (optional) argument is a hashref.
Currently only no_cache is supported.
If specified then data will not be cached in memory and the system will
read from disk each time you access a shape.
It will save memory for large files, though.

=item type_is ($type)

Returns true if the major type of this data file is the same as the type
passed to type_is().

The $type argument can be either the numeric code (see L</shape_type>),
or the string code (see L</shape_type_text>).

=item get_dbf_record ($record_index)

Returns the data from the dbf file associated with the specified record index
(shapefile indexes start at 1).  If called in a list context, returns a hash,
if called in a scalar context, returns a hashref.

=item x_min() x_max() y_min() y_max()

=item m_min() m_max() z_min() z_max()

Returns the minimum and maximum values for x, y, z, and m fields as indicated
in the shp file header.

=item upper_left_corner() upper_right_corner()

=item lower_left_corner() lower_right_corner()

Returns a L<Geo::ShapeFile::Point> object indicating the respective corners.

=item height() width()

Returns the height and width of the area contained in the shp file.  Note that
this likely does not return miles, kilometers, or any other useful measure, it
simply returns x_max - x_min, or y_max - y_min.  Whether this data is a useful
measure or not depends on your data.

=item corners()

Returns a four element array consisting of the corners of the area contained
in the shp file.  The corners are listed clockwise starting with the upper
left.
(upper_left_corner, upper_right_corner, lower_right_corner, lower_left_corner)

=item area_contains_point ($point, $x_min, $y_min, $x_max, $y_max)

Utility function that returns true if the Geo::ShapeFile::Point object in
point falls within the bounds of the rectangle defined by the area
indicated.  See bounds_contains_point() if you want to check if a point falls
within the bounds of the current shp file.

=item bounds_contains_point ($point)

Returns true if the specified point falls within the bounds of the current
shp file.

=item file_version()

Returns the ShapeFile version number of the current shp/shx file.

=item shape_type()

Returns the shape type contained in the current shp/shx file.  The ESRI spec
currently allows for a file to contain only a single type of shape (null
shapes are the exception, they may appear in any data file).  This returns
the numeric value for the type, use type() to find the text name of this
value.

=item shapes()

Returns the number of shapes contained in the current shp/shx file.  This is
the value that allows you to iterate through all the shapes using
C<< for(1 .. $obj->shapes()) { >>.

=item records()

Returns the number of records contained in the current data.  This is similar
to shapes(), but can be used even if you don't have shp/shx files, so you can
access data that is stored as dbf, but does not have shapes associated with it.

=item shape_type_text()

Returns the shape type of the current shp/shx file (see shape_type()), but
as the human-readable string type, rather than an integer.

=item get_shx_record ($record_index)

=item get_shx_record_header ($record_index)

Get the contents of an shx record or record header (for compatibility with
the other get_* functions, both are provided, but in the case of shx data,
they return the same information).  The return value is a two element array
consisting of the offset in the shp file where the indicated record begins,
and the content length of that record.

=item get_shp_record_header ($record_index)

Retrieve an shp record header for the specified index.  Returns a two element
array consisting of the record number and the content length of the record.

=item get_shp_record ($record_index)

Retrieve an shp record for the specified index.  Returns a
Geo::ShapeFile::Shape object.

=item shapes_in_area ($x_min, $y_min, $x_max, $y_max)

Returns an array of integers listing which shape IDs have
bounding boxes that overlap with the area specified.

=item check_in_area ($x1_min, $y1_min, $x1_max, $y1_max, $x2_min, $x2_max, $y2_min, $y2_max)

Returns true if the two specified areas overlap.

=item bounds()

Returns the bounds for the current shp file.
(x_min, y_min, x_max, y_max)

=item shx_handle() shp_handle() dbf_handle()

Returns the file handles associated with the respective data files.

=item type ($shape_type_number)

Returns the name of the type associated with the given type id number.

=item find_bounds (@shapes)

Takes an array of Geo::ShapeFile::Shape objects, and returns a hash, with
keys of x_min, y_min, x_max, y_max, with the values for each of those bounds.

=item get_dbf_field_names()

Returns an array of the field names in the dbf file, in file order.
Returns an array reference if used in scalar context.

=item get_all_shapes()

Returns an array (or arrayref in scalar context) with all shape objects in the
shapefile.

=item get_shapes_sorted()

=item get_shapes_sorted (\@shapes, \&sort_sub)

Returns an array (or arrayref in scalar context) of shape objects sorted by ID.
Defaults to all shapes, but will also take an array of Geo::ShapeFile::Shape objects.
Sorts by record number by default, but you can pass your own sub for more fancy work.

=item get_shapes_sorted_spatially()

=item get_shapes_sorted_spatially (\@shapes, \&sort_sub)

Convenience wrapper around get_shapes_sorted to sort spatially (south-west to north-east)
then by record number.  You can pass your own shapes and sort sub.
The sort sub does not need to be spatial since it will sort by whatever you say,
but it is your code so do what you like.


=item build_spatial_index()

Builds a spatial index (a L<Tree::R> object) and returns it.  This will be used internally for
many of the routines, but you can use it directly if useful.

=item get_spatial_index()

Returns the spatial index object, or C<undef> if one has not been built.

=item get_dbf_field_info()

Returns an array of hashes containing information about the fields.
Useful if you are modifying the shapes and then writing them out to a
new shapefile using L<Geo::Shapefile::Writer>.

=back

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to
  L<https://github.com/shawnlaffan/Geo-ShapeFile/issues>.

=head1 SEE ALSO

L<Geo::ShapeFile::Shape>, 
L<Geo::ShapeFile::Point>, 
L<Geo::Shapefile::Writer>, 
L<Geo::GDAL::FFI>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2002-2013 by Jason Kohles (versions up to and including 2.52)

Copyright 2014 by Shawn Laffan (versions 2.53 -)


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
