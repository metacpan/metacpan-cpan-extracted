# Copyrights 2005-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

use strict;
use warnings;

package Geo::Proj;
use vars '$VERSION';
$VERSION = '0.96';


use Geo::Proj4   ();
use Carp         qw/croak/;


use overload '""'     => sub { shift->nick }
           , fallback => 1;


sub import()
{
  Geo::Proj->new
   ( nick  => 'wgs84'
   , proj4 => '+proj=latlong +datum=WGS84 +ellps=WGS84'
   );
}


my %projections;
my $defproj;

sub new(@)
{   my ($class, %args) = @_;
    my $proj   = $projections{$args{nick} || 'dead'};
    return $proj if defined $proj;

    my $self   = (bless {}, $class)->init(\%args);
    $projections{$self->nick} = $self;
    $defproj ||= $self;
    $self;
}

sub init($)
{   my ($self, $args) = @_;

    my $nick = $self->{GP_nick} = $args->{nick}
        or croak "ERROR: nick required";

    $self->{GP_srid} = $args->{srid};

    my $proj4 = $args->{proj4}
        or croak "ERROR: proj4 parameter required";

    if(ref $proj4 eq 'ARRAY')
    {   $proj4   = Geo::Proj4->new(@$proj4);
        croak "ERROR: cannot create proj4: ".Geo::Proj4->error
            unless $proj4;
    }
    elsif(!ref $proj4)
    {   $proj4   = Geo::Proj4->new($proj4);
        croak "ERROR: cannot create proj4: ".Geo::Proj4->error
            unless $proj4;
    }
    $self->{GP_proj4} = $proj4;
    $self->{GP_name}  = $args->{name};
    $self;
}


sub nick() {shift->{GP_nick}}


sub name()
{   my $self = shift;
    my $name = $self->{GP_name};
    return $name if defined $name;

    my $proj = $self->proj4;
    my $abbrev = $proj->projection
       or return $self->{nick};

    my $def    = $proj->type($abbrev);
    $def->{description};
}


sub proj4(;$)
{   my $thing = shift;
    return $thing->{GP_proj4} unless @_;

    my $proj  = $thing->projection(shift) or return undef;
    $proj->proj4;
}


sub srid() {shift->{GP_srid}}


sub projection($)
{   my $which = $_[1];
    UNIVERSAL::isa($which, __PACKAGE__) ? $which : $projections{$which};
}


sub defaultProjection(;$)
{   my $thing = shift;
    if(@_)
    {   my $proj = shift;
        $defproj = ref $proj ? $proj : $thing->projection($proj);
    }
    $defproj;
}


sub listProjections() { sort keys %projections }


sub dumpProjections(;$)
{   my $class = shift;
    my $fh    = shift || select;

    my $default = $class->defaultProjection;
    my $defnick = defined $default ? $default->nick : '';

    foreach my $nick ($class->listProjections)
    {   my $proj = $class->projection($nick);
        my $name = $proj->name;
        my $norm = $proj->proj4->normalized;
        $fh->print("$nick: $name".($defnick eq $nick ? ' (default)':'')."\n");
        $fh->print("    $norm\n") if $norm ne $name;
    }
}


sub to($@)
{   my $thing   = shift;
    my $myproj4 = ref $thing ? $thing->proj4 : __PACKAGE__->proj4(shift);
    my $toproj4 = __PACKAGE__->proj4(shift);
    $myproj4->transform($toproj4, shift);
}


# These methods may have been implemented in Geo::Point, however may get
# supported by any external library later.  Knowledge about projections
# is as much as possible concentrated here.


sub zoneForUTM($)
{   my ($thing, $point) = @_;
    my ($long, $lat) = $point->longlat;

    my $zone
     = ($lat >= 56 && $lat < 64)
     ? ( $long <  3   ? undef
       : $long < 12   ? 32
       :                undef
       )
     : ($lat >= 72 && $lat < 84)
     ? ( $long <  0   ? undef
       : $long <  9   ? 31
       : $long < 21   ? 33
       : $long < 33   ? 35
       : $long < 42   ? 37
       :                undef
       )
     : undef;

    my $meridian = int($long/6)*6 + ($long < 0 ? -3 : +3);
    $zone      ||= int(($meridian+180)/6) +1;
 
    my $letter
     = ($lat < -80 || $lat > 84) ? ''
     : ('C'..'H', 'J'..'N', 'P'..'X', 'X')[ ($lat+80)/8 ];

      wantarray     ? ($zone, $letter, $meridian)
    : defined $zone ? "$zone$letter"
    : undef;
}


sub bestUTMprojection($;$)
{   my ($thing, $point) = (shift, shift);
    my $proj  = @_ ? shift : $point->proj;

    my ($zone, $letter, $meridian) = $thing->zoneForUTM($point);
    $thing->UTMprojection($proj, $zone);
}


sub UTMprojection($$)
{   my ($class, $base, $zone) = @_;

    $base   ||= $class->defaultProjection;
    my $datum = UNIVERSAL::isa($base, __PACKAGE__) ? $base->proj4->datum :$base;
    $datum  ||= 'wgs84';

    my $label = "utm$zone-\L$datum\E";
    my $proj  = "+proj=utm +zone=$zone +datum=\U$datum\E"
              . " +ellps=\U$datum\E +units=m +no_defs";

    Geo::Proj->new(nick => $label, proj4 => $proj);
}

1;
