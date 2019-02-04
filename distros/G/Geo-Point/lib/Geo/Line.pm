# Copyrights 2005-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Geo-Point.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Geo::Line;
use vars '$VERSION';
$VERSION = '0.98';

use base qw/Geo::Shape Math::Polygon/;

use strict;
use warnings;

use Carp;
use List::Util    qw/min max/;
use Scalar::Util  qw/refaddr/;


sub new(@)
{   my ($thing, %args) = @_;
    if(my $points = $args{points})
    {   @$points >= 2
            or croak "ERROR: line needs at least two points";

        my $proj = $args{proj};
        foreach my $p (@$points)
        {   next unless UNIVERSAL::isa($p, 'Geo::Point');
            $proj ||= $p->proj;
            $p      = [ $p->xy($proj) ];   # replace
        }
        $args{proj} = $proj;
    }

    ref $thing
        or return shift->Math::Polygon::new(%args);

    # instance method: clone!
    $thing->Math::Polygon::new
      ( ring   => $thing->{GL_ring}
      , filled => $thing->{GL_fill}
      , proj   => $thing->proj
      , %args
      );
}

sub init($)
{   my ($self, $args) = @_;
    $self->Geo::Shape::init($args);

    $self->Math::Polygon::init($args);

    $self->{GL_ring} = $args->{ring} || $args->{filled};
    $self->{GL_fill} = $args->{filled};
    $self->{GL_bbox} = $args->{bbox};
    $self;
}


sub line(@)
{   my $thing = shift;
    my @points;
    push @points, shift while @_ && ref $_[0];
    $thing->new(points => \@points, @_);
}


sub ring(@)
{   my $thing  = shift;
    my $self   = $thing->line(@_, ring => 1);
    my $points = $self->points;

    my ($first, $last) = @$points[0, -1];
    push @$points, $first
        unless $first->[0] == $last->[0] && $first->[1] == $last->[1];
    $self;
}


sub filled(@)
{   my $thing = shift;
    $thing->ring(@_, filled => 1);
}


sub bboxFromString($;$)
{   my ($class, $string, $nick) = @_;

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return () unless length $string;

    # line starts with project label
    $nick = $1 if $string =~ s/^(\w+)\s*\:\s*//;

    # Split the line
    my @parts = $string =~ m/\,/ ? split(/\s*\,\s*/, $string) : ($string);

    # expand dashes
    @parts = map { m/^([nesw])(\d.*?)\s*\-\s*(\d.*?)\s*$/i ?    ($1.$2, $1.$3)
                 : m/^(\d.*?)([nesw])\s*\-\s*(\d.*?)\s*$/i ?    ($2.$1, $2.$3)
                 : m/^(\d.*?)\s*\-\s*(\d.*?)\s*([nesw])\s*$/i ? ($1.$3, $2.$3)
                 : $_
                 } @parts;

    # split on blanks
    @parts = map { split /\s+/, $_ } @parts;

    # Now, the first word may be a projection.  That is: any non-coordinate,
    # anything which starts with more than one letter.
    if($parts[0] =~ m/^[a-z_]{2}/i)
    {   $nick = lc(shift @parts);   # overrules default
    }

    $nick  ||= Geo::Proj->defaultProjection;
    my $proj = Geo::Proj->projection($nick);

    die "ERROR: Too few values in $string (got @parts, expect 4)\n"
       if @parts < 4;

    die "ERROR: Too many values in $string (got @parts, expect 4)"
       if @parts > 4;

    unless($proj)
    {   die "ERROR: No projection defined for $string\n";
        return undef;
    }

    if(! $proj->proj4->isLatlong)
    {   die "ERROR: can only handle latlong coordinates, on the moment\n";
    }

    my(@lats, @longs);
    foreach my $part (@parts)
    {   if($part =~ m/[ewEW]$/ || $part =~ m/^[ewEW]/)
        {   my $lat = $class->dms2deg($part);
            defined $lat
               or die "ERROR: dms latitude coordinate not understood: $part\n";
            push @lats, $lat;
        }
        else
        {   my $long = $class->dms2deg($part);
            defined $long
               or die "ERROR: dms longitude coordinate not understood: $part\n";
            push @longs, $long;
        }
    }

    die "ERROR: expect two lats and two longs, but got "
      . @lats."/".@longs."\n"  if @lats!=2;

    (min(@lats), min(@longs), max(@lats), max(@longs), $nick);
}



sub ringFromString($;$)
{   my $class = shift;
    my ($xmin, $ymin, $xmax, $ymax, $nick) = $class->bboxFromString(@_)
        or return ();

    $class->bboxRing($xmin, $ymin, $xmax, $ymax, $nick);
}

#------------

sub geopoints()
{   my $self = shift;
    my $proj = $self->proj;

    map { Geo::Point->new(x => $_->[0], y => $_->[1], proj => $proj) }
        $self->points;
}


sub geopoint(@)
{   my $self = shift;
    my $proj = $self->proj;

    unless(wantarray)
    {   my $p = $self->point(shift) or return ();
        return Geo::Point->(x => $p->[0], y => $p->[1], proj => $proj);
    }

    map { Geo::Point->(x => $_->[0], y => $_->[1], proj => $proj) }
       $self->point(@_);

}


sub isRing()
{   my $self = shift;
    return $self->{GL_ring} if defined $self->{GL_ring};

    my ($first, $last) = $self->points(0, -1);
    $self->{GL_ring}  = ($first->[0]==$last->[0] && $first->[1]==$last->[1]);
}


sub isFilled() { shift->{GL_fill} }

#----------------

sub in($)
{   my ($self, $projnew) = @_;
    return $self if ! defined $projnew || $projnew eq $self->proj;

    # projnew can be 'utm'
    my ($realproj, @points) = $self->projectOn($projnew, $self->points);

    @points ? $self->new(points => \@points, proj => $realproj) : $self;
}

#----------------

sub equal($;$)
{   my $self  = shift;
    my $other = shift;

    return 0 if $self->nrPoints != $other->nrPoints;

    $self->Math::Polygon::equal($other->in($self->proj), @_);
}


sub bbox() { shift->Math::Polygon::bbox }


sub area()
{   my $self = shift;

    croak "ERROR: area requires a ring of points"
       unless $self->isRing;

    $self->Math::Polygon::area;
}


sub perimeter()
{   my $self = shift;

    croak "ERROR: perimeter requires a ring of points."
       unless $self->isRing;

    $self->Math::Polygon::perimeter;
}


sub length() { shift->Math::Polygon::perimeter }


sub clip(@)
{   my $self  = shift;
    my $proj  = $self->proj;
    my @bbox  = @_==1 ? $_[0]->bbox : @_;
    $self->isFilled ? $self->fillClip1(@bbox) : $self->lineClip(@bbox);
}

#----------------

sub toString(;$)
{   my ($self, $proj) = @_;
    my $line;
    if(defined $proj)
    {   $line = $self->in($proj);
    }
    else
    {   $proj = $self->proj;
        $line = $self;
    }

    my $type  = $line->isFilled ? 'filled'
              : $line->isRing   ? 'ring'
              :                   'line';

    "$type\[$proj](".$line->Math::Polygon::string.')';
}
*string = \&toString;

1;
