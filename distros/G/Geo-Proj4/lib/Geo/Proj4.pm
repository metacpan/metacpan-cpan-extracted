# Copyrights 2017 by [Mark Overmeer].
#  For other contributors see Changes.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
package Geo::Proj4;
use vars '$VERSION';
$VERSION = '1.06';


use strict;
use warnings;
#our $VERSION = '0.96';

use base 'DynaLoader';

use Scalar::Util   qw/dualvar/;
use Carp           qw/croak/;

# The library definitions
bootstrap Geo::Proj4; # $VERSION;


my $last_error;

sub new($@)
{   my $class = shift;

    my $def;
    if(@_==1)
    {   $def = shift;
    }
    else
    {   my @args;
        while(@_)
        {   my ($key, $val) = (shift, shift);
            push @args, "+$key".(defined $val ? "=$val" : '');
	}
        $def = join ' ', @args;
    }

    my ($self, $error, $errtxt) = new_proj4($def);

    defined $self
        or $last_error = dualvar($error, $errtxt);

    $self;
}

#--------------

sub error() { $last_error }


sub normalized()
{   my $norm = normalized_proj4(shift);
    $norm =~ s/^\s+//;
    $norm;
}


sub datum()
{   my $norm = shift->normalized;
    $norm =~ m/\+datum\=(w+)/ ? $1 : undef;
}


sub projection()
{   my $norm = shift->normalized;
    $norm =~ m/\+proj\=(\w+)/ ? $1 : undef;
}


sub dump() { dump_proj4(shift) }


sub isLatlong()  { is_latlong_proj4(shift) }
sub isGeodesic() { is_latlong_proj4(shift) }


sub isGeocentric() { is_geocentric_proj4(shift) }


sub hasInverse() { has_inverse_proj4(shift) }

#--------------

sub forward($$)
{   my ($self, $lat, $long) = @_;
    forward_degrees_proj4($self, $lat, $long);
}


sub forwardRad($$)
{   my ($self, $lat, $long) = @_;
    forward_proj4($self, $lat, $long);
}


sub inverse($$) { inverse_degrees_proj4(@_) }


sub inverseRad($$) { inverse_proj4(@_) }


sub transform($$)
{   my ($self, $to, $points) = @_;

    ref $points eq 'ARRAY'
        or croak "ERROR: transform() expects array of points";

    my ($err, $errtxt, $pr);
    if(ref($points->[0]) eq 'ARRAY')
    {   ($err, $errtxt, $pr) = transform_proj4($self, $to, $points, 1);
    }
    else
    {   ($err, $errtxt, $pr) = transform_proj4($self, $to, [$points], 1);
        $pr = $pr->[0] if $pr;
    }

    $last_error = dualvar $err, $errtxt;
    $err ? () : $pr;
}


sub transformRad($$)
{   my ($self, $to, $points) = @_;

    ref $points eq 'ARRAY'
        or croak "ERROR: transformRad() expects array of points";

    my ($err, $errtxt, $pr);
    if(ref($points->[0]) eq 'ARRAY')
    {   ($err, $errtxt, $pr) = transform_proj4($self, $to, $points, 0);
    }
    else
    {   ($err, $errtxt, $pr) = transform_proj4($self, $to, [$points], 0);
        $pr = $pr->[0] if $pr;
    }

    $last_error = dualvar $err, $errtxt;
    $err ? () : $pr;
}

sub AUTOLOAD(@)
{   our $AUTOLOAD;
    die "$AUTOLOAD not implemented";
}

#--------------

sub libVersion()
{   my $version = libproj_version_proj4();
    $version =~ s/./$&./g;
    $version;
}


sub listTypes() { &def_types_proj4 }


sub typeInfo($)
{   my $label = $_[1];
    my %def = (id => $label);
    my($descr) = type_proj4($label);
    $def{has_inverse} = not ($descr =~ s/(?:\,?\s+no\s+inv\.?)//);
    $def{description} = $descr;
    \%def;
}


sub listEllipsoids() { &def_ellps_proj4 }


sub ellipsoidInfo($)
{   my $label = $_[1];
    my %def = (id => $label);
    @def{ qw/major ell name/ } = ellps_proj4($label);
    \%def;
}


sub listUnits() { &def_units_proj4 }


sub unitInfo($)
{   my $label = $_[1];
    my %def = (id => $label);
    @def{ qw/to_meter name/ } = unit_proj4($label);
    $def{to_meter} =~ s!^1\.?/(.*)!1/$1!e;  # 1/2 -> 0.5
    \%def;
}


sub listDatums() { &def_datums_proj4 }


sub datumInfo($)
{   my $label = $_[1];
    my %def = (id => $label);
    @def{ qw/ellipse_id definition comments/ } = datum_proj4($label);
    \%def;
}

#--------------

# more text in PODTAIL.txt

1;
