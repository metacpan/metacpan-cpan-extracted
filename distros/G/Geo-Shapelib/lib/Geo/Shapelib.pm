package Geo::Shapelib;

use strict;
use Carp;
use Tree::R;
use File::Basename qw(fileparse);
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS @EXPORT_OK $AUTOLOAD);
use vars qw(%ShapeTypes %PartTypes);

require Exporter;
require DynaLoader;
use AutoLoader 'AUTOLOAD';

@ISA = qw(Exporter DynaLoader);

$VERSION = '0.22';

bootstrap Geo::Shapelib $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Page 4 of the ESRI Shapefile Technical Description, July 1998
%ShapeTypes = (
	1 => 'Point',
	3 => 'PolyLine',
	5 => 'Polygon',
	8 => 'Multipoint',
	11 => 'PointZ',
	13 => 'PolyLineZ',
	15 => 'PolygonZ',
	18 => 'MultipointZ',
	21 => 'PointM',
	23 => 'PolyLineM',
	25 => 'PolygonM',
	28 => 'MultipointM',
	31 => 'Multipatch',
);

# Page 21 of the ESRI Shapefile Technical Description, July 1998
%PartTypes = (
	0 => 'TriStrip',
	1 => 'TriFan',
	2 => 'OuterRing',
	3 => 'InnerRing',
	4 => 'FirstRing',
	5 => 'Ring',
);

# Create the SUBROUTINES FOR ShapeTypes and PartTypes
# We could prefix these with SHPT_ and SHPP_ respectively
{
    my %typeval = (map(uc,reverse(%ShapeTypes)),map(uc,reverse(%PartTypes)));

    for my $datum (keys %typeval) {
	no strict "refs";       # to register new methods in package
	*$datum = sub { $typeval{$datum}; }
    }
}

# Add Extended Exports
%EXPORT_TAGS = ('constants' => [ map(uc,values(%ShapeTypes)),
				 map(uc,values(%PartTypes))
				 ],
		'types' =>[ qw(%ShapeTypes %PartTypes) ] );
$EXPORT_TAGS{all}=[ @{ $EXPORT_TAGS{constants} },
		    @{ $EXPORT_TAGS{types} } ];

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw();


=pod

=head1 NAME

Geo::Shapelib - Perl extension for reading and writing shapefiles as defined by ESRI(r)

=head1 SYNOPSIS

    use Geo::Shapelib qw/:all/;

or

    use Geo::Shapelib qw/:all/;

    my $shapefile = new Geo::Shapelib { 
        Name => 'stations',
        Shapetype => POINT,
        FieldNames => ['Name','Code','Founded'],
        FieldTypes => ['String:50','String:10','Integer:8']
    };

    while (<DATA>) {
        chomp;
        my($station,$code,$founded,$x,$y) = split /\|/;
        push @{$shapefile->{Shapes}},{ Vertices => [[$x,$y,0,0]] };
        push @{$shapefile->{ShapeRecords}}, [$station,$code,$founded];
    }

    $shapefile->save();


=head1 DESCRIPTION

This is a library for reading, creating, and writing shapefiles as
defined by ESRI(r) using Perl.  The Perl code uses Frank Warmerdam's
Shapefile C Library (http://shapelib.maptools.org/). The library
is included in this distribution.

Currently no methods exist for populating an empty Shape. You need
to do it in your own code. This is how:

First you include the module into your code. If you want to define the
shape type using its name, import all:

    use Geo::Shapelib qw/:all/;

Create the shapefile object and specify its name and type:

    $shapefile = new Geo::Shapelib { 
        Name => <filename>, 
        Shapetype => <type from the list>,
        FieldNames => <field name list>,
        FieldTypes => <field type list>
    }

The name (filename, may include path) of the shapefile, the extension
is not used (it is stripped in the save method).

The shape type is an integer. This module defines shape type names as
constants (see below).

The field name list is an array reference of the names of the data
items assigned to each shape.

The field type list is an array reference of the types of the data
items. Field type is either 'Integer', 'Double', or 'String'.

The types may have optional 'width' and 'decimals' fields defined,
like this:

    'Integer[:width]' defaults: width = 10
    'Double[:width[:decimals]]' defaults: width = 10, decimals = 4
    'String[:width]' defaults: width = 255

There are some other attributes which can be defined in the
constructor (see below), they are rarely needed. The shape object will
need or get a couple of other attributes as well. They should be
treated as private:

    $shapefile->{NShapes} is the number of shapes in your
    object. Shapefile is a collection of shapes. This is usually
    automatically deduced from the Shapes array when needed.

    $shapefile->{MinBounds} is set by shapelib C functions.

    $shapefile->{MaxBounds} is set by shapelib C functions.

Create the shapes and respective shape records and put them into the
shape:

    for many times {
        make $s, a new shape as a reference to a hash
        push @{$shapefile->{Shapes}}, $s;
	make $r, a shape record as a reference to an array
	push @{$shapefile->{ShapeRecords}}, $r;
    }

how to create $s? It is a (reference to an) hash.

set:

    $s->{Vertices} this is a reference to an array of arrays of four
    values, one for each vertex: x, y, z, and m of the vertex. There
    should be at least one vertex in $s. Point has only one vertex.

$s->{Parts}:

    $s->{Parts} is not needed in simple cases. $s->{Parts} is a
    reference to an array (a) of arrays (b). There is one (b) array
    for each part. In a (b) array the first value is an index to the
    Vertices array denoting the first vertex of that part. The second
    value is the type of the part (NOTE: not the type of the
    shape). The type is 5 (Ring) unless the shape is of type
    Multipatch. The third value is set as the type of the part as a
    string when reading from a file but the save method requires only
    the first two values.

    The index of the last vertex of any part is implicitly the index
    of the next part minus one or the index of the last vertex.

forget these:

    $s->{ShapeId} may be left undefined. The save method sets it to
    the index in the Shapes array. Instead create and use an id field
    in the record.

    $s->{NParts} and $s->{NVertices} may be set but that is usually
    not necessary since they are calculated in the save method. You
    only need to set these if you want to save less parts or vertices
    than there actually are in the Parts or Vertices arrays.

    $s->{SHPType} is the type of the shape and it is automatically set
    to $shape->{Shapetype} unless defined (which you should not do)

The shape record is simply an array reference, for example:

    $r = [item1,item2,item3,...];

That's all. Then save it and start your shapefile viewer to look at
the result.

=head1 EXPORT

None by default.  The following export tags are defined.

=over 8

=item :constants

This exports constant functions for the individual types of shapefile
Types and shapefile part types.  They all return scalar (integer)
values.  The shapetype functions: POINT, ARC, POLYGON, MULTIPOINT,
POINTZ, ARCZ, POLYGONZ, MULTIPOINTZ, POINTM, ARCM, POLYGONM,
MULTIPOINTM, MULTIPATCH are defined.  The shapefile part
types: TRISTRIP, TRIFAN, OUTERRING, INNERRING, FIRSTRING, RING are
defined.

=item :types

Exports two hashs: %ShapeTypes, %PartTypes which map the shapelib type
integers to string values.

=item :all

All possible exports are included.


=back

=head1 CONSTRUCTORS

This one reads in an existing shapefile:

    $shapefile = new Geo::Shapelib "myshapefile", {<options>};

This one creates a new, blank Perl shapefile object:

    $shapefile = new Geo::Shapelib {<options>};

{<options>} is optional in both cases, an example (note the curly braces):

   $shapefile = new Geo::Shapelib { 
       Name => $shapefile,
       Shapetype => POINT,
       FieldNames => ['Name','Code','Founded'],
       FieldTypes => ['String:50','String:10','Integer:8']
   };

   $shapefile = new Geo::Shapelib "myshapefile" { 
       Rtree => 1
   };

=item Options:

Like:

    A shapefile from which to copy ShapeType, FieldNames, and FieldTypes.

Name:

    Default is "shapefile". The filename (if given) becomes the name
    for the shapefile unless overridden by this.

Shapetype:

    Default "POINT". The type of the shapes. (All non-null shapes in a
    shapefile are required to be of the same shape type.)

FieldNames:

    Default is [].

FieldTypes:

    Default is [].

ForceStrings:

    Default is 0. If 1, sets all FieldTypes to string, may be useful
    if values are very large ints

Rtree:

    Default is 0. If 1, creates an R-tree of the shapes into an
    element Rtree. (Requires LoadAll.)


When a shapefile is read from files they end up in a bit different
kind of data structure than what is expected by the save method for
example and what is described above. These flags enable the
conversion, they are not normally needed.

CombineVertices:

    Default is 1. CombineVertices is experimental. The default
    behavior is to put all vertices into the Vertices array and part
    indexes into the Parts array. If CombineVertices is set to 0 there
    is no Vertices array and all data goes into the Parts.  Currently
    setting CombineVertices to 0 breaks saving of shapefiles.

UnhashFields:

    Default is 1. Makes $self's attributes FieldNames, FieldTypes refs
    to lists, and ShapeRecords a list of lists.


The default is to load all data into Perl variables in the
constructor.  With these options the data can be left into the files
to be loaded on-demand.

Load:

    Default is 1. If 0, has the same effect as LoadRecords=>0 and
    LoadAll=>0.

LoadRecords:

    Default is 1. Reads shape records into $self->{ShapeRecords}
    automatically in the constructor using the
    get_record($shape_index) method

LoadAll:

    Default is 1. Reads shapes (the geometry data) into
    $self->{Shapes} automatically in the constructor using the
    get_shape($shape_index) method


=cut

sub new {
    my $package = shift;
    my $filename;
    my $options = shift;
    unless (ref $options) {
	$filename = $options;
	$options = shift;
    }
    croak "usage: new Geo::Shapelib <filename>, {<options>};" if (defined $options and not ref $options);
    
    my $self = {};
    bless $self => (ref($package) or $package);
    
    $self->{Name} = $filename if $filename;
    
    my %defaults = ( Like => 0,
		     Name => 'shapefile',
		     Shapetype => 'POINT',
		     FieldNames => [],
		     FieldTypes => [],
		     CombineVertices => 1, 
		     UnhashFields => 1,
		     Load => 1,
		     LoadRecords => 1, 
		     LoadAll => 1, 
		     ForceStrings => 0,
		     Rtree => 0 );
    
    for (keys %defaults) {
	next if defined $self->{$_};
	$self->{$_} = $defaults{$_};
    }
    
    if (defined $options and ref $options) {
	for (keys %$options) {
	    croak "unknown constructor option for Geo::Shapelib: $_" unless defined $defaults{$_}
	}
	for (keys %defaults) {
	    next unless defined $options->{$_};
	    $self->{$_} = $options->{$_};
	}
	if ($self->{Like}) {
	    for ('Shapetype','FieldNames','FieldTypes') {
		$self->{$_} = $options->{Like}->{$_};
	    }
	}
    }
    
    return $self unless $filename;
    
#	print "\n\n";
#	for (keys %$self) {
#	    print "$_ $self->{$_}\n";
#	}
    
    # Read the specified file
    
    # Get 'NShapes', 'FieldTypes' and 'ShapeRecords' from the dbf
    my $dbf_handle = DBFOpen($self->{Name}, 'rb');
    unless ($dbf_handle) {
	croak("DBFOpen $self->{Name} failed");
	return undef;
    }
    $self->{NShapes} = DBFGetRecordCount($dbf_handle);
    $self->{FieldNames} = '';
    $self->{FieldTypes} = ReadDataModel($dbf_handle, $self->{ForceStrings});

    if ($self->{Load} and $self->{LoadRecords}) {
	$self->{ShapeRecords} = ReadData($dbf_handle, $self->{ForceStrings});
    }

    DBFClose($dbf_handle);
    #return undef unless $dbf;  # Here, not above, so the dbf always gets closed.
    
    # Get 'Shapetype', 'MinBounds', and 'MaxBounds'
    $self->{SHPHandle} = SHPOpen($self->{Name}, 'rb');
    unless ($self->{SHPHandle}) {
	carp("SHPOpen $self->{Name} failed!");
	return undef;
    }
    my $info = SHPGetInfo($self->{SHPHandle});  # DESTROY closes SHPHandle
    unless ($info) {
	carp("SHPGetInfo failed!");
	return undef;
    }
    @$self{keys %$info} = values %$info;
    $self->{ShapetypeString} = $ShapeTypes{ $self->{Shapetype} };
    
    if ($self->{UnhashFields}) {
	($self->{FieldNames}, $self->{FieldTypes}) = data_model($self);
	if ($self->{Load} and $self->{LoadRecords}) {
	    for my $i (0..$self->{NShapes}-1) {
		$self->{ShapeRecords}->[$i] = get_record_arrayref($self, $i, undef, 1);
	    }
	}
    }
    
    if ($self->{Load} and $self->{LoadAll}) {
	for (my $i = 0; $i < $self->{NShapes}; $i++) {
	    my $shape = get_shape($self, $i, 1);
	    push @{$self->{Shapes}}, $shape;
	}
    }
    
    $self->Rtree() if $self->{Rtree};
    
    return $self;
}

=pod

=head1 METHODS

=head2 data_model

Returns data model converted into two arrays. 

If in a constructor a filename is given, then the data model is read
from the dbf file and stored as a hashref in the attribute FieldTypes.
This converts the hashref into two arrays: FieldNames and respective
FieldTypes. These arrayrefs are stored in attributes of those names if
UnhashFields is TRUE.

=cut

sub data_model {
    my $self = shift;
    my @FieldNames;
    my @FieldTypes;
    while (my($name,$type) = each %{$self->{FieldTypes}}) {
	push @FieldNames,$name;
	push @FieldTypes,$type;
    }
    return (\@FieldNames,\@FieldTypes);
}

=pod

=head2 get_shape(shape_index, from_file)

Returns a shape nr. shape_index+1 (first index is 0). The shape is
read from a file even if array Shapes exists if from_file is TRUE.

Option CombineVertices is in operation here.

Use this method to get a shape unless you know what you are doing.

=cut

sub get_shape {
    my ($self, $i, $from_file) = @_;
    if (!$from_file and $self->{Shapes}) {

	return $self->{Shapes}->[$i];

    } else {

	my $shape = SHPReadObject($self->{SHPHandle}, $i, $self->{CombineVertices}?1:0) or return undef;

	# $shape->{ShapeRecords} = $self->{ShapeRecords}[$i];

	if($self->{CombineVertices}) {
	    for my $part (@{$shape->{Parts}}) {
		$part->[2] = $PartTypes{ $part->[1] };
	    }
	}
	return $shape;

    }
}

=pod

=head2 get_record(shape_index, from_file)

Returns the record which belongs to shape nr. shape_index+1 (first
index is 0). The record is read from a file even if array ShapeRecords
exists if from_file is TRUE.

=cut

sub get_record {
    my ($self, $i, $from_file) = @_;
    if (!$from_file and $self->{ShapeRecords}) {

	return $self->{ShapeRecords}->[$i];

    } else {

	my $dbf_handle = DBFOpen($self->{Name}, 'rb');
	unless ($dbf_handle) {
	    croak("DBFOpen $self->{Name} failed");
	    return undef;
	}
	my $rec = ReadRecord($dbf_handle, $self->{ForceStrings}, $i);
	DBFClose($dbf_handle);
	return $rec;

    }
}

=pod

=head2 get_record_arrayref(shape_index, FieldNames, from_file)

Returns the record which belongs to shape nr. shape_index+1 (first
index is 0) as an arrayref. The parameter FieldNames may be undef but
if defined, it is used as the array according to which the record
array is sorted. This in case the ShapeRecords contains hashrefs.  The
record is read from the file even if array ShapeRecords exists if
from_file is TRUE.

Use this method to get a record of a shape unless you know what you
are doing.

=cut

sub get_record_arrayref {
    my ($self, $i, $FieldNames, $from_file) = @_;
    my $rec = get_record($self, $i, $from_file);
    if (ref $rec eq 'HASH') {
	my @rec;
	$FieldNames = $self->{FieldNames} unless defined $FieldNames;
	for (@$FieldNames) {
	    push @rec,$rec->{$_};
	}
	return \@rec;
    }
    return $rec;
}

=pod

=head2 get_record_hashref(shape_index, from_file)

Returns the record which belongs to shape nr. shape_index+1 (first
index is 0) as a hashref. The record is read from the file even if
array ShapeRecords exists if from_file is TRUE. If records are in the
array ShapeRecords as a list of lists, then FieldNames _must_ contain
the names of the fields.

Use this method to get a record of a shape unless you know what you
are doing.

=cut

sub get_record_hashref {
    my ($self, $i, $from_file) = @_;
    my $rec = get_record($self, $i, $from_file);
    if (ref $rec eq 'ARRAY') {
	my %rec;
	for my $i (0..$#{$self->{FieldNames}}) {
	    $rec{$self->{FieldNames}->[$i]} = $rec->[$i];
	}
	return \%rec;
    }
    return $rec;
}

=pod

=head2 lengths(shape)

Returns the lengths of the parts of the shape. This is lengths of the
parts of polyline or the length of the boundary of polygon. 2D and 3D
data is taken into account.

=cut

sub lengths {
    my ($self, $shape) = @_;
    my @l;
    if ($shape->{NParts}) {
	
	my $pindex = 0;
	my $pmax = $shape->{NParts};
	while($pindex < $pmax) {
	    
	    my $l = 0;
	    my $prev = 0;

	    my $part = $shape->{Parts}[$pindex];
	    
	    if($self->{CombineVertices}) {
		my $vindex = $part->[0];
		my $vmax = $shape->{Parts}[$pindex+1][0];
		$vmax = $shape->{NVertices} unless defined $vmax;
		while($vindex < $vmax) {

		    my $vertex = $shape->{Vertices}[$vindex];
		    if ($prev) {
			my $c2 = 0;
			if ($self->{Shapetype} < 10) { # x,y
			    for (0..1) {
				$c2 += ($vertex->[$_] - $prev->[$_])**2;
			    }
			} else {
			    for (0..2) {
				$c2 += ($vertex->[$_] - $prev->[$_])**2;
			    }
			}
			$l += sqrt($c2);
		    }
		    $prev = $vertex;

		    $vindex++;
		}
	    } else {
		for my $vertex (@{$part->{Vertices}}) {

		    if ($prev) {
			my $c2 = 0;
			if ($self->{Shapetype} < 10) { # x,y
			    for (0..1) {
				$c2 += ($vertex->[$_] - $prev->[$_])**2;
			    }
			} else {
			    for (0..2) {
				$c2 += ($vertex->[$_] - $prev->[$_])**2;
			    }
			}
			$l += sqrt($c2);
		    }
		    $prev = $vertex;

		}
	    }
	    
	    push @l,$l;
	    $pindex++;
	}
	
    } else {
	
	my $l = 0;
	my $prev = 0;
	for my $vertex (@{$shape->{Vertices}}) {
	    
	    if ($prev) {
		my $c2 = 0;
		if ($self->{Shapetype} < 10) { # x,y
		    for (0..1) {
			$c2 += ($vertex->[$_] - $prev->[$_])**2;
		    }
		} else {
		    for (0..2) {
			$c2 += ($vertex->[$_] - $prev->[$_])**2;
		    }
		}
		$l += sqrt($c2);
	    }
	    $prev = $vertex;
	}
	push @l,$l;
	
    }
    
    return @l;
}

=pod

=head2 Using shapefile quadtree spatial indexing

Obtain a list of shape ids within the specified bound using a shapefile quadtree
index:

    $shapefile->query_within_rect($bounds, $maxdepth = 0);

$bounds should be an array reference of 4 elements (xmin, ymin, xmax, ymax)

This method uses the quadtree indices defined by Shapelib *not* ESRI
spatial index files (.sbn, .sbx). If a quadtree index (<basename>.qix)
does not exist, one is created and saved as a file.

To just create an index you can also use the method:

    $shapefile->create_spatial_index($maxdepth = 0);

$maxdepth (optional) is the maximum depth of the index to create. Default is 0
meaning that shapelib will calculate a reasonable default depth.

=cut

sub query_within_rect {
    my ($self, $bounds, $maxdepth) = @_;
    croak "Shapefile is not open." unless $self->{SHPHandle};
    my $fn = $self->qix_filename;
    $maxdepth ||= 0;
    my $found = SHPSearchDiskTree($self->{SHPHandle}, $fn, $bounds, $maxdepth);
    return $found;
}

sub create_spatial_index {
    my ($self, $maxdepth, $quiet) = @_;
    $maxdepth ||= 0;
    croak "Shapefile is not open." unless $self->{SHPHandle};
    my $fn = $self->qix_filename;
    my $ret = SHPCreateSpatialIndex($fn, $maxdepth, $self->{SHPHandle});
    croak "Could not create the spatial index file: $fn." if !$ret;
    return $ret;
}

sub qix_filename {
    my $self = shift;
    my ($file, $path, $suffix) = fileparse( $self->{Name}, '.shp' );
    return "$path$file.qix";
}

=pod

=head2 Rtree and editing the shapefile

Building a R-tree for the shapes:

    $shapefile->Rtree();

This is automatically done if Rtree-option is set when a shapefile is
loaded from files.

You can then use methods like (there are not yet any wrappers for
these).

    my @shapes;
    $shapefile->{Rtree}->query_point(@xy,\@shapes); # or
    $shapefile->{Rtree}->query_completely_within_rect(@rect,\@shapes); # or
    $shapefile->{Rtree}->query_partly_within_rect(@rect,\@shapes);

To get a list of shapes (indexes to the shape array), which you can
feed for example to the select_vertices function.

    for my $shape (@shapes) {
	my $vertices = $shapefile->select_vertices($shape,@rect);
	my $n = @$vertices;
	print "you selected $n vertices from shape $shape\n";
    }

The shapefile object remembers the selected vertices and calling the
function

    $shapefile->move_selected_vertices($dx,$dy);

moves the vertices. The bboxes of the affected shapes, and the R-tree,
if one exists, are updated automatically. To clear all selections from
all shapes, call:

    $selected->clear_selections();

=cut

sub Rtree {
    my $self = shift @_;
    unless (defined $self->{NShapes}) {
	croak "no shapes" unless $self->{Shapes} and ref $self->{Shapes} eq 'ARRAY' and @{$self->{Shapes}};
	$self->{NShapes} = @{$self->{Shapes}};
    }
    $self->{Rtree} = new Tree::R @_;
    for my $sindex (0..$self->{NShapes}-1) {
	my $shape = get_shape($self, $sindex);
	my @rect;
	@rect[0..1] = @{$shape->{MinBounds}}[0..1];
	@rect[2..3] = @{$shape->{MaxBounds}}[0..1];

	$self->{Rtree}->insert($sindex,@rect);
    }
}

sub clear_selections {
    my($self) = @_;
    for my $shape (@{$self->{Shapes}}) {
	$shape->{SelectedVertices} = [];
    }
}

sub select_vertices {
    my($self,$shape,$minx,$miny,$maxx,$maxy) = @_;
    unless (defined $shape) {
	for my $sindex (0..$self->{NShapes}-1) {
	    $self->select_vertices($sindex);
	}
	return;
    }
    $shape = $self->{Shapes}->[$shape];
    my @vertices;
    unless (defined $maxy) {
	@vertices = (0..$shape->{NVertices}-1);
	$shape->{SelectedVertices} = \@vertices;
	return \@vertices;
    }
    my $v = $shape->{Vertices};
    my $i;
    for ($i = 0; $i < $shape->{NVertices}; $i++) {
	next unless 
	    $v->[$i]->[0] >= $minx and
	    $v->[$i]->[0] <= $maxx and
	    $v->[$i]->[1] >= $miny and
	    $v->[$i]->[1] <= $maxy;
	push @vertices,$i;
    }
    $shape->{SelectedVertices} = \@vertices;
    return \@vertices;
}

sub move_selected_vertices {
    my($self,$dx,$dy) = @_;
    return unless $self->{NShapes};

    my $count = 0;
    for my $sindex (0..$self->{NShapes}-1) {
	my $shape = $self->{Shapes}->[$sindex];
	next unless $shape->{SelectedVertices} and @{$shape->{SelectedVertices}};

	my $v = $shape->{Vertices};
	for my $vindex (@{$shape->{SelectedVertices}}) {
	    $v->[$vindex]->[0] += $dx;
	    $v->[$vindex]->[1] += $dy;
	}

	my @rect;
	for my $vertex (@{$shape->{Vertices}}) {
	    $rect[0] = defined($rect[0]) ? min($vertex->[0],$rect[0]) : $vertex->[0];
	    $rect[1] = defined($rect[1]) ? min($vertex->[1],$rect[1]) : $vertex->[1];
	    $rect[2] = defined($rect[2]) ? max($vertex->[0],$rect[2]) : $vertex->[0];
	    $rect[3] = defined($rect[3]) ? max($vertex->[1],$rect[3]) : $vertex->[1];
	}

	@{$shape->{MinBounds}}[0..1] = @rect[0..1];
	@{$shape->{MaxBounds}}[0..1] = @rect[2..3];
	$count++;
    }

    if ($self->{Rtree}) {
	if ($count < 10) {
	    for my $sindex (0..$self->{NShapes}-1) {
		my $shape = $self->{Shapes}->[$sindex];
		next unless $shape->{SelectedVertices} and @{$shape->{SelectedVertices}};
		
		# update Rtree... 	
		
		#delete $sindex from it
		print STDERR "remove $sindex\n";
		$self->{Rtree}->remove($sindex);
	    }
	    for my $sindex (0..$self->{NShapes}-1) {
		my $shape = $self->{Shapes}->[$sindex];
		next unless $shape->{SelectedVertices} and @{$shape->{SelectedVertices}};
		
		my @rect = (@{$shape->{MinBounds}}[0..1],@{$shape->{MaxBounds}}[0..1]);
		
		# update Rtree... 	
		
		# add $sindex to it
		print STDERR "add $sindex\n";
		$self->{Rtree}->insert($sindex,@rect);
	    }
	} else {
	    $self->Rtree;
	}
    }

    $self->{MinBounds}->[0] = $self->{Shapes}->[0]->{MinBounds}->[0];
    $self->{MinBounds}->[1] = $self->{Shapes}->[0]->{MinBounds}->[1];
    $self->{MaxBounds}->[0] = $self->{Shapes}->[0]->{MaxBounds}->[0];
    $self->{MaxBounds}->[1] = $self->{Shapes}->[0]->{MaxBounds}->[1];
    for my $sindex (1..$self->{NShapes}-1) {
	my $shape = $self->{Shapes}->[$sindex];
	$self->{MinBounds}->[0] = min($self->{MinBounds}->[0],$shape->{MinBounds}->[0]);
	$self->{MinBounds}->[1] = min($self->{MinBounds}->[1],$shape->{MinBounds}->[1]);
	$self->{MaxBounds}->[0] = max($self->{MaxBounds}->[0],$shape->{MaxBounds}->[0]);
	$self->{MaxBounds}->[1] = max($self->{MaxBounds}->[1],$shape->{MaxBounds}->[1]);
    }
}

sub min {
    $_[0] > $_[1] ? $_[1] : $_[0];
}

sub max {
    $_[0] > $_[1] ? $_[0] : $_[1];
}

=pod

=head2 Setting the bounds of the shapefile

    $shapefile->set_bounds;

Sets the MinBounds and MaxBounds of all shapes and of the shapefile.

=cut

sub set_bounds {
    my($self) = @_;

    return unless @{$self->{Shapes}};

    my $first = 1;

    for my $shape (@{$self->{Shapes}}) {

	my @rect;
	for my $vertex (@{$shape->{Vertices}}) {
	    $rect[0] = defined($rect[0]) ? min($vertex->[0],$rect[0]) : $vertex->[0];
	    $rect[1] = defined($rect[1]) ? min($vertex->[1],$rect[1]) : $vertex->[1];
	    $rect[2] = defined($rect[2]) ? max($vertex->[0],$rect[2]) : $vertex->[0];
	    $rect[3] = defined($rect[3]) ? max($vertex->[1],$rect[3]) : $vertex->[1];
	}

	@{$shape->{MinBounds}}[0..1] = @rect[0..1];
	@{$shape->{MaxBounds}}[0..1] = @rect[2..3];

	if ($first) {
	    $self->{MinBounds}->[0] = $shape->{MinBounds}->[0];
	    $self->{MinBounds}->[1] = $shape->{MinBounds}->[1];
	    $self->{MaxBounds}->[0] = $shape->{MaxBounds}->[0];
	    $self->{MaxBounds}->[1] = $shape->{MaxBounds}->[1];
	    $first = 0;
	} else {
	    $self->{MinBounds}->[0] = min($self->{MinBounds}->[0],$shape->{MinBounds}->[0]);
	    $self->{MinBounds}->[1] = min($self->{MinBounds}->[1],$shape->{MinBounds}->[1]);
	    $self->{MaxBounds}->[0] = max($self->{MaxBounds}->[0],$shape->{MaxBounds}->[0]);
	    $self->{MaxBounds}->[1] = max($self->{MaxBounds}->[1],$shape->{MaxBounds}->[1]);
	}

    }

}

=pod

=head2 Saving the shapefile

    $shapefile->save($filename);

The argument $shapefile is optional, the internal attribute
$shapefile->{Name} is used if $filename is not specified. If $filename
is specified it also becomes the new name.

$filename may contain an extension, it is removed and .shp etc. are used instead.

If you are not sure that the bounds of the shapefile are ok, then call
$shapefile->set_bounds; before saving.

=cut

sub save {
    my($self,$filename) = @_;

    unless (defined $self->{NShapes}) {
	croak "no shapes" unless $self->{Shapes} and ref $self->{Shapes} eq 'ARRAY' and @{$self->{Shapes}};
	$self->{NShapes} = @{$self->{Shapes}};
    }

    $self->create($filename);

    for my $i (0..$self->{NShapes}-1) {
	my $s = get_shape($self, $i);
	my $rec = get_record($self, $i);
	$self->add($s, $rec);
    }

    $self->close();
}

=pod

=head2 create, add, close

$shapefile->create($filename);

many times: 
    $shapefile->add($shape, $record);

$shapefile->close();

These methods make it easy to create large shapefiles. $filename is
optional. These methods create some temporary variables (prefix: _) in
internal data and thus calling of close method is required.

=cut

sub create {
    my ($self, $filename) = @_;

    $filename = $self->{Name} unless defined $filename;
    $filename =~ s/\.\w+$//;
    $self->{_filename} = $filename;

    $self->{_SHPhandle} = SHPCreate($filename.'.shp', $self->{Shapetype});
    croak "SHPCreate failed" unless $self->{_SHPhandle};

    $self->{_DBFhandle} = DBFCreate($filename.'.dbf');
    croak "DBFCreate failed" unless $self->{_DBFhandle};
    
    $self->{_fn} = $self->{FieldNames};
    my $ft = $self->{FieldTypes};
    unless ($self->{_fn}) {
	($self->{_fn}, $ft) = data_model($self);
    }
    for my $f (0..$#{$self->{_fn}}) {
	my $type = 0;
	my $width;
	my $decimals = 0;
        my ($ftype, $fwidth, $fdeci) = split(/[:;,]/, $ft->[$f]);
      SWITCH: {
	  if ($ftype eq 'String') { 
	      $type = 1;
	      $width = defined($fwidth)?$fwidth:255;      
	      last SWITCH; 
	  }
	  if ($ftype eq 'Integer') { 
	      $type = 2;
	      $width = defined($fwidth)?$fwidth:10;
	      last SWITCH; 
	  }
	  if ($ftype eq 'Double') { 
	      $type = 3;
	      $width = defined($fwidth)?$fwidth:10;
	      $decimals = defined($fdeci)?$fdeci:4;
	      last SWITCH; 
	  }
      }
	$self->{_ftypes}->[$f] = $type;
	next unless $type;
	my $ret = _DBFAddField($self->{_DBFhandle}, $self->{_fn}->[$f], $type, $width, $decimals);
	croak "DBFAddField failed for field $self->{_fn}->[$f] of type $ft->[$f]" if $ret == -1;
    }
    
    $self->{_SHP_id} = 0;
}

sub add {
    my ($self, $shape, $record) = @_;

    if (defined($shape->{SHPType})) {
	if ($shape->{SHPType} != 0 and $shape->{SHPType} != $self->{Shapetype}) {
	    croak "non-null shapes with differing shape types";
	}
    } else {
	$shape->{SHPType} = $self->{Shapetype};
    }
    my $nParts =  exists $shape->{Parts} ? @{$shape->{Parts}} : 0;
    if (defined $shape->{NParts}) {
	if ($shape->{NParts} > $nParts) {
	    croak "NParts is larger than the actual number of Parts";
	} else {
	    $nParts = $shape->{NParts};
	}
    }
    my $nVertices =  exists $shape->{Vertices} ? @{$shape->{Vertices}} : 0;
    if (defined $shape->{NVertices}) {
	if ($shape->{NVertices} > $nVertices) {
	    croak "NVertices is larger than the actual number of Vertices";
	} else {
	    $nVertices = $shape->{NVertices};
	}
    }
    my $id = defined $shape->{ShapeId} ? $shape->{ShapeId} : $self->{_SHP_id};

    my $s = _SHPCreateObject($shape->{SHPType}, $id, $nParts, $shape->{Parts}, $nVertices, $shape->{Vertices});
    croak "SHPCreateObject failed" unless $s;
    SHPWriteObject($self->{_SHPhandle}, -1, $s);
    SHPDestroyObject($s);

    my $r = $record;
    if (ref $r eq 'HASH') {
	my @rec;
	for (@{$self->{_fn}}) {
	    push @rec,$r->{$_};
	}
	$r = \@rec;
    }

    for my $f (0..$#{$self->{_fn}}) {
	next unless $self->{_ftypes}->[$f];
	my $ret;
      SWITCH: {
	  if ($self->{_ftypes}->[$f] == 1) { 
	      $ret = DBFWriteStringAttribute($self->{_DBFhandle}, $self->{_SHP_id}, $f, $r->[$f]) if exists $r->[$f];
	      last SWITCH; 
	  }
	  if ($self->{_ftypes}->[$f] == 2) { 
	      $ret = DBFWriteIntegerAttribute($self->{_DBFhandle}, $self->{_SHP_id}, $f, $r->[$f]) if exists $r->[$f];
	      last SWITCH; 
	  }
	  if ($self->{_ftypes}->[$f] == 3) { 
	      $ret = DBFWriteDoubleAttribute($self->{_DBFhandle}, $self->{_SHP_id}, $f, $r->[$f]) if exists $r->[$f];
	      last SWITCH; 
	  }
      }
	croak "DBFWriteAttribute(field = $self->{_fn}->[$f], ftype = $self->{_ftypes}[$f], value = $r->[$f]) failed" unless $ret;
    }
    
    $self->{_SHP_id}++;
}

sub close {
    my ($self) = @_;
    SHPClose($self->{_SHPhandle});
    DBFClose($self->{_DBFhandle});
    $self->{Name} = $self->{_filename};
    delete $self->{_SHPhandle};
    delete $self->{_DBFhandle};
    delete $self->{_fn};
    delete $self->{_ftypes};
    delete $self->{_SHP_id};
    delete $self->{_filename};
}

=pod

=head2 Dump

$shapefile->dump($to);

$to can be undef (then dump uses STDOUT), filename, or reference to a
filehandle (e.g., \*DUMP).

This method just dumps all data. If you have yourself created the
shapefile then the reported bounds may be incorrect.

=cut

sub dump {
    my ($self,$file) = @_;

    unless (defined $self->{NShapes}) {
	croak "no shapes" unless $self->{Shapes} and ref $self->{Shapes} eq 'ARRAY' and @{$self->{Shapes}};
	$self->{NShapes} = @{$self->{Shapes}};
    }
    
    my $old_select;
    if (defined $file) {
	if (not ref $file) {
	    # $file is a name that we'll convert to a file handle
	    # ref.  Passing open a scalar makes it close when the
	    # scaler is destroyed.
	    my $fh;
	    unless (open $fh, ">$file") {
		carp("$file: $!"),
		return undef;
	    }
	    $file = $fh;
	}
		return undef unless ref($file) eq 'GLOB';
	$old_select = select($file);
    }
    
    printf "Name:  %s\n", ($self->{Name} or '(none)');
    print "Shape type:  $self->{Shapetype} ($ShapeTypes{$self->{Shapetype}})\n";
    printf "Min bounds:  %11f %11f %11f %11f\n", @{$self->{MinBounds}} if $self->{MinBounds};
    printf "Max bounds:  %11f %11f %11f %11f\n", @{$self->{MaxBounds}} if $self->{MaxBounds};
    my $fn = $self->{FieldNames};
    my $ft = $self->{FieldTypes};
    unless ($fn) {
	($fn, $ft) = data_model($self);
    }
    print "Field names:  ", join(', ', @$fn), "\n";
    print "Field types:  ", join(', ', @$ft), "\n";

    print "Number of shapes:  $self->{NShapes}\n";
    
    my $sindex = 0;
    while($sindex < $self->{NShapes}) {
	my $shape = get_shape($self, $sindex);
	my $rec = get_record_arrayref($self, $sindex, $fn);
	
	print "Begin shape ",$sindex+1," of $self->{NShapes}\n";
	print "\tShape id: $shape->{ShapeId}\n";
	print "\tShape type: $shape->{SHPType} ($ShapeTypes{$shape->{SHPType}})\n";
	printf "\tMin bounds:  %11f %11f %11f %11f\n", @{$shape->{MinBounds}} if $shape->{MinBounds};
	printf "\tMax bounds:  %11f %11f %11f %11f\n", @{$shape->{MaxBounds}} if $shape->{MaxBounds};
	
	print "\tShape record:  ", join(', ', @$rec), "\n";
	
	if ($shape->{NParts}) {
	    
	    my $pindex = 0;
	    my $pmax = $shape->{NParts};
	    while($pindex < $pmax) {
		my $part = $shape->{Parts}[$pindex];
		print "\tBegin part ",$pindex+1," of $pmax\n";
		
		if($self->{CombineVertices}) {
		    print "\t\tPartType:  $part->[1] ($part->[2])\n";
		    my $vindex = $part->[0];
		    my $vmax = $shape->{Parts}[$pindex+1][0];
		    $vmax = $shape->{NVertices} unless defined $vmax;
		    while($vindex < $vmax) {
			printf "\t\tVertex:  %11f %11f %11f %11f\n", @{$shape->{Vertices}[$vindex]};
			$vindex++;
		    }
		} else {
		    print "\t\tPart id:  $part->{PartId}\n";
		    print "\t\tPart type:  $part->{PartType} ($PartTypes{$part->{PartType}})\n";
		    for my $vertex (@{$part->{Vertices}}) {
			printf "\t\tVertex:  %11f %11f %11f %11f\n", @$vertex;
		    }
		}
		
		print "\tEnd part ",$pindex+1," of $pmax\n";
		$pindex++;
	    }
	    
	} else {
	    
	    for my $vertex (@{$shape->{Vertices}}) {
		printf "\t\tVertex:  %11f %11f %11f %11f\n", @$vertex;
	    }
	    
	}
	
	print "End shape ",$sindex+1," of $self->{NShapes}\n";
	$sindex++;
    }
    
    select $old_select if defined $old_select;
    return 1;
}

sub DESTROY {
    my $self = shift;
    SHPClose($self->{SHPHandle}) if defined $self->{SHPHandle};
}

1;
__END__


=head1 AUTHOR

Ari Jolma, https://github.com/ajolma

=head1 REPOSITORY

L<https://github.com/ajolma/Geo-Shapelib>

=cut
