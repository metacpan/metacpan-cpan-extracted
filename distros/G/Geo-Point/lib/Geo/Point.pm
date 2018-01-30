# Copyrights 2005-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Geo-Point.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Geo::Point;
use vars '$VERSION';
$VERSION = '0.97';

use base 'Geo::Shape';

use strict;
use warnings;

use Geo::Proj;
use Carp        qw/confess croak/;


sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);
    $self->{GP_x} = defined $args->{x}    ? $args->{x}
                  : defined $args->{long} ? $args->{long}
                  :                         $args->{longitude};
    $self->{GP_y} = defined $args->{y}    ? $args->{y}
                  : defined $args->{lat}  ? $args->{lat}
                  :                         $args->{latitude};
    $self;
}


sub latlong(@)
{   my $thing = shift;

    if(ref $thing)   # instance method
    {   return ($thing->{GP_y}, $thing->{GP_x}) unless @_ > 2;

        my $proj = pop @_;
        return $thing->in($proj)->latlong;
    }

    # class method
    $thing->new(lat => shift, long => shift, proj => shift);
}


sub longlat(@)
{   my $thing = shift;

    if(ref $thing)   # instance method
    {   return ($thing->{GP_x}, $thing->{GP_y}) unless @_ > 2;
        my $proj = pop @_;
        return $thing->in($proj)->longlat;
    }

    # class method
    $thing->new(long => shift, lat => shift, proj => shift);
}


sub xy(@)
{   my $thing = shift;

    if(ref $thing)   # instance method
    {   return ($thing->{GP_x}, $thing->{GP_y}) unless @_ > 2;

        my $proj = pop @_;
        return $thing->in($proj)->xy;
    }

    # class method
    $thing->new(x => shift, y => shift, proj => shift);
}


sub yx(@)
{   my $thing = shift;

    if(ref $thing)   # instance method
    {   return ($thing->{GP_y}, $thing->{GP_x}) unless @_ > 2;

        my $proj = pop @_;
        return $thing->in($proj)->yx;
    }

    # class method
    $thing->new(y => shift, x => shift, proj => shift);
}


sub fromString($;$)
{   my ($class, $string, $nick) = @_;

    defined $string or return;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return () unless length $string;

    # line starts with project label
    $nick   = $1 if $string =~ s/^(\w+)\s*\:\s*//;

    # The line is either split by comma's or by blanks.
    my @parts
      = $string =~ m/\,/
      ? (split /\s*\,\s*/, $string)
      : (split /\s+/, $string);

    # Now, the first word may be a projection.  That is: any non-coordinate,
    # anything which starts with more than one letter.
    if($parts[0] =~ m/^[a-z_]{2}/i)
    {   $nick = shift @parts;          # overrules default
    }

    my $proj;
    if(!defined $nick)
    {   $proj = Geo::Proj->defaultProjection;
        $nick = $proj->nick;
    }
    elsif($nick eq 'utm')
    {   die "ERROR: UTM requires 3 values: easting, northing, and zone\n"
           unless @parts==3;

        my $zone;
        if($parts[0] =~ m/^\d\d?[C-HJ-NP-X]?$/i )
        {   $zone = shift @parts;
        }
        elsif($parts[2] =~ m/^\d\d?[C-HJ-NP-X]?$/i )
        {   $zone = pop @parts;
        }

        if(!defined $zone || $zone==0 || $zone > 60)
        {   die "ERROR: illegal UTM zone in $string";
        }

        $proj = Geo::Proj->UTMprojection(undef, $zone);
        $nick = $proj->nick;
    }
    else
    {   $proj = Geo::Proj->projection($nick)
            or croak "ERROR: undefined projection $nick";
    }

    croak "ERROR: too few values in '$string' (got ".@parts.", expect 2)\n"
       if @parts < 2;

    croak "ERROR: too many values in '$string' (got ".@parts.", expect 2)\n"
       if @parts > 2;

    if($proj->proj4->isLatlong)
    {   my ($lats, $longs)
         = (  $parts[0] =~ m/[ewEW]$/ || $parts[1] =~ m/[nsNS]$/
           || $parts[0] =~ m/^[ewEW]/ || $parts[1] =~ m/^[nsNS]/
           )
         ? reverse(@parts) : @parts;

        my $lat  = $class->dms2deg($lats);
        defined $lat
            or die "ERROR: dms latitude coordinate not understood: $lats\n";

        my $long = $class->dms2deg($longs);
        defined $long
           or die "ERROR: dms longitude coordinate not understood: $longs\n";

        return $class->new(lat => $lat, long => $long, proj => $nick);
    }
    else # type eq xy
    {   my ($x, $y) = @parts;
        die "ERROR: illegal character in x coordinate $x"
            unless $x =~ m/^\d+(?:\.\d+)$/;

        die "ERROR: illegal character in y coordinate $y"
            unless $y =~ m/^\d+(?:\.\d+)$/;

        return $class->new(x => $x, y => $y, proj => $nick);
    }

    ();
}

#----------------

sub longitude() {shift->{GP_x}}
sub long()      {shift->{GP_x}}
sub latitude()  {shift->{GP_y}}
sub lat()       {shift->{GP_y}}

sub x()         {shift->{GP_x}}
sub y()         {shift->{GP_y}}

#----------------

sub in($)
{   my ($self, $newproj) = @_;

    # Dirty hacks violate OO, to improve the speed.
    return $self if $newproj eq $self->{G_proj};

    my ($n, $p) = $self->projectOn($newproj, [$self->{GP_x}, $self->{GP_y}]);
    $p ? ref($self)->new(x => $p->[0], y => $p->[1], proj => $n) : $self;
}


sub normalize()
{   my $self = shift;
    my $p    = Geo::Proj->projection($self->proj);
    $p && $p->proj4->isLatlong or return $self;
    my ($x, $y) = @$self{'GP_x','GP_y'};
    $x += 360 while $x < -180;
    $x -= 360 while $x >  180;
    $y += 180 while $y <  -90;
    $y -= 180 while $y >   90;
    @$self{'GP_x','GP_y'} = ($x, $y);
    $self;
}

#----------------

sub bbox() { @{(shift)}[ qw/GP_x GP_y GP_x GP_y/ ] }


sub area() { 0 }


sub perimeter() { 0 }


# When two points are within one UTM zone, this could be done much
# easier...

sub distancePointPoint($$$)
{   my ($self, $geodist, $units, $other) = @_;

    my $here  = $self->in('wgs84');
    my $there = $other->in('wgs84');
    $geodist->distance($units, $here->latlong, $there->latlong);
}


sub sameAs($$)
{   my ($self, $other, $e) = (shift, shift);

    croak "ERROR: can only compare a point to another Geo::Point"
        unless $other->isa('Geo::Point');

    # may be latlong or xy, doesn't matter: $e is corrected for that
    my($x1, $y1) = $self->xy;
    my($x2, $y2) = $other->xy;
    abs($x1-$x2) < $e && abs($y1-$y2) < $e;
}


sub inBBox($)
{   my ($self, $other) = @_;
    my ($x, $y) = $self->in($other->proj)->xy;
    my ($xmin, $ymin, $xmax, $ymax) = $other->bbox;
    $xmin <= $x && $x <= $xmax && $ymin <= $y && $y <= $ymax
}

#----------------

sub coordsUsualOrder()
{   my $self = shift;
    my $p    = Geo::Proj->projection($self->proj);
    $p && $p->proj4->isLatlong ? $self->latlong : $self->xy;
}


sub coords()
{  my ($a, $b) = shift->coordsUsualOrder;
   defined $a && defined $b or return '(none)';

   sprintf "%.4f %.4f", $a, $b;
}


sub toString(;$)
{   my ($self, $proj) = @_;
    my $point;

    if(defined $proj)
    {   $point = $self->in($proj);
    }
    else
    {   $proj  = $self->proj;
        $point = $self;
    }

    "point[$proj](" .$point->coords.')';
}
*string = \&toString;


sub dms(;$)
{   my ($self, $proj) = @_;
    my ($long, $lat)  = $proj ? $self->in($proj)->longlat : $self->longlat;

    my $dmslat  = $self->deg2dms($lat,  'N', 'S');
    my $dmslong = $self->deg2dms($long, 'E', 'W');
    wantarray ? ($dmslat, $dmslong) : "$dmslat, $dmslong";
}


sub dm(;$)
{   my ($self, $proj) = @_;
    my ($long, $lat)  = $proj ? $self->in($proj)->longlat : $self->longlat;

    my $dmlat  = $self->deg2dm($lat,  'N', 'S');
    my $dmlong = $self->deg2dm($long, 'E', 'W');
    wantarray ? ($dmlat, $dmlong) : "$dmlat, $dmlong";
}


sub dmsHTML(;$)
{   my ($self, $proj) = @_;
    my @both = $self->dms($proj);
    foreach (@both)
    {   s/"/\&quot;/g;
        # The following two translations are nice, but IE does not handle
        # them correctly when uses as values in form fields.
        # s/d/\&deg;/g;
        # s/ /\&nbsp;\&nbsp;/g;
    }
    wantarray ? @both : "$both[0], $both[1]";
}


sub dmHTML(;$)
{   my ($self, $proj) = @_;
    my @both = $self->dm($proj);
    foreach (@both)
    {   s/"/\&quot;/g;
        # See dmsHTML above
        # s/d/\&deg;/g;
        # s/ /\&nbsp;\&nbsp;/g;
    }
    wantarray ? @both : "$both[0], $both[1]";
}


sub moveWest()
{   my $self = shift;
    $self->{GP_x} -= 360 if $self->{GP_x} > 0;
}


1;
