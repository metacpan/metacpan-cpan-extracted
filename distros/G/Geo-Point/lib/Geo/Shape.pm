# Copyrights 2005-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

use strict;
use warnings;

package Geo::Shape;
use vars '$VERSION';
$VERSION = '0.96';


use Geo::Proj;      # defines wgs84
use Geo::Point      ();
use Geo::Line       ();
use Geo::Surface    ();
use Geo::Space      ();

use Geo::Distance   ();
use Math::Trig      qw/deg2rad/;
use Carp            qw/croak confess/;


use overload '""'     => 'string'
           , bool     => sub {1}
           , fallback => 1;


sub new(@) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;
    my $proj = $self->{G_proj}
      = $args->{proj} || Geo::Proj->defaultProjection->nick;

    croak "proj parameter must be a label, not a Geo::Proj object"
        if UNIVERSAL::isa($proj, 'Geo::Proj');

    $self;
}

#---------------------------

sub proj()  { shift->{G_proj} }
sub proj4() { Geo::Proj->proj4(shift->{G_proj}) }

#---------------------------

sub in($) { croak "ERROR: in() not implemented for a ".ref(shift) }


sub projectOn($@)
{   # fast check: nothing to be done
    return () if @_<2 || $_[0]->{G_proj} eq $_[1];

    my ($self, $projnew) = (shift, shift);
    my $projold = $self->{G_proj};

    return ($projnew, @_)
        if $projold eq $projnew;

    if($projnew eq 'utm')
    {   my $point = $_[0];
        $point   = Geo::Point->xy(@$point, $projold)
            if ref $point eq 'ARRAY';
        $projnew = Geo::Proj->bestUTMprojection($point, $projold)->nick;
        return ($projnew, @_)
            if $projnew eq $projold;
    }

    my $points = Geo::Proj->to($projold, $projnew, \@_);
    ($projnew, @$points);
}

#---------------------------

my $geodist;
sub distance($;$)
{   my ($self, $other, $unit) = (shift, shift, shift);
    $unit ||= 'kilometer';

    unless($geodist)
    {   $geodist = Geo::Distance->new;
        $geodist->formula('hsin');
        $geodist->reg_unit(1 => 'radians');
        $geodist->reg_unit(deg2rad(1) => 'degrees');
        $geodist->reg_unit(km => 1, 'kilometer');
    }

    my $proj = $self->proj;
    $other = $other->in($proj)
        if $other->proj ne $proj;

    if($self->isa('Geo::Point') && $other->isa('Geo::Point'))
    {   return $self->distancePointPoint($geodist, $unit, $other);
    }

    die "ERROR: distance calculation not implemented between a "
      . ref($self) . " and a " . ref($other);
}


sub bboxRing(@)
{   my ($thing, $xmin, $ymin, $xmax, $ymax, $proj) = @_;

    if(@_==1 && ref $_[0])   # instance method without options
    {   $proj  = $thing->proj;
        ($xmin, $ymin, $xmax, $ymax) = $thing->bbox;
    }

    Geo::Line->new   # just a little faster than calling ring()
     ( points    => [ [$xmin,$ymin], [$xmax,$ymin], [$xmax,$ymax]
                    , [$xmin,$ymax], [$xmin,$ymin] ]
     , proj      => $proj
     , ring      => 1
     , bbox      => [$xmin, $ymin, $xmax, $ymax]
     , clockwise => 0
     );
}


sub bbox() { confess "INTERNAL: bbox() not implemented for ".ref(shift) }


sub bboxCenter()
{   my $self = shift;
    my ($xmin, $ymin, $xmax, $ymax) = $self->bbox;
    Geo::Point->xy(($xmin+$xmax)/2, ($ymin+$ymax)/2, $self->proj);
}


sub area() { confess "INTERNAL: area() not implemented for ".ref(shift) }


sub perimeter() { confess "INTERNAL: perimeter() not implemented for ".ref(shift) }


sub deg2dms($$$)
{   my ($thing, $degrees, $pos, $neg) = @_;
    $degrees   -= 360 while $degrees >   180;
    $degrees   += 360 while $degrees <= -180;

    my $sign    = $pos;
    if($degrees < 0)
    {   $sign   = $neg;
        $degrees= -$degrees;
    }

    my $d       = int $degrees;
    my $frac    = ($degrees - $d) * 60;
    my $m       = int($frac + 0.00001);
    my $s       = ($frac - $m) * 60;
    $s = 0 if $s < 0.001;

    my $g       = int($s + 0.00001);
    my $h       = int(($s - $g) * 1000 + 0.0001);
      $h ? sprintf("%dd%02d'%02d.%03d\"$sign", $d, $m, $g, $h)
    : $s ? sprintf("%dd%02d'%02d\"$sign", $d, $m, $g)
    : $m ? sprintf("%dd%02d'$sign", $d, $m)
    :      sprintf("%d$sign", $d);
}


sub deg2dm($$$)
{   my ($thing, $degrees, $pos, $neg) = @_;
    defined $degrees or return '(null)';

    $degrees   -= 360 while $degrees >   180;
    $degrees   += 360 while $degrees <= -180;

    my $sign    = $pos;
    if($degrees < 0)
    {   $sign   = $neg;
        $degrees= -$degrees;
    }

    my $d       = int $degrees;
    my $frac    = ($degrees - $d) * 60;
    my $m       = int($frac + 0.00001);

    $m ? sprintf("%dd%02d'$sign", $d, $m)
       : sprintf("%d$sign", $d);
}


sub dms2deg($)
{  my ($thing, $dms) = @_;

   my $o = 'E';
   $dms =~ s/^\s+//;

      if($dms =~ s/([ewsn])\s*$//i) { $o = uc $1 }
   elsif($dms =~ s/^([ewsn])\s*//i) { $o = uc $1 }

   if($dms =~ m/^( [+-]? \d+ (?: \.\d+)? )   [\x{B0}dD]?
               \s* (?: ( \d+ (?: \.\d+)? )   [\'mM\x{92}]? )?
               \s* (?: ( \d+ (?: \.\d+)? )   [\"sS]? )?
               /xi
     )
   {   my ($d, $m, $s) = ($1, $2||0, $3||0);

       my $deg = ($o eq 'W' || $o eq 'S' ? -1 : 1)
               * ($d + $m/60 + $s/3600);

       return $deg;
   }

   ();
}

1;
