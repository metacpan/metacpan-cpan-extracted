=pod

=head1 NAME

Geo::OGC::Geometry - Perl extension for OGC simple feature geometries

=head1 SYNOPSIS

    use Geo::OGC::Geometry;

    my $point = Geo::OGC::Point->new(Text => 'POINT 1 1');

=head1 DESCRIPTION

OGC simple feature geometries is a class hierarchy for geographic
information. This module conforms to the document OGC 06-103r4, which
is the current document describing the standard. The document is
available from L<http://www.opengeospatial.org/>.

This module is currently mostly an interface and storage classes and
does not contain implementations of most of the methods for testing
spatial relations etc.

=head1 CLASSES

=head2 Geo::OGC::Geometry

Geo::OGC::Geometry is the root class and it represents an arbitrary
geospatial geometry.

=cut

package Geo::OGC::Geometry;

use strict;
use POSIX;
use Carp;

BEGIN {
    use Exporter 'import';
    use vars qw /$SNAP_DISTANCE_SQR/;
    POSIX::setlocale( &POSIX::LC_NUMERIC, "C" ); # Force to "C" locale
    our %EXPORT_TAGS = ( 'all' => [ qw( &ccw &intersect &distance_point_line_sqr 
					$SNAP_DISTANCE_SQR ) ] );
    our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
    our $VERSION = '0.06';
    $SNAP_DISTANCE_SQR = 1E-6;
}

=pod

=over

=item new(%params)

Create a new Geometry object or a new object belonging to a concrete
subclass of Geometry if initialization data is given.

%param is a hash containing named parameters. The keywords are
(subclasses of Geometry may add new keywords):

=over

=item Text

A well-known text to initialize an object of a concrete class.

=item SRID

Sets the Spatial Reference System ID of the object, default is -1.

=item Precision

If specified, has the effect that numeric comparisons in the Equals
method is is preceded with a rounding operation (using sprintf "%.pe",
where p is the Precision-1, i.e the number of meaningful numbers is
Precision). Affects also AsText.

=back

=cut

sub new {
    my($package, %params) = @_;
    return parse_wkt($params{Text}) if exists $params{Text};
    my $self = {};
    bless $self => (ref($package) or $package);
    $self->init(%params);
    return $self;
}

# methods beginning with lower case letter are private
# and thus not in pod

# Override in new classes but call $self->SUPER::init(%params);
sub init {
    my($self, %params) = @_;
    $self->{SRID} = exists $params{SRID} ? $params{SRID} : -1;
    $self->{Precision} = $params{Precision}-1 if exists $params{Precision};
}

# Copies the attributes of this object to the other object,
# which is a newly created object of same class.
sub copy {
    my($self, $clone) = @_;
    $clone->{SRID} = $self->{SRID};
    $clone->{Precision} = $self->{Precision} if exists $self->{Precision};
}

# parse well known text and construct respective geometry
sub parse_wkt {
    my $text = shift;
    my $self;
    my $type;
    my $prefix;
    for my $t (qw/POINT MULTIPOINT LINESTRING MULTILINESTRING
    LINEARRING POLYGON POLYHEDRALSURFACE MULTIPOLYGON
    GEOMETRYCOLLECTION/) {
        next unless $text =~ /^\s*$t/i;
        $type = $t;
        $text =~ s/^\s*$t\s*//i;
        if ($text =~ /^EMPTY/i) {
            $text = undef;
        } else {
            $text =~ s/^([ZM]*)\s*\(\s*//i;
            $prefix = lc($1);
            $text =~ s/\s*\)\s*$//;
        }
        last;
    }
    if ($type eq 'POINT') {
        return Geo::OGC::Point->new unless $text;
        my @point = split /\s+/, $text;
        $self = Geo::OGC::Point->new("point$prefix"=>\@point);
    } elsif ($type eq 'MULTIPOINT') {
        return Geo::OGC::MultiPoint->new unless $text;
        $text =~ s/^\(\s*//;
        $text =~ s/\)\s*$//;
        my @points = split /\s*,\s*/, $text;
        $self = Geo::OGC::MultiPoint->new();
        for my $p (@points) {
            $self->AddGeometry(parse_wkt("POINT $prefix ($p)"));
        }
    } elsif ($type eq 'LINESTRING') {
        return Geo::OGC::LineString->new unless $text;
        $text =~ s/^\(\s*//;
        $text =~ s/\)\s*$//;
        my @points = split /\s*,\s*/, $text;
        $self = Geo::OGC::LineString->new();
        for my $p (@points) {
            $self->AddPoint(parse_wkt("POINT $prefix ($p)"));
        }
    } elsif ($type eq 'MULTILINESTRING') {
        return Geo::OGC::MultiLineString->new unless $text;
        $text =~ s/^\(\s*//;
        $text =~ s/\)\s*$//;
        my @strings = split /\)\s*,\s*\(/, $text;
        $self = Geo::OGC::MultiLineString->new();
        for my $s (@strings) {
            $self->AddGeometry(parse_wkt("LINESTRING $prefix ($s)"));
        }
    } elsif ($type eq 'LINEARRING') {
        return Geo::OGC::LinearRing->new unless $text;
        $text =~ s/^\(\s*//;
        $text =~ s/\)\s*$//;
        my @points = split /\s*,\s*/, $text;
        $self = Geo::OGC::LinearRing->new();
        for my $p (@points) {
            $self->AddPoint(parse_wkt("POINT $prefix ($p)"));
        }
    } elsif ($type eq 'POLYGON') {
        return Geo::OGC::Polygon->new unless $text;
        $text =~ s/^\(\s*//;
        $text =~ s/\)\s*$//;
        my @rings = split /\)\s*,\s*\(/, $text;
        $self = Geo::OGC::Polygon->new();
        $self->ExteriorRing(parse_wkt("LINEARRING $prefix (".shift(@rings).")"));
        for my $r (@rings) {
            $self->AddInteriorRing(parse_wkt("LINEARRING $prefix ($r)"));
        }
    } elsif ($type eq 'POLYHEDRALSURFACE') {
        return Geo::OGC::PolyhedralSurface->new unless $text;
        $text =~ s/^\(\s*//;
        $text =~ s/\)\s*$//;
        my @patches = split /\)\s*,\s*\(/, $text;
        $self = Geo::OGC::PolyhedralSurface->new();
        for my $p (@patches) {
            $self->AddPatch(parse_wkt("POLYGON $prefix ($p)"));
        }
    } elsif ($type eq 'MULTIPOLYGON') {
        return Geo::OGC::MultiPolygon->new unless $text;
        $text =~ s/^\(\s*\(\s*//;
        $text =~ s/\)\s*\)\s*$//;
        my @polygons = split /\)\s*\)\s*,\s*\(\s*\(/, $text;
        $self = Geo::OGC::MultiPolygon->new();
        for my $p (@polygons) {
            $self->AddGeometry(parse_wkt("POLYGON $prefix (($p))"));
        }
    } elsif ($type eq 'GEOMETRYCOLLECTION') {
        return Geo::OGC::GeometryCollection->new unless $text;
        my @b = $text =~ /,([A-Z])/g;
        unshift @b,'';
        my @geometries = split /,[A-Z]/, $text;
        $self = Geo::OGC::GeometryCollection->new();
        for my $i (0..$#geometries) {
            $self->AddGeometry(parse_wkt($b[$i].$geometries[$i]));
        }
    } else {
        my $b = substr $text, 0, 20;
        croak "can't parse text beginning as: $b";
    }
    return $self;
}

# counterclockwise from Sedgewick: Algorithms in C
sub ccw {
    my($x0, $y0, $x1, $y1, $x2, $y2) = @_;
    my $dx1 = $x1 - $x0; 
    my $dy1 = $y1 - $y0;
    my $dx2 = $x2 - $x0; 
    my $dy2 = $y2 - $y0;
    return +1 if $dx1*$dy2 > $dy1*$dx2;
    return -1 if $dx1*$dy2 < $dy1*$dx2;
    return -1 if ($dx1*$dx2 < 0) or ($dy1*$dy2 < 0);
    return +1 if ($dx1*$dx1+$dy1*$dy1) < ($dx2*$dx2+$dy2*$dy2);
    return 0;
}

# Test intersection of two lines from Sedgewick: Algorithms in C
sub intersect {
    my($x11, $y11, $x12, $y12, $x21, $y21, $x22, $y22) = @_;
    return ((ccw($x11, $y11, $x12, $y12, $x21, $y21)
	     *ccw($x11, $y11, $x12, $y12, $x22, $y22)) <= 0)
	&& ((ccw($x21, $y21, $x22, $y22, $x11, $y11)
	     *ccw($x21, $y21, $x22, $y22, $x12, $y12)) <= 0);
}

sub intersection_point {
    my($x11, $y11, $x12, $y12, $x21, $y21, $x22, $y22) = @_;
    my $dy1 = $y12 - $y11;
    my $dx1 = $x12 - $x11;
    my $dy2 = $y22 - $y21;
    my $dx2 = $x22 - $x21;
    # (dy1*dx2 - dy2*dx1)*x = dx1*dx2*(y21-y11) - dy2*dx1*x21 + dy1*dx2*x11
    # (dy1*dx1 - dy2*dx2)*y = dy1*dy2*(x21-x11) - dy1*dx2*y21 + dy2*dx1*y11
    my $x = ($dx1*$dx2*($y21-$y11) - $dy2*$dx1*$x21 + $dy1*$dx2*$x11)/($dy1*$dx2 - $dy2*$dx1);
    my $y = ($dy1*$dy2*($x21-$x11) - $dy1*$dx2*$y21 + $dy2*$dx1*$y11)/($dy1*$dx1 - $dy2*$dx2);
    return ($x, $y);
}

# Compute the distance of a point to a line.
sub distance_point_line_sqr {
    my($x, $y, $x1, $y1, $x2, $y2) = @_;
    my $dx = $x2-$x1;
    my $dy = $y2-$y1;
    my $l2 = $dx*$dx + $dy*$dy;
    my $u = (($x - $x1) * $dx + ($y - $y1) * $dy) / $l2;
    if ($u < 0) { # distance to point 1
	return (($x-$x1)*($x-$x1) + ($y-$y1)*($y-$y1));
    } elsif ($u > 1) { # distance to point 2
	return (($x-$x2)*($x-$x2) + ($y-$y2)*($y-$y2));
    } else {
	my $ix = $x1 + $u * $dx;
	my $iy = $y1 + $u * $dy;
	return (($x-$ix)*($x-$ix) + ($y-$iy)*($y-$iy));
    }
}

=pod

=item Clone()

Clones this object, i.e., creates a spatially exact copy.

=cut

sub Clone {
    my($self) = @_;
    my $clone = Geo::OGC::Geometry::new($self);
    $self->copy($clone);
    return $clone;
}

=pod

=item Precision($precision)

Sets or gets the precision.

Not in the specification.

=cut

sub Precision {
    my($self, $Precision) = @_;
    defined $Precision ? 
	$self->{Precision} = $Precision-1 : $self->{Precision}+1;
}

=pod

=item Dimension()

The dimension (2 or 3) of this geometric object. In non-homogeneous
collections, this will return the largest topological dimension of the
contained objects.

=cut

sub Dimension {
    my($self) = @_;
    croak "Dimension method for class ".ref($self)." is not implemented yet";
}

=pod

=item GeometryType()

Returns the geometry type of this object.

=cut

sub GeometryType {
    my($self) = @_;
    croak "GeometryType method for class ".ref($self)." is not implemented yet";
}

=pod

=item SRID($srid)

Get or set Spatial Reference System ID for this object.

=cut

sub SRID {
    my($self, $SRID) = @_;
    defined $SRID ? 
	$self->{SRID} = $SRID : $self->{SRID};
}

=pod

=item Envelope()

Compute the minimum bounding box for this geometry as a ring.

=cut

sub Envelope {
    my($self) = @_;
    croak "Envelope method for class ".ref($self)." is not implemented yet";
}

# A helper method used by AsText
sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    croak "as_text method for class ".ref($self)." is not implemented yet";
}

=pod

=item AsText()

This object in Well-known Text representation.

=cut

sub AsText {
    my($self) = @_;
    return uc($self->GeometryType).' '.'EMPTY' if $self->IsEmpty;
    return $self->as_text(1, 1);
}

=pod

=item AsBinary()

This object in Well-known Binary representation.

=cut

sub AsBinary {
    my($self) = @_;
    croak "AsBinary method for class ".ref($self)." is not implemented yet";
}

=pod

=item IsEmpty()

Returns true if this object is empty, i.e. contains no points.

=cut

sub IsEmpty {
    my($self) = @_;
    croak "IsEmpty method for class ".ref($self)." is not implemented yet";
}

=pod

=item IsSimple()

Returns true if this geometric object has no anomalous geometric
points, such as self intersection or self tangency.

=cut

sub IsSimple {
    my($self) = @_;
    croak "IsSimple method for class ".ref($self)." is not implemented yet";
}

=pod

=item Is3D()

Returns true if this geometric object has z coordinate values.

=cut

sub Is3D {
    my($self) = @_;
    croak "Is3D method for class ".ref($self)." is not implemented yet";
}

=pod

=item IsMeasured()

Returns true if this object has m coordinate values.

=cut

sub IsMeasured {
    my($self) = @_;
    croak "IsMeasured method for class ".ref($self)." is not implemented yet";
}

=pod

=item Boundary()

Returns the closure of the combinatorial boundary of this object.

=cut

sub Boundary {
    my($self) = @_;
    croak "Boundary method for class ".ref($self)." is not implemented yet";
}

=pod

=item Equals($geometry)

Returns true if this object is "spatially equal" to the other
geometry.

=cut

sub Equals {
    my($self, $geom) = @_;
    croak "Equals method for class ".ref($self)." is not implemented yet";
}

=pod

=item Disjoint($geometry)

Returns true if this object is "spatially disjoint" from the other geometry.

=cut

sub Disjoint {
    my($self, $geom) = @_;
    croak "Disjoint method for class ".ref($self)." is not implemented yet";
}

=pod

=item Intersects($geometry)

Returns true if this object "spatially intersects" the other geometry.

=cut

sub Intersects {
    my($self, $geom) = @_;
    croak "Intersects method for class ".ref($self)." is not implemented yet";
}

=pod

=item Touches($geometry)

Returns true if this object "spatially touches" the other geometry.

=cut

sub Touches {
    my($self, $geom) = @_;
    croak "Touches method for class ".ref($self)." is not implemented yet";
}

=pod

=item Crosses($geometry)

Returns true if this object "spatially crosses" the other geometry.

=cut

sub Crosses {
    my($self, $geom) = @_;
    croak "Crosses method for class ".ref($self)." is not implemented yet";
}

=pod

=item Within($geometry)

Returns true if this object is "spatially within" the other geometry.

=cut

sub Within {
    my($self, $geom) = @_;
    croak "Within method for class ".ref($self)." is not implemented yet";
}

=pod

=item Contains($geometry)

Returns true if this object "spatially contains" the other geometry.

=cut

sub Contains {
    my($self, $geom) = @_;
    croak "Contains method for class ".ref($self)." is not implemented yet";
}

=pod

=item Overlaps($geometry)

Returns true if this object "spatially overlaps" the other geometry.

=cut

sub Overlaps {
    my($self, $geom) = @_;
    croak "Overlaps method for class ".ref($self)." is not implemented yet";
}

=pod

=item Relate($geometry, $intersectionPatternMatrix)

Returns true if this object is spatially related to the other geometry
by testing for intersections between the interior, boundary and
exterior of the two geometric objects as specified by the values in
the intersectionPatternMatrix.  This returns FALSE if all the tested
intersections are empty except exterior (this) intersect exterior
(another).

=cut

sub Relate {
    my($self, $geom, $int_pat) = @_;
    croak "Relate method for class ".ref($self)." is not implemented yet";
}

=pod

=item LocateAlong($mValue)

Returns a derived geometry collection value that matches the
specified m coordinate value.

=cut

sub LocateAlong {
    my($self, $mValue) = @_;
    croak "LocateAlong method for class ".ref($self)." is not implemented yet";
}

=pod

=item LocateBetween($mStart, $mEnd)

Returns a derived geometry collection value that matches the specified
range of m coordinate values inclusively.

=cut

sub LocateBetween {
    my($self, $mStart, $mEnd) = @_;
    croak "LocateBetween method for class ".ref($self)." is not implemented yet";
}

=pod

=item Distance($geometry)

Returns the shortest distance between any two points between this object and the other geometry.

=cut

sub Distance {
    my($self, $geom) = @_;
    croak "Distance method for class ".ref($self)." is not implemented yet";
}

=pod

=item Buffer($distance)

Returns a surface whose points are closer than or at the given distance from this object.

=cut

sub Buffer {
    my($self, $distance) = @_;
    croak "Buffer method for class ".ref($self)." is not implemented yet";
}

=pod

=item ConvexHull()

Returns a convex hull of this object.

=cut

sub ConvexHull {
    my($self) = @_;
    croak "ConvexHull method for class ".ref($self)." is not implemented yet";
}

=pod

=item Intersection($geometry)

Returns a point set intersection of this object with the other geometry.

=cut

sub Intersection {
    my($self, $geom) = @_;
    croak "Intersection method for class ".ref($self)." is not implemented yet";
}

=pod

=item Union($geometry)

Returns a point set union of this object with the other geometry.

=cut

sub Union {
    my($self, $geom) = @_;
    croak "Union method for class ".ref($self)." is not implemented yet";
}

=pod

=item Difference($geometry)

Returns a point set difference of this object with the other geometry.

=cut

sub Difference {
    my($self, $geom) = @_;
    croak "Difference method for class ".ref($self)." is not implemented yet";
}

=pod

=item SymDifference($geometry)

Returns a point set symmetric difference of this object with the other geometry.

=cut

sub SymDifference {
    my($self, $geom) = @_;
    croak "SymDifference method for class ".ref($self)." is not implemented yet";
}

=pod

=item MakeCollection()

Creates a collection which contains this geometry.

=cut

sub MakeCollection {
    my($self) = @_;
    croak "MakeCollection method for class ".ref($self)." is not implemented";
}

=pod

=item ApplyTransformation($transformation)

transf = A point transformation method which will be applied for all
the points in the geometry as:

    ($new_x, $new_y, $new_z) = $transformation->($x, $y, $z)

Not in the specification.

=cut

sub ApplyTransformation {
    my($self, $transf) = @_;
    croak "ApplyTransformation method for class ".ref($self)." is not implemented";
}

=pod

=back

=head2 Geo::OGC::SpatialReferenceSystem

=cut

package Geo::OGC::SpatialReferenceSystem;

use strict;
use Carp;

sub new {
    my($package, %params) = @_;
    my $self = {};
    bless $self => (ref($package) or $package);
}

=pod 

=head2 Geo::OGC::Point

A 0-dimensional geometric object.

=cut

package Geo::OGC::Point;

use strict;
use Carp;
use Geo::OGC::Geometry qw/:all/;

our @ISA = qw( Geo::OGC::Geometry );

=pod

=over

=item new()

A new point object can be created (besides using WKT) with

    $point = Geo::OGC::Point->new($x, $y);
    $point = Geo::OGC::Point->new($x, $y, $z);
    $point = Geo::OGC::Point->new(point => [$x, $y]);
    $point = Geo::OGC::Point->new(point => [$x, $y, $z]);
    $point = Geo::OGC::Point->new(point => [$x, $y, $z, $m]);
    $point = Geo::OGC::Point->new(pointz => [$x, $y, $z]);
    $point = Geo::OGC::Point->new(pointz => [$x, $y, $z, $m]);
    $point = Geo::OGC::Point->new(pointm => [$x, $y, $m]);
    $point = Geo::OGC::Point->new(pointm => [$x, $y, $z, $m]);
    $point = Geo::OGC::Point->new(pointzm => [$x, $y, $z, $m]);
    $point = Geo::OGC::Point->new(X => $x, Y => $y);
    $point = Geo::OGC::Point->new(X => $x, Y => $y, Z => $z);
    $point = Geo::OGC::Point->new(X => $x, Y => $y, Z => $z, M => $m);

=cut

sub new {
    my $package = shift;
    my %params;
    if (@_ == 2 and !($_[0] =~ /^[XYZMpP]/)) { # allow syntax Point->new($x, $y);
	$params{X} = shift;
	$params{Y} = shift;
    } elsif (@_ == 3) { # allow syntax Point->new($x, $y, $z);
	$params{X} = shift;
	$params{Y} = shift;
	$params{Z} = shift;
    } else {
	%params = @_;
    }
    # support comma as decimal point, and space in numbers
    for my $k (keys %params) {
	if (ref($params{$k})) {
	    for my $p (@{$params{$k}}) {
		$p =~ s/,/./g;
		$p =~ s/ //g;
		#print STDERR "point: $_\n";
	    }
	} else {
	    $params{$k} =~ s/,/./g;
	    $params{$k} =~ s/ //g;
	    #print STDERR "point: $_ => $params{$_}\n";
	}
    }
    my $self = Geo::OGC::Geometry::new($package, %params);
    return $self;
}

sub init {
    my($self, %params) = @_;
    $self->SUPER::init(%params);
    # +0 catches non-numeric error, if warnings are on
    if ($params{point}) {
	$self->{X} = $params{point}[0]+0;
	$self->{Y} = $params{point}[1]+0;
	$self->{Z} = $params{point}[2]+0 if @{$params{point}} > 2;
	$self->{M} = $params{point}[3]+0 if @{$params{point}} > 3;
    } elsif ($params{pointz}) {
	$self->{X} = $params{pointz}[0]+0;
	$self->{Y} = $params{pointz}[1]+0;
	$self->{Z} = $params{pointz}[2]+0;
	if (@{$params{pointz}} == 4) {
	    $self->{M} = $params{pointz}[3]+0;
	}
    } elsif ($params{pointm}) {
	$self->{X} = $params{pointm}[0]+0;
	$self->{Y} = $params{pointm}[1]+0;
	if (@{$params{pointm}} == 3) {
	    $self->{M} = $params{pointm}[2]+0;
	} elsif (@{$params{pointm}} == 4) {
	    $self->{Z} = $params{pointm}[2]+0;
	    $self->{M} = $params{pointm}[3]+0;
	}
    } elsif ($params{pointzm}) {
	$self->{X} = $params{pointm}[0]+0;
	$self->{Y} = $params{pointm}[1]+0;
	$self->{Z} = $params{pointm}[2]+0;
	$self->{M} = $params{pointm}[3]+0;
    } else {
	$self->{X} = $params{X}+0 if exists $params{X};
	$self->{Y} = $params{Y}+0 if exists $params{Y};
	$self->{Z} = $params{Z}+0 if exists $params{Z};
	$self->{M} = $params{M}+0 if exists $params{M};
    }
}

sub copy {
    my($self, $clone) = @_;
    $self->SUPER::copy($clone);
    for my $a (qw/X Y Z M/) {
	$clone->{$a} = $self->{$a} if exists $self->{$a};
    }
}

# Return a reference to an anonymous array that contains the point data.
# Note that there is no difference between [x,y,z] and [x,y,m]
sub point {
    my($self) = @_;
    my @point = ($self->{X}, $self->{Y});
    push @point, $self->{Z} if exists $self->{Z};
    push @point, $self->{M} if exists $self->{M};
    return [@point];
}

sub GeometryType {
    return 'Point';
}

sub Dimension {
    return 0;
}

sub Clone {
    my($self) = @_;
    my $m = exists $self->{M} ? 'm' : '';
    return Geo::OGC::Point::new($self, "point$m" => $self->point);
}

sub IsEmpty {
    my($self) = @_;
    return !(exists $self->{X});
}

# A point is always simple.
sub IsSimple {
    my($self) = @_;
    return 1;
}

sub Is3D {
    my($self) = @_;
    return exists $self->{Z};
}

sub IsMeasured {
    my($self) = @_;
    return exists $self->{M};
}

sub Boundary {
    my($self) = @_;
    return $self->Clone;
}

sub X {
    my($self, $X) = @_;
    defined $X ? 
	$self->{X} = $X : $self->{X};
}

sub Y {
    my($self, $Y) = @_;
    defined $Y ? 
	$self->{Y} = $Y : $self->{Y};
}

=pod

=item Z()

Get or set the z coordinate.

Setting is not in the specification.

=cut

sub Z {
    my($self, $Z) = @_;
    defined $Z ? 
	$self->{Z} = $Z : (exists $self->{Z} ? $self->{Z} : undef);
}

=pod

=item M()

Get or set the measure.

Setting is not in the specification.

=cut

sub M {
    my($self, $M) = @_;
    defined $M ? 
	$self->{M} = $M : (exists $self->{M} ? $self->{M} : undef);
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my @coords;
    my $ZM = exists $self->{Z} ? 'Z' : '';
    if (exists $self->{Precision}) {
	for my $a (qw/X Y Z/) {
	    last unless exists $self->{$a};
	    my $s = sprintf('%.'.$self->{Precision}.'e', $self->{$a});
	    push @coords, $s;
	}
    } else {
	for my $a (qw/X Y Z/) {
	    push @coords, $self->{$a} if exists $self->{$a};
	}
    }
    if (exists $self->{M}) {
	push @coords, $self->{M};
	$ZM .= 'M';
    }
    my $text = join(' ', @coords);
    $text =~ s/,/./g; # setting POSIX numeric locale does not seem to work??
    $text = '('.$text.')' if $force_parens;
    $text = "POINT$ZM ".$text if $include_tag;
    return $text;
}

# what should we do with z?
sub Equals {
    my($self, $geom) = @_;
    return 0 unless $geom->isa('Geo::OGC::Point');
    if (exists $self->{Precision}) {
	for my $a (qw/X Y Z/) {
	    last unless exists $self->{$a} and exists $geom->{$a};
	    my $s = sprintf('%.'.$self->{Precision}.'e', $self->{$a});
	    my $g = sprintf('%.'.$self->{Precision}.'e', $geom->{$a});
	    return 0 if $s != $g;
	}
	return 1;
    }
    return (($self->{X}-$geom->{X})**2+($self->{Y}-$geom->{Y})**2) < $SNAP_DISTANCE_SQR;
}

sub DistanceToLineStringSqr {
    my($self, $linestring) = @_;
    my($x, $y) = ($self->{X}, $self->{Y});
    my $p1 = $linestring->{Points}[0];
    return unless $p1;
    my $p2 = $linestring->{Points}[1];
    return (($x-$p1->{X})**2+($y-$p1->{Y})**2) unless $p2;
    my $distance = distance_point_line_sqr($x, $y, $p1->{X}, $p1->{Y}, $p2->{X}, $p2->{Y});
    for my $i (2..$#{$linestring->{Points}}) {
	$p1 = $p2;
	$p2 = $linestring->{Points}[$i];
	my $d = distance_point_line_sqr($x, $y, $p1->{X}, $p1->{Y}, $p2->{X}, $p2->{Y});
	$distance = $d if $d < $distance;
    }
    return $distance;
}

sub Distance {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	return sqrt(($self->{X}-$geom->{X})**2 + ($self->{Y}-$geom->{Y})**2);
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	return sqrt($self->DistanceToLineStringSqr($geom));
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	if ($geom->{ExteriorRing}->IsPointIn($self)) {
	    for my $ring (@{$geom->{InteriorRings}}) {
		return sqrt($self->DistanceToLineStringSqr($ring)) if $ring->IsPointIn($self);
	    }
	    return 0;
	} else {
	    return sqrt($self->DistanceToLineStringSqr($geom->{ExteriorRing}));
	}
    } elsif ($geom->isa('Geo::OGC::GeometryCollection')) {
	my $dist = $self->Distance($geom->{Geometries}[0]);
	for my $g (@{$geom->{Geometries}}[1..$#{$geom->{Geometries}}]) {
	    my $d = $self->Distance($g);
	    $dist = $d if $d < $dist;
	}
	return $dist;
    } else {
	croak "can't compute distance between a ".ref($geom)." and a point";
    }
}

# what should this be?
sub Envelope {
    my($self) = @_;
    my $r = Geo::OGC::LinearRing->new;
    $r->AddPoint(Geo::OGC::Point->new($self->{X}, $self->{Y}));
    $r->AddPoint(Geo::OGC::Point->new($self->{X}, $self->{Y}));
    $r->AddPoint(Geo::OGC::Point->new($self->{X}, $self->{Y}));
    $r->AddPoint(Geo::OGC::Point->new($self->{X}, $self->{Y}));
    $r->Close;
    return $r;
}

sub Area {
    return 0;
}

sub Intersection {
    my($self, $geom) = @_;
    return $self->Clone if $self->Within($geom);
    return undef;
}

sub Within {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	return $self->Equals($geom) ? 1 : 0;
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	return $self->DistanceToLineStringSqr($geom) < $SNAP_DISTANCE_SQR ? 1 : 0;
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	if (!($geom->{ExteriorRing}->IsPointStricktlyOut($self))) {
	    for my $ring (@{$geom->{InteriorRing}}) {
		return 0 if $ring->IsPointStricktlyIn($self);
	    }
	    return 1;
	}
	return 0;
    } elsif ($geom->isa('Geo::OGC::GeometryCollection')) {
	for my $g (@{$geom->{Geometries}}) {
	    return 1 if $self->Within($g);
	}
	return 0;
    } else {
	croak "point within ".ref($geom)." is not implemented yet";
    }
}

sub MakeCollection {
    my($self) = @_;
    my $coll = Geo::OGC::MultiPoint->new;
    $coll->AddGeometry($self);
    return $coll;
}

sub ApplyTransformation {
    my($self, $transf) = @_;
    if (@_ > 2) {
	($self->{X}, $self->{Y}, $self->{Z}) = $transf->($self->{X}, $self->{Y}, $self->{Z});
    } else {
	($self->{X}, $self->{Y}) = $transf->($self->{X}, $self->{Y});
    }
}

sub ClosestVertex {
    my($self, $x, $y) = @_;
    return (($self->{X}-$x)**2 + ($self->{Y}-$y)**2);
}

sub VertexAt {
    my $self = shift;
    return ($self);
}

sub ClosestPoint {
    my($self, $x, $y) = @_;
    return (($self->{X}-$x)**2 + ($self->{Y}-$y)**2);
}

sub AddVertex {
}

sub DeleteVertex {
}

=pod 

=back

=head2 Geo::OGC::Curve

A 1-dimensional geometric object.

=cut

package Geo::OGC::Curve;

use strict;
use Carp;
use Geo::OGC::Geometry qw/:all/;

our @ISA = qw( Geo::OGC::Geometry );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Geometry::new($package, %params);
    return $self;
}

sub init {
    my($self, %params) = @_;
    $self->SUPER::init(%params);
    $self->{Points} = [];
    if ($params{points}) {
	for my $p (@{$params{points}}) {
	    $self->AddPoint(Geo::OGC::Point->new(point=>$p));
	}
    } elsif ($params{pointsm}) {
	for my $p (@{$params{pointsm}}) {
	    $self->AddPoint(Geo::OGC::Point->new(pointm=>$p));
	}
    }
}

sub copy {
    my($self, $clone) = @_;
    $self->SUPER::copy($clone);
    for my $p (@{$self->{Points}}) {
	$clone->AddPoint($p->Clone);
    }
}

sub IsEmpty {
    my($self) = @_;
    return 1 if !$self->{Points} or @{$self->{Points}} == 0;
    return 0;
}

sub GeometryType {
    return 'Curve';
}

sub Dimension {
    return 1;
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my $text = join(',', map {$_->as_text} @{$self->{Points}});
    $text = '('.$text.')';
    my $ZM = $self->Is3D ? 'Z' : '';
    $ZM .= 'M' if $self->IsMeasured;
    $text = uc($self->GeometryType).$ZM.' '.$text if $include_tag;
    return $text;
}

=pod

=over

=item AddPoint($point, $i)

Adds a point to the end (N+1) of the curve by default.

point = A Point object
i [optional] = The location in the sequence (1..N+1) where to add the Point. 

Not in the specification.

=cut

sub AddPoint {
    my($self, $point, $i) = @_;
    croak 'usage: Curve->AddPoint($point) '
	unless $point and $point->isa('Geo::OGC::Point');
    my $points = $self->{Points};
    if (defined $i) {
	my $temp = $points->[$i-1];
	splice @$points, $i-1, 1, ($point, $temp);
    } else {
	push @$points, $point;
    }
}

=pod

=item DeletePoint($i)

Delete a point from the curve.

i = The location in the sequence (1..N) from where to delete the Point.

Not in the specification.

=cut

sub DeletePoint {
    my($self, $i) = @_;
    my $points = $self->{Points};
    splice @$points, $i-1, 1;
}

sub StartPoint {
    my($self) = @_;
    my $points = $self->{Points};
    return $points->[0] if @$points;
}

sub EndPoint {
    my($self) = @_;
    my $points = $self->{Points};
    return $points->[$#$points] if @$points;
}

=pod

=item NumPoints()

Return the number of points in the sequence.

=cut

sub NumPoints {
    my($self) = @_;
    scalar(@{$self->{Points}});
}

=pod

=item PointN($N, $point)

Get or set the point of the sequence.

N = A location in the sequence.
point [optional] = A Point object, if defined sets the point to index N.

The first point has the index 1 as OGC SF SQL conformance test uses 1-based indexing. 

=cut

sub PointN {
    my($self, $N, $point) = @_;
    my $points = $self->{Points};
    $points->[$N-1] = $point if defined $point;
    return $points->[$N-1];
}

sub Is3D {
    my($self) = @_;
    for my $p (@{$self->{Points}}) {
	return 1 if $p->Is3D;
    }
    return 0;
}

sub IsMeasured {
    my($self) = @_;
    for my $p (@{$self->{Points}}) {
	return 1 if $p->IsMeasured;
    }
    return 0;
}

sub IsClosed {
    my($self) = @_;
    $self->StartPoint()->Equals($self->EndPoint());
}

=pod

=item Close()

Close the curve by adding the first point also as the last point.

Not in the specification.

=cut

sub Close {
    my($self) = @_;
    push @{$self->{Points}}, $self->{Points}[0];
}

=pod

=item IsRing($upgrade)

Tests whether this curve is a ring, i.e., closed and simple.

upgrade [optional, not in the specification] = Upgrades this curve into a Ring if this really could be a ring.

=cut

sub IsRing {
    my($self, $upgrade) = @_;
    my $ret = ($self->IsClosed and $self->IsSimple);
    bless($self, 'Geo::OGC::LinearRing') if $ret and $upgrade;
    return $ret;
}

# should use Precision if one exists
sub Equals {
    my($self, $geom) = @_;
    return 0 unless $geom->isa('Geo::OGC::Curve');
    return 0 unless $#{$self->{Points}} == $#{$geom->{Points}};
    for my $i (0..$#{$self->{Points}}) {
	return 0 unless $self->{Points}[$i]->Equals($geom->{Points}[$i]);
    }
    return 1;
}

sub Area {
    return 0;
}

sub MakeCollection {
    my($self) = @_;
    my $coll = Geo::OGC::MultiCurve->new;
    $coll->AddGeometry($self);
    return $coll;
}

sub ApplyTransformation {
    my($self, $transf) = @_;
    for my $p (@{$self->{Points}}) {
	$p->ApplyTransformation($transf);
    }
}

=pod

=item Reverse()

Reverse the order of the points in the sequence.

Not in the specification.

=cut

sub Reverse {
    my($self) = @_;
    @{$self->{Points}} = reverse @{$self->{Points}};
}

sub ClosestVertex {
    my($self, $x, $y) = @_;
    return unless @{$self->{Points}};
    my($dmin) = $self->{Points}[0]->ClosestVertex($x, $y);
    my $i = 0;
    for my $j (1..$#{$self->{Points}}) {
	my($d) = $self->{Points}[$j]->ClosestVertex($x, $y);
	($i, $dmin) = ($j, $d) if $d < $dmin;
    }
    return ($i, $dmin);
}

sub VertexAt {
    my($self, $i) = @_;
    return ($self->{Points}[0], $self->{Points}[$#{$self->{Points}}])
	if (($i == 0 or $i == $#{$self->{Points}}) and $self->isa('Geo::OGC::LinearRing'));
    return ($self->{Points}[$i]);
}

sub _closest_point {
    my($x0, $y0, $x1, $y1, $x, $y) = @_;
    my $ab2 = ($x1-$x0)*($x1-$x0) + ($y1-$y0)*($y1-$y0);
    my $ap_ab = ($x-$x0)*($x1-$x0) + ($y-$y0)*($y1-$y0);
    my $t = $ap_ab/$ab2;
    if ($t < 0) {$t = 0} elsif ($t > 1) {$t = 1}
    my $xp = $x0+$t*($x1-$x0);
    my $yp = $y0+$t*($y1-$y0);
    return ($xp, $yp, ($x-$xp)*($x-$xp)+($y-$yp)*($y-$yp));
}

sub ClosestPoint {
    my($self, $x, $y) = @_;
    return unless @{$self->{Points}};
    my($i, $pmin, $dmin);
    for my $j (1..$#{$self->{Points}}) {
	my($xp, $yp, $d) = 
	    _closest_point($self->{Points}[$j-1]{X}, $self->{Points}[$j-1]{Y}, 
			   $self->{Points}[$j]{X}, $self->{Points}[$j]{Y}, $x, $y);
	($i, $pmin, $dmin) = ($j, Geo::OGC::Point->new($xp, $yp), $d) 
	    if (!defined($dmin) or $d  < $dmin);
    }
    return ($i, $pmin, $dmin)
}

sub AddVertex {
    my($self, $i, $p) = @_;
    splice @{$self->{Points}}, $i, 0, $p;
}

sub DeleteVertex {
    my($self, $i) = @_;
    splice @{$self->{Points}}, $i, 1;
}

=pod

=back

=head2 Geo::OGC::LineString

=cut

package Geo::OGC::LineString;

use strict;
use Carp;
use Geo::OGC::Geometry qw/:all/;

our @ISA = qw( Geo::OGC::Curve );

# de Berg et al p. 25
sub FindIntersections {
    # @_ contains a list of linestrings that make up the S
    my @linestrings = @_;
    #my $precision = 

    # event queue
    my @Q = (); # [ymax,index1,index2], ..., index1 is index to @_ index2 is index to Points
    for my $index1 (0 .. $#linestrings) {
	my $s = $linestrings[$index1]->{Points};
	for my $index2 (0 .. $#$s-1) {
	    my($y1, $y2) = ( $s->[$index2]{Y}, $s->[$index2+1]{Y} );
	    if ($y1 > $y2) {
		push @Q, [$y1, $index1, $index2];
		push @Q, [$y2];
	    } else {
		push @Q, [$y2, $index1, $index2];
		push @Q, [$y1];
	    }
	}
    }
    
    # process event points in descending ymax order
    @Q = sort {$b->[0] <=> $a->[0]} @Q;
    
    my $T = Tree::Binary::Search->new(); # the status structure
    $T->setComparisonFunction
	(sub {
	    my($a, $b) = @_; # two keys
	    
	});
    
    my $i = 0;
    while ($i < @Q) {
	my $j = $i+1;
	while ($j < @Q and sqrt(($Q[$i][0]-$Q[$j][0])**2) < $SNAP_DISTANCE_SQR) {
	    $j++;
	}
	# $i .. $j-1 are the event points in @Q
	for my $k ($i .. $j-1) {
	    if (@{$Q[$k]} == 3) {
		my $i1 = $Q[$k][1];
		my $i2 = $Q[$k][2];
		my $s = $linestrings[$i1]->{Points};
		$T->insert( "$i1,$i2" => [$s->[$i2]{X}, $s->[$i2]{Y}, $s->[$i2+1]{X}, $s->[$i2+1]{Y}] );
	    }
	}
    }
}

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Curve::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'LineString';
}

sub IsSimple {
    my($self) = @_;
    my $edges = @{$self->{Points}} - 1;
    return 1 if $edges < 2;
    my $closed = $self->IsClosed;
    my $simple = 1;
    for my $i (0..$edges-1) {
	# check a case of self tangency
	return 0 if $i < $edges-1 and $self->{Points}[$i+2]->Equals($self->{Points}[$i]);
	for my $j ($i+2..$edges-1) {
	    next if $closed and $i == 0 and $j == $edges-1;
	    return 0 if intersect
		(
		 $self->{Points}[$i]{X}, $self->{Points}[$i]{Y},
		 $self->{Points}[$i+1]{X}, $self->{Points}[$i+1]{Y},
		 $self->{Points}[$j]{X}, $self->{Points}[$j]{Y},
		 $self->{Points}[$j+1]{X},$self->{Points}[$j+1]{Y}
		 );
	}
    }
    return 1;
}

sub Envelope {
    my($self) = @_;
    my($minx, $miny, $maxx, $maxy);
    for my $p (@{$self->{Points}}) {
	$minx = $p->{X} if !defined($minx) or $minx > $p->{X};
	$miny = $p->{Y} if !defined($miny) or $miny > $p->{Y};
	$maxx = $p->{X} if !defined($maxx) or $maxx > $p->{X};
	$maxy = $p->{Y} if !defined($maxy) or $maxy > $p->{Y};
    }
    my $r = Geo::OGC::LinearRing->new;
    $r->AddPoint(Geo::OGC::Point->new($minx, $miny));
    $r->AddPoint(Geo::OGC::Point->new($maxx, $miny));
    $r->AddPoint(Geo::OGC::Point->new($maxx, $maxy));
    $r->AddPoint(Geo::OGC::Point->new($minx, $maxy));
    $r->Close;
    return $r;
}

=pod

=over

=item Length()

The length of this LineString in its associated spatial reference.

Currently computed as a simple euclidean distance.

=cut

sub Length {
    my($self) = @_;
    my $l = 0;
    my($x0, $y0) = ($self->{Points}[0]{X}, $self->{Points}[0]{Y});
    for my $i (1..$#{$self->{Points}}) {
	my($x1, $y1) = ($self->{Points}[$i]{X}, $self->{Points}[$i]{Y});
	$l += sqrt(($x1 - $x0)**2+($y1 - $y0)**2);
	($x0, $y0) = ($x1, $y1);
    }
    return $l;
}

sub Distance {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	return $geom->DistanceToLineStringSqr($self);
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	my $dist;
	for my $p (@{$self->{Points}}) {
	    my $d = $p->DistanceToLineStringSqr($geom);
	    $dist = $d if !(defined $dist) or $d < $dist;
	}
	return $dist;
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	my $dist;
	for my $p (@{$self->{Points}}) {
	    my $d = $p->Distance($geom);
	    $dist = $d if !(defined $dist) or $d < $dist;
	}
	return $dist;
    } elsif ($geom->isa('Geo::OGC::GeometryCollection')) {
	my $dist = $self->Distance($geom->{Geometries}[0]);
	for my $g (@{$geom->{Geometries}}[1..$#{$geom->{Geometries}}]) {
	    my $d = $self->Distance($g);
	    $dist = $d if $d < $dist;
	}
	return $dist;
    } else {
	croak "can't compute distance between a ".ref($geom)." and a line string";
    }
}

sub LinesWhereWithin {
    my($self, $point) = @_;
    my($x, $y) = ($point->{X}, $point->{Y});
    my @ret;
    my $p1 = $self->{Points}[0];
    return @ret unless $p1;
    my $p2 = $self->{Points}[1];
    return @ret unless $p1;
    push @ret, 1 if 
	distance_point_line_sqr($x, $y, $p1->{X}, $p1->{Y}, $p2->{X}, $p2->{Y}) < $SNAP_DISTANCE_SQR;
    for my $i (2..$#{$self->{Points}}) {
	$p1 = $p2;
	$p2 = $self->{Points}[$i];
	push @ret, $i if
	    distance_point_line_sqr($x, $y, $p1->{X}, $p1->{Y}, $p2->{X}, $p2->{Y}) < $SNAP_DISTANCE_SQR;
    }
    return @ret;
}

sub Within {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	for my $p (@{$self->{Points}}) {
	    return 0 unless $p->Equals($geom);
	}
	return 1;
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	my @w1 = ();
	for my $p (@{$self->{Points}}) {
	    my @w2 = $geom->LinesWhereWithin($p);
	    return 0 unless @w2;
	    next unless @w1;
	    my $overlap = 0;
	    for my $w1 (@w1) {
		for my $w2 (@w2) {
		    $overlap = 1 if $w1 == $w2;
		}
	    }
	    return 0 unless $overlap;
	    @w1 = @w2;
	}
	return 1;
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	for my $p (@{$self->{Points}}) {
	    return 0 if $geom->{ExteriorRing}->IsPointStricktlyOut($p);
	    for my $ring (@{$geom->{InteriorRings}}) {
		return 0 if $ring->IsPointStricktlyIn($p);
	    }
	}
	my $i = $self->Intersection($geom->{ExteriorRing});
	for my $g (@{$i->{Geometries}}) {
	    next unless $g->isa('Geo::OGC::Line');
	    # does the line go out of the polygon?
	    # yes, if its start and end points are on different lines
	    my @s = $geom->{ExteriorRing}->LinesWhereWithin($g->StartPoint);
	    my @e = $geom->{ExteriorRing}->LinesWhereWithin($g->EndPoint);
	    my $overlap = 0;
	    for my $s (@s) {
		for my $e (@e) {
		    $overlap = 1 if $s == $e;
		}
	    }
	    return 0 unless $overlap;
	}
	for my $ring (@{$geom->{InteriorRings}}) {
	    my $i = $self->Intersection($ring);
	    for my $g (@{$i->{Geometries}}) {
		next unless $g->isa('Geo::OGC::Line');
		# does the line go into the interior ring?
		# yes, if its start and end points are on different lines
		my @s = $ring->LinesWhereWithin($g->StartPoint);
		my @e = $ring->LinesWhereWithin($g->EndPoint);
		my $overlap = 0;
		for my $s (@s) {
		    for my $e (@e) {
			$overlap = 1 if $s == $e;
		    }
		}
		return 0 unless $overlap;
	    }
	}
	return 1;
    } else {
	croak "linestring within ".ref($geom)." is not yet implemented";
    }
}

# assuming simple lines
# z and m coords!
sub Intersection {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	return $geom->Clone if $geom->DistanceToLineStringSqr($self) < $SNAP_DISTANCE_SQR;
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	#my $i = Geo::OGC::GeometryCollection->new;
	my %i;
	my $index = 1;
	my $p1;
	for my $p2 (@{$self->{Points}}) {
	    $p1 = $p2, next unless $p1;
	    my $q1;
	    for my $q2 (@{$geom->{Points}}) {
		$q1 = $q2, next unless $q1;
		my @p = ($p1->{X}, $p1->{Y}, $p2->{X}, $p2->{Y});
		my @q = ($q1->{X}, $q1->{Y}, $q2->{X}, $q2->{Y});
		#print STDERR "lines: @p; @q\n";
		if (intersect( @p, @q )) {
		    my $p1q = distance_point_line_sqr(@p[0..1], @q);
		    my $p2q = distance_point_line_sqr(@p[2..3], @q);
		    my $q1p = distance_point_line_sqr(@q[0..1], @p);
		    my $q2p = distance_point_line_sqr(@q[2..3], @p);
		    #print STDERR "p1=q $p1q p2=q $p2q q1=p $q1p q2=p $q2p\n";
		    if ($p1q < $SNAP_DISTANCE_SQR) {
			if ($q1p < $SNAP_DISTANCE_SQR) {
			    if ($p1->Equals($q1)) {
				$i{$index++} = $p1->Clone;
			    } else {
				$i{$index++} = Geo::OGC::Line->new( points=>[[@p[0..1]],[@q[0..1]]] );
			    }
			} 
			if ($q2p < $SNAP_DISTANCE_SQR) {
			    if ($p1->Equals($q2)) {
				$i{$index++} = $p1->Clone;
			    } else {
				$i{$index++} = Geo::OGC::Line->new( points=>[[@p[0..1]],[@q[2..3]]] );
			    }
			} 
			if ($p2q < $SNAP_DISTANCE_SQR) {
			    $i{$index++} = Geo::OGC::Line->new( points=>[[@p[0..1]],[@p[2..3]]] );
			} else {
			    $i{$index++} = Geo::OGC::Point->new( @p[0..1] );
			}
		    } elsif ($p2q < $SNAP_DISTANCE_SQR) {
			if ($q1p < $SNAP_DISTANCE_SQR) {
			    if ($p2->Equals($q1)) {
				$i{$index++} = $p2->Clone;
			    } else {
				$i{$index++} = Geo::OGC::Line->new( points=>[[@p[2..3]],[@q[0..1]]] );
			    }
			} 
			if ($q2p < $SNAP_DISTANCE_SQR) {
			    if ($p2->Equals($q2)) {
				$i{$index++} = $p2->Clone;
			    } else {
				$i{$index++} = Geo::OGC::Line->new( points=>[[@p[2..3]],[@q[2..3]]] );
			    }
			}
			$i{$index++} = Geo::OGC::Point->new( @p[2..3] );
		    } elsif ($q1p < $SNAP_DISTANCE_SQR) {
			if ($q2p < $SNAP_DISTANCE_SQR) {
			    $i{$index++} = Geo::OGC::Line->new( points=>[[@q[0..1]],[@q[2..3]]] );
			} else {
			    $i{$index++} = Geo::OGC::Point->new( @q[0..1] );
			}
		    } elsif ($q2p < $SNAP_DISTANCE_SQR) {
			$i{$index++} = Geo::OGC::Point->new( @q[2..3] );
		    } else {
			$i{$index++} = Geo::OGC::Point->new( Geo::OGC::Geometry::intersection_point(@p, @q) );
		    }
		}
		$q1 = $q2;
	    }
	    $p1 = $p2;
	}
	#$i->Simplify;
	
	# delete unnecessary points and lines
	# comparisons are done unnecessarily twice??
	for my $g1 (keys %i) {
	    for my $g2 (keys %i) {
		next if $g1 == $g2;
		if ($i{$g1}->Within($i{$g2})) {
		    #print STDERR "delete ",$i{$g1}->AsText," because it is in ",$i{$g2}->AsText,"\n";
		    delete $i{$g1};
		    last;
		}
	    }
	}

	my $i = Geo::OGC::GeometryCollection->new;
	for my $g1 (keys %i) {
	    $i->AddGeometry($i{$g1});
	}
	return $i;
    } else {
	croak "intersection between a ".ref($geom)." and a line string is not yet implemented";
    }
}

sub MakeCollection {
    my($self) = @_;
    my $coll = Geo::OGC::MultiLineString->new;
    $coll->AddGeometry($self);
    return $coll;
}

# from http://everything2.com/index.pl?node_id=859282
sub pt_to_seg_dist {
    # distance of p to segment p1-p2, v12 is the vector p1p2
    my ($p1, $v12, $p) = @_;

    my $m12 = $v12->[0] * $v12->[0] + $v12->[1] * $v12->[1];
    my $v1p = [];
    $v1p->[0] = $p->{X} - $p1->{X};
    $v1p->[1] = $p->{Y} - $p1->{Y};
    my $dot = $v1p->[0] * $v12->[0] + $v1p->[1] * $v12->[1];
    if ($dot <= 0.0) 
    {
	return sqrt ($v1p->[0] * $v1p->[0] + $v1p->[1] * $v1p->[1]);
    } 
    else 
    {
	if ($dot >= $m12)
	{
	    $v1p->[0] = $v1p->[0] + $v12->[0];
	    $v1p->[1] = $v1p->[1] + $v12->[1];
	    return sqrt ($v1p->[0] * $v1p->[0] + $v1p->[1] * $v1p->[1]);
	}
	else
	{
	    my $slash = $v1p->[0] * $v12->[1] - $v1p->[1] * $v12->[0];
	    return abs ($slash / sqrt ($m12));
	}
    }
}

sub simplify_part {
    my($self, $first, $last, $simple, $tolerance) = @_;
    if ($last > $first + 1)
    {
	my $p1 = $self->{Points}[$first];
	my $vfl = [$self->{Points}[$last]{X} - $self->{Points}[$first]{X},
		   $self->{Points}[$last]{Y} - $self->{Points}[$first]{Y}];
	# find the intermediate point
	# furthest from the segment
	# connecting first and last
	my $b = $first+1;
	my $db = pt_to_seg_dist ($p1, $vfl, $self->{Points}[$b]);
	my $i = $b + 1;
	while ($i < $last) 
	{
	    my $di = pt_to_seg_dist ($p1, $vfl, $self->{Points}[$i]);
	    if ($di > $db)
	    {
		$b = $i;
		$db = $di;
	    }
	    $i++;
	}
	# if the furthest distance beats the tolerance,
	# recursively simplify the rest of the array.
	if ($db >= $tolerance)
	{
	    simplify_part ($self, $first, $b, $simple, $tolerance);
	    $simple->AddPoint($self->{Points}[$b]);
	    simplify_part ($self, $b, $last, $simple, $tolerance);
	}
    }
}

# Simplifies the linestring using Douglas-Peucker
sub simplify {
    my($self, $tolerance) = @_;
    my $simple = Geo::OGC::LineString->new;
    $simple->AddPoint($self->StartPoint);
    simplify_part ($self, 0, $self->NumPoints-1, $simple, $tolerance);
    $simple->AddPoint($self->EndPoint);
    return $simple;
}

=pod

=back

=head2 Geo::OGC::Line

=cut

package Geo::OGC::Line;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::LineString );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::LineString::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'Line';
}

=pod

=head2 Geo::OGC::LinearRing

=cut

package Geo::OGC::LinearRing;

use strict;
use Carp;
use Geo::OGC::Geometry qw/:all/;

our @ISA = qw( Geo::OGC::LineString );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::LineString::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'LinearRing';
}

=pod

=over

=item IsPointIn($point)

Tests whether the given point is within the ring.

Uses the pnpoly algorithm from L<http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html>.

Assumes a simple closed ring. May or may not return true if the point is on the border.

Not in the specification.

=cut

sub IsPointIn {
    my($self, $point) = @_;
    my($x, $y) = ($point->{X}, $point->{Y});
    my $c = 0;
    my $prev;
    for my $p (@{$self->{Points}}) {
	$prev = $p, next unless $prev;
	$c = !$c if (((( $p->{Y} <= $y ) && ( $y < $prev->{Y} )) ||
		      (( $prev->{Y} <= $y ) && ( $y < $p->{Y} ))) &&
		     ( $x < ( $prev->{X} - $p->{X} ) * 
		       ( $y - $p->{Y} ) / ( $prev->{Y} - $p->{Y} ) + $p->{X} ));
	$prev = $p;
    }
    return $c;
}

# @note not on the border
sub IsPointStricktlyIn {
    my($self, $point) = @_;
    return 1 if ( $self->IsPointIn($point) and 
		  !($point->DistanceToLineStringSqr($self) < $SNAP_DISTANCE_SQR) );
    return 0;
}

# @note not on the border
sub IsPointStricktlyOut {
    my($self, $point) = @_;
    return 1 unless ( $self->IsPointIn($point) or 
		      $point->DistanceToLineStringSqr($self) < $SNAP_DISTANCE_SQR );
    return 0;
}

=pod

=item Area()

Compute the area of the ring. The area is computed as a simple euclidean area.

Not in the specification.

Assumes a simple closed ring

Returns the area as a negative number if the sense of the rotation of the ring is clockwise.

=cut

sub Area {
    my($self) = @_;
    my $area = 0;
    my $N = $#{$self->{Points}}-1; # skip the closing point
    my $j = 0;
    for my $i (0..$N) {
	$j++;
	$area += $self->{Points}[$i]{X} * $self->{Points}[$j]{Y};
	$area -= $self->{Points}[$i]{Y} * $self->{Points}[$j]{X};
    }
    return $area/2;
}

sub Centroid {
    my($self) = @_;
    my($area, $x, $y) = (0, 0, 0);
    my $N = $#{$self->{Points}}-1; # skip the closing point
    for my $i (0..$N) {
	my($xi, $yi, $xj, $yj) = ( $self->{Points}[$i]{X}, $self->{Points}[$i]{Y},
				   $self->{Points}[$i+1]{X}, $self->{Points}[$i+1]{Y} );
	my $b = $xi * $yj - $xj * $yi;
	$area += $b;
	$x += ($xi + $xj) * $b;
	$y += ($yi + $yj) * $b;
    }
    $x /= abs(3*$area); # 6 but $area is 2 * real area
    $y /= abs(3*$area);
    return Geo::OGC::Point->new($x, $y);
}

# Returns true if the points in this ring are arranged counterclockwise. Assumes a simple closed ring.
sub IsCCW {
    my($self) = @_;
    # find the northernmost point
    my $t = 0;
    my $N = $#{$self->{Points}}-1; # skip the closing point
    for my $i (1..$N) {
	$t = $i if $self->{Points}[$i]{Y} > $self->{Points}[$t]{Y};
    }
    # the previous point
    my $p = $t-1;
    $p = $N if $p < 0;
    # the next point
    my $n = $t+1;
    $n = 0 if $n > $N;
    return ccw($self->{Points}[$p]{X}, $self->{Points}[$p]{Y}, 
	       $self->{Points}[$t]{X}, $self->{Points}[$t]{Y}, 
	       $self->{Points}[$n]{X}, $self->{Points}[$n]{Y}) == 1;
}

# Makes clockwise from counterclockwise and vice versa.
sub Rotate {
    my($self) = @_;
    @{$self->{Points}} = reverse @{$self->{Points}};
}

=pod

=back

=head2 Geo::OGC::Surface

A 2-dimensional geometric object.

=cut

package Geo::OGC::Surface;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::Geometry );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Geometry::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'Surface';
}

sub Dimension {
    return 2;
}

sub Area {
    my($self) = @_;
    croak "Area method for class ".ref($self)." is not implemented yet";
}

sub Centroid {
    my($self) = @_;
    croak "Centroid method for class ".ref($self)." is not implemented yet";
}

sub PointOnSurface {
    my($self) = @_;
    croak "PointOnSurface method for class ".ref($self)." is not implemented yet";
}

sub MakeCollection {
    my($self) = @_;
    my $coll = Geo::OGC::MultiSurface->new;
    $coll->AddGeometry($self);
    return $coll;
}

=pod

=head2 Geo::OGC::Polygon

=cut

package Geo::OGC::Polygon;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::Surface );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Surface::new($package, %params);
    return $self;
}

sub init {
    my($self, %params) = @_;
    $self->SUPER::init(%params);
    $self->{ExteriorRing} = undef;
    $self->{InteriorRings} = [];
}

sub copy {
    my($self, $clone) = @_;
    $self->SUPER::copy($clone);
    $clone->ExteriorRing($self->{ExteriorRing}->Clone) if $self->{ExteriorRing};
    for my $r (@{$self->{InteriorRings}}) {
	$clone->AddInteriorRing($r->Clone);
    }
}

sub IsEmpty {
    my($self) = @_;
    return 1 unless $self->{ExteriorRing};
    return undef;
}

sub GeometryType {
    return 'Polygon';
}

# Test the rules that define valid polygons.
sub Assert {
    my($self) = @_;

    # a) Polygons are topologically closed;
    croak "not at least triangle" unless @{$self->{ExteriorRing}->{Points}} > 3;
    croak "exterior not closed" unless $self->{ExteriorRing}->IsClosed;

    # b) The boundary of a Polygon consists of a set of LinearRings
    # that make up its exterior and interior boundaries;
    for my $r (@{$self->{InteriorRings}}) {
	croak "an interior is not closed" unless $r->IsClosed;
    }

    # c) No two Rings in the boundary cross and the Rings in the
    # boundary of a Polygon may intersect at a Point but only as a
    # tangent
    for my $ring (@{$self->{InteriorRings}}) {
	for my $p (@{$ring->{Points}}) {
	    croak "point in interior not within exterior" unless $self->{ExteriorRing}->IsPointIn($p);
	    for my $r2 (@{$self->{InteriorRings}}) {
		next if $ring == $r2;
		croak "point in interior is within another interior" if $r2->IsPointIn($p);
	    }
	}
    }

    # d) A Polygon may not have cut lines, spikes or punctures
    croak "exterior is not simple" unless $self->{ExteriorRing}->IsSimple;
    for my $r (@{$self->{InteriorRings}}) {
	croak "an interior is not simple" unless $r->IsSimple;
    }

    # e) The interior of every Polygon is a connected point set

    # f) The exterior of a Polygon with 1 or more holes is not
    # connected. Each hole defines a connected component of the
    # exterior.
    
    for my $i (0..$#{$self->{InteriorRings}}) {
	my $r1 = $self->{InteriorRings}[$i];
	my $r2 = $r1->Intersection($self->{ExteriorRing});
	croak "an interior intersects too much with the exterior"
	    if @{$r2->{Geometries}} and (@{$r2->{Geometries}} > 1 or 
					 !$r2->{Geometries}[0]->isa('Geo::OGC::Point'));
	for my $j ($i+1..$#{$self->{InteriorRings}}) {
	    my $r2 = $self->{InteriorRings}[$j];
	    $r2 = $r1->Intersection($r2);
	    croak "an interior intersects too much with another interior"
		if @{$r2->{Geometries}} and (@{$r2->{Geometries}} > 1 or 
					     !$r2->{Geometries}[0]->isa('Geo::OGC::Point'));
	}
    }
    
    return 1;

}

sub Is3D {
    my($self) = @_;
    return 1 if $self->{ExteriorRing}->Is3D;
    for my $r (@{$self->{InteriorRings}}) {
	return 1 if $r->Is3D;
    }
    return 0;
}

sub IsMeasured {
    my($self) = @_;
    return 1 if $self->{ExteriorRing}->IsMeasured;
    for my $r (@{$self->{InteriorRings}}) {
	return 1 if $r->IsMeasured;
    }
    return 0;
}

sub AddInteriorRing {
    my($self, $ring, $i) = @_;
    croak 'usage: Polygon->AddInteriorRing($ring[, $i])' 
	unless $ring and $ring->isa('Geo::OGC::LinearRing');
    my $rings = $self->{InteriorRings};
    $i = @$rings unless defined $i;
    if (@$rings) {
	my $temp = $rings->[$i-1];
	splice @$rings,$i-1,1,($temp, $ring);
    } else {
	push @$rings, $ring;
    }
}

sub ExteriorRing {
    my($self, $ring) = @_;
    if (defined $ring) {
	croak 'usage: Polygon->ExteriorRing($ring)' 
	    unless $ring->isa('Geo::OGC::LinearRing');
	$self->{ExteriorRing} = $ring;
    } else {
	return $self->{ExteriorRing};
    }
}

sub Envelope {
    my($self) = @_;
    return $self->{ExteriorRing}->Envelope;
}

=pod

=over

=item NumInteriorRing()

Return the number of interior rings in the polygon.

=cut

sub NumInteriorRing {
    my($self) = @_;
    scalar(@{$self->{InteriorRings}});
}

sub InteriorRingN {
    my($self, $N, $ring) = @_;
    my $rings = $self->{InteriorRings};
    $rings->[$N-1] = $ring if defined $ring;
    return $rings->[$N-1] if @$rings;
}

# @note Assumes the order of the interior rings is the same.
sub Equals {
    my($self, $geom) = @_;
    return 0 unless $geom->isa('Geo::OGC::Polygon');
    return 0 unless @{$self->{InteriorRings}} == @{$geom->{InteriorRings}};
    return 0 unless $self->{ExteriorRing}->Equals($geom->{ExteriorRing});
    for my $i (0..$#{$self->{InteriorRings}}) {
	return 0 unless $self->{InteriorRings}[$i]->Equals($geom->{InteriorRings}[$i]);
    }
    return 1;
}

sub Area {
    my($self) = @_;
    my $a = $self->{ExteriorRing}->Area;
    for my $ring (@{$self->{InteriorRings}}) {
	$a -= $ring->Area;
    }
    return $a;
}

sub IsPointIn {
    my($self, $point) = @_;
    my $c = $self->{ExteriorRing}->IsPointIn($point);
    if ($c) {
	for my $ring (@{$self->{InteriorRings}}) {
	    $c = 0, last if $ring->IsPointIn($point);
	}
    }
    return $c;
}

sub Distance {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	return $geom->Distance($self);
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	return $geom->Distance($self);
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	my $dist;
	for my $p (@{$self->{ExteriorRing}->{Points}}) {
	    if ($geom->{ExteriorRing}->IsPointIn($p)) {
		my $c = 1;
		for my $ring (@{$self->{InteriorRings}}) {
		    if ($ring->IsPointIn($p)) {
			my $d = $p->DistanceToLineStringSqr($ring);
			$dist = $d if !(defined $dist) or $d < $dist;
			$c = 0;
		    }
		}
		return 0 if $c;
	    } else {
		my $d = $p->DistanceToLineStringSqr($geom->{ExteriorRing});
		$dist = $d if !(defined $dist) or $d < $dist;
	    }
	}
	return $dist;
    } elsif ($geom->isa('Geo::OGC::GeometryCollection')) {
	my $dist = $self->Distance($geom->{Geometries}[0]);
	for my $g (@{$geom->{Geometries}}[1..$#{$geom->{Geometries}}]) {
	    my $d = $self->Distance($g);
	    $dist = $d if $d < $dist;
	}
	return $dist;
    } else {
	croak "can't compute distance between a ".ref($geom)." and a polygon";
    }
}

sub Within {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	for my $p (@{$self->{ExteriorRing}->{Points}}) {
	    return 0 unless $p->Equals($geom);
	}
	return 1;
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	for my $p (@{$self->{ExteriorRing}->{Points}}) {
	    return 0 unless $p->Within($geom);
	}
	return 1;
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	croak "polygon within ".ref($geom)." is not yet implemented";
	# the exterior and interior rings must be completely within
	# and the other's interiors must not be within ...
	for my $p (@{$self->{ExteriorRing}->{Points}}) {
	    return 0 unless $p->Within($geom);
	}
	return 1;
    } else {
	croak "polygon within ".ref($geom)." is not yet implemented";
    }
}

sub Intersection {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	return $geom->Intersection($self);
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	return $geom->Intersection($self);
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	croak "polygon within ".ref($geom)." is not yet implemented";

	# 1st intersection between outer rings $A (this) and $B (other)
	my $A = $self->{ExteriorRing};
	my $B = $geom->{ExteriorRing};
	my $p1 = $A->{Points}[0];
	my $c = $B->IsPointStricktlyIn($p1);

	my $i = 0;
	my $j;
	while (1) {
	    my $p = $A->{Points}[$i];
	    $j = $i, last if $B->IsPointStricktlyOut($p);
	    $i++;
	    last if $i == @{$A->{Points}};
	}
	if (defined $j) { # there is at least one point
	}
	# the list of 
	my @A; # lines on A
	
    } else {
	croak "polygon within ".ref($geom)." is not yet implemented";
    }
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my $text .= $self->{ExteriorRing}->as_text if $self->{ExteriorRing};
    for my $ring (@{$self->{InteriorRings}}) {
	$text .= ', ';
	$text .= $ring->as_text;
    }
    my $ZM = $self->Is3D ? 'Z' : '';
    $ZM .= 'M' if $self->IsMeasured;
    $text = uc($self->GeometryType).$ZM.' ('.$text.')' if $include_tag;
    return $text;
}

sub MakeCollection {
    my($self) = @_;
    my $coll = Geo::OGC::MultiPolygon->new;
    $coll->AddGeometry($self);
    return $coll;
}

sub ClosestVertex {
    my($self, $x, $y) = @_;
    return unless $self->{ExteriorRing};
    my($imin, $dmin) = $self->{ExteriorRing}->ClosestVertex($x, $y);
    my $iring = -1;
    my $r = 0;
    for my $ring (@{$self->{InteriorRings}}) {
	my($i, $d) = $ring->ClosestVertex($x, $y);
	($iring, $imin, $dmin) = ($r, $i, $d) if $d < $dmin;
	$r++;
    }
    return ($iring, $imin, $dmin);
}

sub VertexAt {
    my($self, $iring, $ivertex) = @_;
    return $self->{ExteriorRing}->VertexAt($ivertex) if $iring < 0;
    return $self->{InteriorRings}[$iring]->VertexAt($ivertex);
}

sub ClosestPoint {
    my($self, $x, $y) = @_;
    return unless $self->{ExteriorRing};
    my($imin, $pmin, $dmin) = $self->{ExteriorRing}->ClosestPoint($x, $y);
    my $iring = -1;
    my $r = 0;
    for my $ring (@{$self->{InteriorRings}}) {
	my($i, $p, $d) = $ring->ClosestPoint($x, $y);
	($iring, $imin, $pmin, $dmin) = ($r, $i, $p, $d) if $d < $dmin;
	$r++;
    }
    return ($iring, $imin, $pmin, $dmin);
}

sub AddVertex {
    my($self, $ring, $i, $p) = @_;
    $self->{ExteriorRing}->AddVertex($i, $p), return if $ring < 0;
    $self->{InteriorRings}[$ring]->AddVertex($i, $p);
}

sub DeleteVertex {
    my($self, $ring, $i) = @_;
    $self->{ExteriorRing}->DeleteVertex($i), return if $ring < 0;
    $self->{InteriorRings}[$ring]->DeleteVertex($i);
}

## @method LastPolygon()
# @brief Returns self
sub LastPolygon {
    my($self) = @_;
    return $self;
}

=pod

=back

=head2 Geo::OGC::Triangle

=cut

package Geo::OGC::Triangle;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::Polygon );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Polygon::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'Triangle';
}

=pod

=head2 Geo::OGC::PolyhedralSurface

=cut

package Geo::OGC::PolyhedralSurface;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::Surface );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Surface::new($package, %params);
    return $self;
}

sub init {
    my($self, %params) = @_;
    $self->SUPER::init(%params);
    $self->{Patches} = []; # polygon
    if ($params{patches}) {
	for my $p (@{$params{patches}}) {
	    $self->AddPatch(Geo::OGC::Polygon->new(points=>$p));
	}
    } elsif ($params{patchesm}) {
	for my $p (@{$params{patches}}) {
	    $self->AddPatch(Geo::OGC::Polygon->new(pointsm=>$p));
	}
    }
}

sub copy {
    my($self, $clone) = @_;
    $self->SUPER::copy($clone);
    for my $p (@{$self->{Patches}}){
	$clone->AddPatch($p->Clone);
    }
}

sub IsEmpty {
    my($self) = @_;
    return 1 if !$self->{Patches} or @{$self->{Patches}} == 0;
    return undef;
}

sub GeometryType {
    return 'PolyhedralSurface';
}

sub AddPatch {
    my($self, $patch, $i) = @_;
    croak 'usage: PolyhedralSurface->AddPatch($patch[, $i])' 
	unless $patch and $patch->isa('Geo::OGC::Polygon');
    my $patches = $self->{Patches};
    $i = @$patches unless defined $i;
    if (@$patches) {
	my $temp = $patches->[$i-1];
	splice @$patches,$i-1,1,($temp, $patch);
    } else {
	push @$patches, $patch;
    }
}

sub NumPatches {
    my($self) = @_;
    @{$self->{Patches}};
}

sub PatchN {
    my($self, $N, $patch) = @_;
    my $patches = $self->{Patches};
    $patches->[$N-1] = $patch if defined $patch;
    return $patches->[$N-1] if @$patches;
}

sub BoundingPolygons {
    my($self, $p) = @_;
    croak "BoundingPolygons method for class ".ref($self)." is not implemented yet";
}

sub IsClosed {
    my($self) = @_;
    croak "IsClosed method for class ".ref($self)." is not implemented yet";
}

sub IsMeasured {
    my($self) = @_;
    for my $p (@{$self->{Patches}}) {
	return 1 if $p->IsMeasured;
    }
    return 0;
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my $text = '';
    for my $patch (@{$self->{Patches}}) {
	$text .= ', ';
	$text .= $patch->as_text;
    }
    my $ZM = $self->Is3D ? 'Z' : '';
    $ZM .= 'M' if $self->IsMeasured;
    $text = uc($self->GeometryType).$ZM.' ('.$text.')' if $include_tag;
    return $text;
}

=pod

=head2 Geo::OGC::TIN

=cut

package Geo::OGC::TIN;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::PolyhedralSurface );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Surface::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'TIN';
}

=pod

=head2 Geo::OGC::GeometryCollection

=cut

package Geo::OGC::GeometryCollection;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::Geometry );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::Geometry::new($package, %params);
    return $self;
}

sub init {
    my($self, %params) = @_;
    $self->SUPER::init(%params);
    $self->{Geometries} = [];
}

sub copy {
    my($self, $clone) = @_;
    $self->SUPER::copy($clone);
    for my $g (@{$self->{Geometries}}) {
	$clone->AddGeometry($g->Clone);
    }
}

sub IsEmpty {
    my($self) = @_;
    return 1 if !$self->{Geometries} or @{$self->{Geometries}} == 0;
    return undef;
}

sub GeometryType {
    return 'GeometryCollection';
}

sub Dimension {
    my($self) = @_;
    my $dim;
    for my $g (@{$self->{Geometries}}) {
	my $d = $g->Dimension;
	$dim = $d if !(defined $dim) or $d > $dim;
    }
    return $dim;
}

sub Is3D {
    my($self) = @_;
    for my $g (@{$self->{Geometries}}) {
	return 1 if $g->Is3D;
    }
    return 0;
}

sub IsMeasured {
    my($self) = @_;
    for my $g (@{$self->{Geometries}}) {
	return 1 if $g->IsMeasured;
    }
    return 0;
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my $text = join(',', map {$_->as_text(1, 1)} @{$self->{Geometries}});
    my $ZM = $self->Is3D ? 'Z' : '';
    $ZM .= 'M' if $self->IsMeasured;
    $text = uc($self->GeometryType).$ZM.' ('.$text.')' if $include_tag;
    return $text;
}

sub ElementType {
    return 'Geometry';
}

sub AddGeometry {
    my($self, $geometry, $i) = @_;
    croak 'usage: GeometryCollection->AddGeometry($geometry[, $i])' 
	unless $geometry and $geometry->isa('Geo::OGC::Geometry');
    my $geometries = $self->{Geometries};
    $i = @$geometries unless defined $i;
    if (@$geometries) {
	my $temp = $geometries->[$i-1];
	splice @$geometries,$i-1,1,($temp, $geometry);
    } else {
	push @$geometries, $geometry;
    }
}

=pod

=over

=item NumGeometries()

Return the number of geometries in this collection.

=cut

sub NumGeometries {
    my($self) = @_;
    @{$self->{Geometries}};
}

=pod

=item GeometryN($n)

Return the Nth geometry from the collection (the index of the first geometry is 1).

=cut

sub GeometryN {
    my($self, $N, $geometry) = @_;
    my $geometries = $self->{Geometries};
    $geometries->[$N-1] = $geometry if defined $geometry;
    return $geometries->[$N-1] if @$geometries;
}

sub Envelope {
    my($self) = @_;
    my($minx, $miny, $maxx, $maxy);
    for my $g (@{$self->{Geometries}}) {
	my $e = $g->Envelope;
	my $min = $e->PointN(1);
	my $max = $e->PointN(3);
	$minx = $min->{X} if !defined($minx) or $minx > $min->{X};
	$miny = $min->{Y} if !defined($miny) or $miny > $min->{Y};
	$maxx = $max->{X} if !defined($maxx) or $maxx > $max->{X};
	$maxy = $max->{Y} if !defined($maxy) or $maxy > $max->{Y};
    }
    my $r = new Geo::OGC::LinearRing;
    $r->AddPoint(Geo::OGC::Point->new($minx, $miny));
    $r->AddPoint(Geo::OGC::Point->new($maxx, $miny));
    $r->AddPoint(Geo::OGC::Point->new($maxx, $maxy));
    $r->AddPoint(Geo::OGC::Point->new($minx, $maxy));
    $r->Close;
    return $r;
}

# Assumes the order is the same.
sub Equals {
    my($self, $geom) = @_;
    return 0 unless $geom->isa('Geo::OGC::GeometryCollection');
    return 0 unless @{$self->{Geometries}} == @{$geom->{Geometries}};
    for my $i (0..$#{$self->{Geometries}}) {
	return 0 unless $self->{Geometries}[$i]->Equals($geom->{Geometries}[$i]);
    }
    return 1;
}

sub Distance {
    my($self, $geom) = @_;
    if ($geom->isa('Geo::OGC::Point')) {
	return $geom->Distance($self);
    } elsif ($geom->isa('Geo::OGC::LineString')) {
	return $geom->Distance($self);
    } elsif ($geom->isa('Geo::OGC::Polygon')) {
	return $geom->Distance($self);
    } elsif ($geom->isa('Geo::OGC::GeometryCollection')) {
	my $dist = $self->Distance($geom->{Geometries}[0]);
	for my $g (@{$geom->{Geometries}}[1..$#{$geom->{Geometries}}]) {
	    my $d = $g->Distance($self);
	    $dist = $d if $d < $dist;
	}
	return $dist;
    } else {
	croak "can't compute distance between a ".ref($geom)." and a geometry collection";
    }
}

sub ClosestVertex {
    my($self, $x, $y) = @_;
    return unless @{$self->{Geometries}};
    my @rmin = $self->{Geometries}[0]->ClosestVertex($x, $y);
    my $imin = 0;
    my $i = 0;
    for my $g (@{$self->{Geometries}}) {
	$i++, next if $i == 0;
	my @r = $g->ClosestVertex($x, $y);
	if ($r[$#r] < $rmin[$#rmin]) {
	    @rmin = @r;
	    $imin = $i;
	}
	$i++;
    }
    return ($imin, @rmin);
}

sub VertexAt {
    my $self = shift;
    my $i = shift;
    return $self->{Geometries}[$i]->VertexAt(@_);
}

sub ClosestPoint {
    my($self, $x, $y) = @_;
    return unless @{$self->{Geometries}};
    my @rmin = $self->{Geometries}[0]->ClosestPoint($x, $y);
    my $imin = 0;
    my $i = 0;
    for my $g (@{$self->{Geometries}}) {
	$i++, next if $i == 0;
	my @r = $g->ClosestPoint($x, $y);
	if ($r[$#r] < $rmin[$#rmin]) {
	    @rmin = @r;
	    $imin = $i;
	}
	$i++;
    }
    return ($imin, @rmin);
}

sub AddVertex {
    my $self = shift;
    my $i = shift;
    $self->{Geometries}[$i]->AddVertex(@_);
}

sub DeleteVertex {
    my $self = shift;
    my $i = shift;
    $self->{Geometries}[$i]->DeleteVertex(@_);
}

sub LastPolygon {
    my($self) = @_;
    for (my $i = $#{$self->{Geometries}}; $i >= 0; $i--) {
	my $polygon = $self->{Geometries}[$i]->LastPolygon;
	return $polygon if $polygon;
    }
}

=pod

=back

=head2 Geo::OGC::MultiSurface

=cut

package Geo::OGC::MultiSurface;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::GeometryCollection );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::GeometryCollection::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'MultiSurface';
}

sub ElementType {
    return 'Surface';
}

sub Area {
    my($self) = @_;
    croak "Area method for class ".ref($self)." is not implemented yet";
}

sub Centroid {
    my($self) = @_;
    croak "Centroid method for class ".ref($self)." is not implemented yet";
}

sub PointOnSurface {
    my($self) = @_;
    croak "PointOnSurface method for class ".ref($self)." is not implemented yet";
}

=pod

=head2 Geo::OGC::MultiCurve

=cut

package Geo::OGC::MultiCurve;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::GeometryCollection );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::GeometryCollection::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'MultiCurve';
}

sub ElementType {
    return 'Curve';
}

=pod

=head2 Geo::OGC::MultiPoint

=cut

package Geo::OGC::MultiPoint;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::GeometryCollection );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::GeometryCollection::new($package, %params);
    return $self;
}

sub init {
    my($self, %params) = @_;
    $self->SUPER::init(%params);
    if ($params{points}) {
	for my $p (@{$params{points}}) {
	    $self->AddGeometry(Geo::OGC::Point->new(point=>$p));
	}
    } elsif ($params{pointsm}) {
	for my $p (@{$params{pointsm}}) {
	    $self->AddGeometry(Geo::OGC::Point->new(pointm=>$p));
	}
    }
}

sub GeometryType {
    return 'MultiPoint';
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my $text = join(',', map {$_->as_text(1)} @{$self->{Geometries}});
    my $ZM = $self->Is3D ? 'Z' : '';
    $ZM .= 'M' if $self->IsMeasured;
    $text = uc($self->GeometryType).$ZM.' ('.$text.')' if $include_tag;
    return $text;
}

sub ElementType {
    return 'Point';
}

sub Boundary {
    my($self) = @_;
    return Geo::OGC::GeometryCollection->new();
}

=pod

=head2 Geo::OGC::MultiPolygon

=cut

package Geo::OGC::MultiPolygon;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::MultiSurface );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::MultiSurface::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'MultiPolygon';
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my $text = join(',', map {$_->as_text(1)} @{$self->{Geometries}});
    my $ZM = $self->Is3D ? 'Z' : '';
    $ZM .= 'M' if $self->IsMeasured;
    $text = uc($self->GeometryType).$ZM.' ('.$text.')' if $include_tag;
    return $text;
}

sub ElementType {
    return 'Polygon';
}

=pod

=over

=item LastPolygon()

Returns last (latest added) polygon or undef.

=cut

sub LastPolygon {
    return undef;
}

=pod

=back

=head2 Geo::OGC::MultiLineString

=cut

package Geo::OGC::MultiLineString;

use strict;
use Carp;

our @ISA = qw( Geo::OGC::MultiCurve );

sub new {
    my($package, %params) = @_;
    my $self = Geo::OGC::MultiCurve::new($package, %params);
    return $self;
}

sub GeometryType {
    return 'MultiLineString';
}

sub as_text {
    my($self, $force_parens, $include_tag) = @_;
    my $text = join(',', map {$_->as_text(1)} @{$self->{Geometries}});
    my $ZM = $self->Is3D ? 'Z' : '';
    $ZM .= 'M' if $self->IsMeasured;
    $text = uc($self->GeometryType).$ZM.' ('.$text.')' if $include_tag;
    return $text;
}

sub ElementType {
    return 'LineString';
}

=pod

=head1 ACKNOWLEDGEMENTS

The OpenGIS (r) Implementation Standard for Geographic information -
Simple feature access - Part 1: Common architecture was heavily used
in preparation of this module.

=head1 REPOSITORY

L<https://github.com/ajolma/Geo-OGC-Geometry>

=head1 AUTHOR

Ari Jolma L<https://github.com/ajolma>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008- Ari Jolma

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=cut

1;
__END__
