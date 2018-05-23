package Geo::GDAL::FFI::Geometry;
use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = 0.05_01;

my %ref;

sub new {
    my $class = shift;
    my $g = 0;
    confess "Must give either geometry type or format => data." unless @_;
    if (@_ == 1) {
        my $type = shift // '';
        my $tmp = $Geo::GDAL::FFI::geometry_types{$type};
        confess "Empty or unknown geometry type: '$type'\n" unless defined $tmp;
        my $m = $type =~ /M$/;
        my $z = $type =~ /ZM$/ || $type =~ /25D$/;
        $g = Geo::GDAL::FFI::OGR_G_CreateGeometry($tmp);
        confess "OGR_G_CreateGeometry failed." unless $g; # should not happen
        Geo::GDAL::FFI::OGR_G_SetMeasured($g, 1) if $m;
        Geo::GDAL::FFI::OGR_G_Set3D($g, 1) if $z;
        return bless \$g, $class;
    } else {
        my ($format, $string, $sr) = @_;
        my $tmp = $Geo::GDAL::FFI::geometry_formats{$format};
        confess "Empty or unknown geometry format: '$format'\n" unless defined $tmp;
        $sr = $$sr if $sr;
        if ($format eq 'WKT') {
            my $e = Geo::GDAL::FFI::OGR_G_CreateFromWkt(\$string, $sr, \$g);
            confess(Geo::GDAL::FFI::error_msg({OGRError => $e})) if $e;
        }
    }
    return bless \$g, $class;
}

sub DESTROY {
    my ($self) = @_;
    delete $Geo::GDAL::FFI::parent{$$self};
    if ($ref{$$self}) {
        delete $ref{$$self};
        return;
    }
    if ($Geo::GDAL::FFI::immutable{$$self}) {
        #say STDERR "forget $$self $immutable{$$self}";
        $Geo::GDAL::FFI::immutable{$$self}--;
        delete $Geo::GDAL::FFI::immutable{$$self} if $Geo::GDAL::FFI::immutable{$$self} == 0;
    } else {
        #say STDERR "destroy $$self";
        Geo::GDAL::FFI::OGR_G_DestroyGeometry($$self);
    }
}

sub Clone {
    my ($self) = @_;
    my $g = Geo::GDAL::FFI::OGR_G_Clone($$self);
    return bless \$g, 'Geo::GDAL::FFI::Geometry';
}

sub GetType {
    my ($self, $mode) = @_;
    $mode //= '';
    my $t = Geo::GDAL::FFI::OGR_G_GetGeometryType($$self);
    Geo::GDAL::FFI::OGR_GT_Flatten($t) if $mode =~ /flatten/i;
    #say STDERR "type is $t";
    return $Geo::GDAL::FFI::geometry_types_reverse{$t};
}

sub GetPointCount {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_GetPointCount($$self);
}

sub SetPoint {
    my $self = shift;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    my $i;
    if (Geo::GDAL::FFI::OGR_G_GetDimension($$self) == 0) {
        $i = 0;
    } else {
        $i = shift;
    }
    my ($x, $y, $z, $m, $is3d, $ism);
    confess "SetPoint missing coordinate parameters." unless @_;
    if (ref $_[0]) {
        ($x, $y, $z, $m) = @{$_[0]};
        $is3d = $_[1] // Geo::GDAL::FFI::OGR_G_Is3D($$self);
        $ism = $_[2] // Geo::GDAL::FFI::OGR_G_IsMeasured($$self);
    } else {
        confess "SetPoint missing coordinate parameters." unless @_ > 1;
        ($x, $y, $z, $m) = @_;
        $is3d = Geo::GDAL::FFI::OGR_G_Is3D($$self);
        $ism = Geo::GDAL::FFI::OGR_G_IsMeasured($$self);
    }
    if ($is3d && $ism) {
        $z //= 0;
        $m //= 0;
        Geo::GDAL::FFI::OGR_G_SetPointZM($$self, $i, $x, $y, $z, $m);
    } elsif ($ism) {
        $m //= 0;
        Geo::GDAL::FFI::OGR_G_SetPointM($$self, $i, $x, $y, $m);
    } elsif ($is3d) {
        $z //= 0;
        Geo::GDAL::FFI::OGR_G_SetPoint($$self, $i, $x, $y, $z);
    } else {
        Geo::GDAL::FFI::OGR_G_SetPoint_2D($$self, $i, $x, $y);
    }
}

sub GetPoint {
    my ($self, $i, $is3d, $ism) = @_;
    $i //= 0;
    $is3d //= Geo::GDAL::FFI::OGR_G_Is3D($$self);
    $ism //= Geo::GDAL::FFI::OGR_G_IsMeasured($$self);
    my ($x, $y, $z, $m) = (0, 0, 0, 0);
    Geo::GDAL::FFI::OGR_G_GetPointZM($$self, $i, \$x, \$y, \$z, \$m);
    my @point = ($x, $y);
    push @point, $z if $is3d;
    push @point, $m if $ism;
    return wantarray ? @point : \@point;
}

sub GetPoints {
    my ($self, $is3d, $ism) = @_;
    $is3d //= Geo::GDAL::FFI::OGR_G_Is3D($$self);
    $ism //= Geo::GDAL::FFI::OGR_G_IsMeasured($$self);
    my $points = [];
    my $n = $self->GetGeometryCount;
    if ($n == 0) {
        $n = $self->GetPointCount;
        return scalar $self->GetPoint(0, $is3d, $ism) if $n == 0;
        for my $i (0..$n-1) {
            my $p = $self->GetPoint($i, $is3d, $ism);
            push @$points, $p;
        }
        return $points;
    }
    for my $i (0..$n-1) {
        push @$points, $self->GetGeometry($i)->GetPoints($is3d, $ism);
    }
    return $points;
}

sub SetPoints {
    my ($self, $points, $is3d, $ism) = @_;
    confess "SetPoints must be called with an arrayref." unless ref $points;
    $is3d //= Geo::GDAL::FFI::OGR_G_Is3D($$self);
    $ism //= Geo::GDAL::FFI::OGR_G_IsMeasured($$self);
    my $n = $self->GetGeometryCount;
    if ($n == 0) {
        unless (ref $points->[0]) {
            $self->SetPoint($points, $is3d, $ism);
            return;
        }
        $n = @$points;
        for my $i (0..$n-1) {
            $self->SetPoint($i, $points->[$i], $is3d, $ism);
        }
        return;
    }
    for my $i (0..$n-1) {
        $self->GetGeometry($i)->SetPoints($points->[$i], $is3d, $ism);
    }
}

sub GetGeometryCount {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_GetGeometryCount($$self);
}

sub GetGeometry {
    my ($self, $i) = @_;
    my $g = Geo::GDAL::FFI::OGR_G_GetGeometryRef($$self, $i);
    $Geo::GDAL::FFI::parent{$g} = $self;
    $ref{$g} = 1;
    return bless \$g, 'Geo::GDAL::FFI::Geometry';
}

sub AddGeometry {
    my ($self, $g) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    my $e = Geo::GDAL::FFI::OGR_G_OGR_G_AddGeometry($$self, $$g);
    return unless $e;
    confess(Geo::GDAL::FFI::error_msg());
}

sub RemoveGeometry {
    my ($self, $i) = @_;
    confess "Can't modify an immutable object." if $Geo::GDAL::FFI::immutable{$$self};
    my $e = Geo::GDAL::FFI::OGR_G_RemoveGeometry($$self, $i, 1);
    return unless $e;
    confess(Geo::GDAL::FFI::error_msg());
}

sub ExportToWKT {
    my ($self) = @_;
    my $wkt = '';
    Geo::GDAL::FFI::OGR_G_ExportToIsoWkt($$self, \$wkt);
    return $wkt;
}
*AsText = *ExportToWKT;

sub Intersects {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Intersects($$self, $$geom);
}

sub Equals {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Equals($$self, $$geom);
}

sub Disjoint {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Disjoint($$self, $$geom);
}

sub Touches {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Touches($$self, $$geom);
}

sub Crosses {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Crosses($$self, $$geom);
}

sub Within {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Within($$self, $$geom);
}

sub Contains {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Contains($$self, $$geom);
}

sub Overlaps {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Overlaps($$self, $$geom);
}

sub Boundary {
    my ($self) = @_;
    return bless \Geo::GDAL::FFI::OGR_G_Boundary($$self), 'Geo::GDAL::FFI::Geometry';
}

sub ConvexHull {
    my ($self) = @_;
    return bless \Geo::GDAL::FFI::OGR_G_ConvexHull($$self), 'Geo::GDAL::FFI::Geometry';
}

sub Buffer {
    my ($self, $dist, $quad_segs) = @_;
    return bless \Geo::GDAL::FFI::OGR_G_Buffer($$self, $dist, $quad_segs), 'Geo::GDAL::FFI::Geometry';
}

sub Intersection {
    my ($self, $geom) = @_;
    return bless \Geo::GDAL::FFI::OGR_G_Intersection($$self, $$geom), 'Geo::GDAL::FFI::Geometry';
}

sub Union {
    my ($self, $geom) = @_;
    return bless \Geo::GDAL::FFI::OGR_G_Union($$self, $$geom), 'Geo::GDAL::FFI::Geometry';
}

sub Difference {
    my ($self, $geom) = @_;
    return bless \Geo::GDAL::FFI::OGR_G_Difference($$self, $$geom), 'Geo::GDAL::FFI::Geometry';
}

sub SymDifference {
    my ($self, $geom) = @_;
    return bless \Geo::GDAL::FFI::OGR_G_SymDifference($$self, $$geom), 'Geo::GDAL::FFI::Geometry';
}

sub Distance {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Distance($$self, $$geom);
}

sub Distance3D {
    my ($self, $geom) = @_;
    return Geo::GDAL::FFI::OGR_G_Distance3D($$self, $$geom);
}

sub Length {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_Length($$self);
}

sub Area {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_Area($$self);
}

sub Centroid {
    my ($self) = @_;
    my $centroid = Geo::GDAL::FFI::Geometry->new('Point');
    Geo::GDAL::FFI::OGR_G_Centroid($$self, $$centroid);
    my $msg = Geo::GDAL::FFI::error_msg();
    confess($msg) if $msg;
    return $centroid;
}

sub Empty {
    my ($self) = @_;
    Geo::GDAL::FFI::OGR_G_Empty($$self);
}

sub IsEmpty {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_IsEmpty($$self);
}

sub IsValid {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_IsValid($$self);
}

sub IsSimple {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_IsSimple($$self);
}

sub IsRing {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_G_IsRing($$self);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::Geometry - A GDAL geometry

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

 my $geom = Geo::GDAL::FFI::Geometry->new($geometry_type);

$type must be one of Geo::GDAL::FFI::GeometryTypes().

 my $geom = Geo::GDAL::FFI::Geometry->new($format, $arg, $sr);

$format must be one of Geo::GDAL::FFI::GeometryFormats(), e.g., 'WKT'.

$sr should be a SpatialRef object if given.

=head2 Clone

 my $geom2 = $geom1->Clone;

Clones this geometry and returns the clone.

=head2 GetType

 my $type = $geom->GetType($mode);

Returns the type of this geometry. If $mode (optional) is 'flatten',
returns the type without Z, M, or ZM postfix.

=head2 GetPointCount

Returns the point count of this geometry.

=head2 SetPoint

 $point->SetPoint($x, $y, $z, $m);

Set the coordinates of a point geometry. The usage of $z and $m in the
method depend on the actual 3D or measured status of the point.

 $point->SetPoint([$x, $y, $z, $m]);

Set the coordinates of a point geometry. The usage of $z and $m in the
method depend on the actual 3D or measured status of the geometry.

 $geom->SetPoint($i, $x, $y, $z, $m);

Set the coordinates of the ith (zero based index) point in a curve
geometry. The usage of $z and $m in the method depend on the actual 3D
or measured status of the geometry.

Note that setting the nth point of a curve creates all points 0..n-2
unless they exist.

 $geom->SetPoint($i, $coords);

Set the coordinates of the ith (zero based index) point in this
curve. $coords must be a reference to an array of the coordinates. The
usage of $z and $m in the method depend on the 3D or measured status
of the geometry.

Note that setting the nth point of a curve may create all points
0..n-2.

=head2 GetPoint

 my $coords = $geom->GetPoint($i);

Get the coordinates of the ith (zero based index) point in this
curve. This method can also be used to set the coordinates of a point
geometry and then the $i must be zero if it is given.

Returns the coordinates either as a list or a reference to an
anonymous array depending on the context. The coordinates contain $z
and $m depending on the 3D or measured status of the geometry.

=head2 GetPoints

 my $points = $geom->GetPoints;

Returns the coordinates of the vertices of this geometry in an obvious
array based data structure. Note that different geometry types have
similar data structures.

=head2 SetPoints

 $geom->SetPoints($points);

Sets the coordinates of the vertices of this geometry from an obvious
array based data structure. Note that different geometry types may
have similar data structures. If the geometry contains subgeometries
(like polygon contains rings for example), the data structure is
assumed to adhere to this structure. Uses SetPoint and may thus add
points to curves.

=head2 GetGeometryCount

 my $num_geometries = $geom->GetGeometryCount;

=head2 GetGeometry

 my $outer_ring = $polygon->GetGeometry(0);

Returns the ith subgeometry (zero based index) in this geometry. The
returned geometry object is only a wrapper to the underlying C++
reference and thus changing that geometry will change the parent.

=head2 AddGeometry

 $polygon->AddGeometry($ring);

=head2 RemoveGeometry

 $geom->RemoveGeometry($i);

=head2 AsText

=head2 Intersects

=head2 Equals

=head2 Disjoint

=head2 Touches

=head2 Crosses

=head2 Within

=head2 Contains

=head2 Overlaps

=head2 Boundary

=head2 ConvexHull

=head2 Buffer

=head2 Intersection

=head2 Union

=head2 Difference

=head2 SymDifference

=head2 Distance

=head2 Distance3D

=head2 Length

=head2 Area

=head2 Centroid

=head2 Empty

=head2 IsEmpty

=head2 IsValid

=head2 IsSimple

=head2 IsRing

=head1 LICENSE

This software is released under the Artistic License. See
L<perlartistic>.

=head1 AUTHOR

Ari Jolma - Ari.Jolma at gmail.com

=head1 SEE ALSO

L<Geo::GDAL::FFI>

L<Alien::gdal>, L<FFI::Platypus>, L<http://www.gdal.org>

=cut

__END__;
