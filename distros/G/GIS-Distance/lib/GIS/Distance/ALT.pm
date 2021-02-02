package GIS::Distance::ALT;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use parent 'GIS::Distance::Formula';

use Math::Trig qw( deg2rad acos pi );
use GIS::Distance::Constants qw( :all );
use namespace::clean;

my $DEG_RADS = pi / 180;

# Sphere with equal meridian length
my $RM = 6367449.14582342;

# WGS 84 Ellipsoid
my $A = 6378137;
my $B = 6356752.314245;
my $F = 1 / 298.257223563;

sub _distance {
    my ($lat1, $lon1, $lat2, $lon2) = @_;

    my $f = 0.5 * ($lat2 + $lat1) * $DEG_RADS;
    my $g = 0.5 * ($lat2 - $lat1) * $DEG_RADS;
    my $l = 0.5 * ($lon2 - $lon1) * $DEG_RADS;

    my $sf = sin($f); my $sg = sin($g); my $sl = sin($l);
    my $s2f = $sf * $sf; my $s2g = $sg * $sg; my $s2l = $sl * $sl;
    my $c2f = 1.0 - $s2f; my $c2g = 1.0 - $s2g; my $c2l = 1.0 - $s2l;

    my $s2 = $s2g * $c2l + $c2f * $s2l;
    my $c2 = $c2g * $c2l + $s2f * $s2l;

    my ($s, $c, $omega, $rr, $aa, $bb, $pp, $qq, $d2, $qp, $eps1, $eps2);

    return 0 if $s2 == 0;
    return pi * $RM * 0.001 if $c2 == 0;

    $s = sqrt($s2); $c = sqrt($c2);
    $omega = atan2($s, $c);
    $rr = $s * $c;
    $aa = $s2g * $c2f / $s2 + $s2f * $c2g / $c2;
    $bb = $s2g * $c2f / $s2 - $s2f * $c2g / $c2;
    $pp = $rr / $omega;
    $qq = $omega / $rr;
    $d2 = $s2 - $c2;
    $qp = $qq + 6 * $pp;
    $eps1 = 0.5 * $F * (-$aa - 3 * $bb * $pp);
    $eps2 = 0.25 * $F * $F * ((-$qp * $bb + (-3.75 + $d2 * ($qq + 3.75 * $pp)) *
            $aa + 4. - $d2 * $qq) * $aa - (7.5 * $d2 * $bb * $pp - $qp) * $bb);

    my $d = 2 * $omega * $A * (1 + $eps1 + $eps2);
    return $d * 0.001;
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::ALT - Andoyer-Lambert-Thomas distance calculations.

=head1 DESCRIPTION

The ALT formula is intended as a much faster, but slightly less accurate,
alternative of the L<GIS::Distance::Vincenty> formula. This formulas is
about 5x faster than Vincenty.

The code for this formula was taken from L<Geo::Distance::XS> and
modified to fit.

A faster (XS) version of this formula is available as
L<GIS::Distance::Fast::ALT>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

