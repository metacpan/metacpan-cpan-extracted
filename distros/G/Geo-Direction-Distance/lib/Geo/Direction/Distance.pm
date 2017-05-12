package Geo::Direction::Distance;

use warnings;
use strict;
use Carp;
use Math::Trig qw(tan);

use version; our $VERSION = qv('0.0.2');

use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT      = qw(latlng2dirdist dirdist2latlng);

my $pi  = 4 * atan2(1,1); 								# PI
my $rd  = $pi / 180;      								# [radian/degree]

# Datum
my %ellps = (
    'MERIT' => {
        a  => 6378137.0,
        rf => 298.257,
    },
    'SGS85' => {
        a  => 6378136.0,
        rf => 298.257,
    },
    'GRS80' => {
        a  => 6378137.0,
        rf => 298.257222101,
    },
    'IAU76' => {
        a  => 6378140.0,
        rf => 298.257,
    },
    'airy' => {
        a  => 6377563.396,
        b  => 6356256.910,
    },
    'APL4.9' => {
        a  => 6378137.0,
        rf => 298.25,
    },
    'NWL9D' => {
        a  => 6378145.0,
        rf => 298.25,
    },
    'mod_airy' => {
        a  => 6377340.189,
        b  => 6356034.446,
    },
    'andrae' => {
        a  => 6377104.43,
        rf => 300.0,
    },
    'aust_SA' => {
        a  => 6378160.0,
        rf => 298.25,
    },
    'GRS67' => {
        a  => 6378160.0,
        rf => 298.2471674270,
    },
    'bessel' => {
        a  => 6377397.155,
        rf => 299.1528128,
    },
    'bess_nam' => {
        a  => 6377483.865,
        rf => 299.1528128,
    },
    'clrk66' => {
        a  => 6378206.4,
        b  => 6356583.8,
    },
    'clrk80' => {
        a  => 6378249.145,
        rf => 293.4663,
    },
    'CPM' => {
        a  => 6375738.7,
        rf => 334.29,
    },
    'delmbr' => {
        a  => 6376428.0,
        rf => 311.5,
    },
    'engelis' => {
        a  => 6378136.05,
        rf => 298.2566,
    },
    'evrst30' => {
        a  => 6377276.345,
        rf => 300.8017,
    },
    'evrst48' => {
        a  => 6377304.063,
        rf => 300.8017,
    },
    'evrst56' => {
        a  => 6377301.243,
        rf => 300.8017,
    },
    'evrst69' => {
        a  => 6377295.664,
        rf => 300.8017,
    },
    'evrstSS' => {
        a  => 6377298.556,
        rf => 300.8017,
    },
    'fschr60' => {
        a  => 6378166.0,
        rf => 298.3,
    },
    'fschr60m' => {
        a  => 6378155.0,
        rf => 298.3,
    },
    'fschr68' => {
        a  => 6378150.0,
        rf => 298.3,
    },
    'helmert' => {
        a  => 6378200.0,
        rf => 298.3,
    },
    'hough' => {
        a  => 6378270.0,
        rf => 297.,
    },
    'intl' => {
        a  => 6378388.0,
        rf => 297.,
    },
    'krass' => {
        a  => 6378245.0,
        rf => 298.3,
    },
    'kaula' => {
        a  => 6378163.0,
        rf => 298.24,
    },
    'lerch' => {
        a  => 6378139.0,
        rf => 298.257,
    },
    'mprts' => {
        a  => 6397300.0,
        rf => 191.,
    },
    'new_intl' => {
        a  => 6378157.5,
        b  => 6356772.2,
    },
    'plessis' => {
        a  => 6376523.0,
        b  => 6355863.0,
    },
    'SEasia' => {
        a  => 6378155.0,
        b  => 6356773.3205,
    },
    'walbeck' => {
        a  => 6376896.0,
        b  => 6355834.8467,
    },
    'WGS60' => {
        a  => 6378165.0,
        rf => 298.3,
    },
    'WGS66' => {
        a  => 6378145.0,
        rf => 298.25,
    },
    'WGS72' => {
        a  => 6378135.0,
        rf => 298.26,
    },
    'WGS84' => {
        a  => 6378137.0,
        rf => 298.257223563,
    },
    'sphere' => {
        a  => 6370997.0,
        b  => 6370997.0,
    },
);

sub dirdist2latlng {
    my ($flat,$flng,$dir,$dist,$opt) = @_;
    my ($a,$f) = set_af($opt);

    return v2p_pp($f,$a,$rd,$flat,$flng,$dir,$dist);
}

sub latlng2dirdist {
    my ($flat,$flng,$tlat,$tlng,$opt) = @_;
    my ($a,$f) = set_af($opt);

    my ($dir, $dist) = p2v_pp($f,$a,$rd,map { $_ * $rd } ($flat,$flng,$tlat,$tlng));

    while ( $dir < 0 || $dir >= 360 ) {
        $dir += $dir < 0 ? 360 : -360;
    }

    return ($dir, $dist);
}

sub set_af {
    my $opt = shift || {};

    my ($a,$f);

    $opt = $ellps{$opt->{ellps}} if ($opt->{ellps});
    $opt = $ellps{WGS84}         if (!$opt->{a} || (!$opt->{b} && !$opt->{f} && !$opt->{rf}) );

    $a   = $opt->{a};
    $f   = $opt->{b}  ? ($a - $opt->{b}) / $a :
           $opt->{rf} ? 1 / $opt->{rf}        :
                        $opt->{f};

    return ($a,$f);
}

# Engine for vector2point
sub v2p_pp{
    my ($f,$a,$rd,$lat,$lng,$dir,$dis) = @_;
    ($lat,$lng,$dir) = map{ $_ * $rd } ($lat,$lng,$dir);						# Change to radian

    my $r  = 1 - $f;
    my $tu = $r * tan($lat);
    my $sf = sin($dir);
    my $cf = cos($dir);
    my $b  = ($cf == 0) ? 0.0 : 2.0 * atan2($tu,$cf);

    my $cu  = 1.0 / sqrt(1 + $tu**2);
    my $su  = $tu * $cu;
    my $sa  = $cu * $sf;
    my $c2a = 1 - $sa**2;
    my $x   = 1.0 + sqrt(1.0 + $c2a * (1.0/($r**2)-1.0));
    $x      = ($x - 2.0) / $x;

    my $c = 1.0 - $x;
    $c    = ($x**2 / 4.0 + 1.0) / $c;
    my $d = (0.375 * $x**2 - 1.0)* $x;
    $tu   = $dis / ($r * $a * $c);
    my $y = $tu;
    $c    = $y + 1;

    my ($sy,$cy,$cz,$e) = ();
    while (abs($y - $c) > 0.00000000005) {
        $sy = sin($y);
        $cy = cos($y);
        $cz = cos($b + $y);
        $e  = 2.0 * $cz**2 -1.0;
        $c  = $y;
        $x  = $e * $cy;
        $y  = $e + $e - 1;
        $y  = ((($sy**2 * 4.0 - 3.0) * $y * $cz * $d / 6.0 + $x) * $d / 4.0 - $cz) * $sy * $d + $tu;
    }
		
    $b       = $cu * $cy * $cf - $su * $sy;
    $c       = $r * sqrt($sa**2 + $b**2);
    $d       = $su * $cy + $cu * $sy * $cf;
    my $rlat = atan2($d,$c);

    $c       = $cu * $cy - $su * $sy * $cf;
    $x       = atan2($sy * $sf, $c); 
    $c       = ((-3.0 * $c2a + 4.0) * $f + 4.0) * $c2a * $f / 16.0;
    $d       = (($e * $cy * $c + $cz) * $sy * $c + $y) * $sa;
    my $rlon = $lng + $x - (1.0 - $c) * $d * $f;

    return map { $_/$rd } ($rlat,$rlon);
}

# Engine for point2vector
sub p2v_pp {
    my ($f,$a,$rd,$lat,$lng,$tlat,$tlng) = @_;

    return (180,0) if (($lat == $tlat) && ($lng == $tlng));

    my $e2 = 2*$f - $f*$f;   								# Square of Eccentricity
    my $r  = 1 - $f;

    my $tu1 = $r * tan($lat);
    my $tu2 = $r * tan($tlat);

    my $cu1 = 1.0 / sqrt(1.0 + $tu1**2);
    my $su1 = $cu1 * $tu1;
    my $cu2 = 1.0 / sqrt(1.0 + $tu2**2); 
    my $s1  = $cu1 * $cu2;
    my $b1  = $s1 * $tu2;
    my $f1  = $b1 * $tu1;
    my $x   = $tlng - $lng;
    my $d   = $x + 1;									# Force one pass

    my $iter =1;
    my ($sx,$cx,$sy,$cy,$y,$sa,$c2a,$cz,$e,$c)=();

    while ((abs($d - $x) > 0.00000000005) && ($iter < 100)) {
        $iter++;
        $sx = sin($x);
        $cx = cos($x);
        $tu1 = $cu2 * $sx;
        $tu2 = $b1 - $su1 * $cu2 * $cx;
        $sy = sqrt($tu1**2 + $tu2**2);
        $cy = $s1 * $cx + $f1;
        $y = atan2($sy,$cy);
        $sa = $s1 * $sx / $sy;
        $c2a = 1 - $sa**2;
        $cz = $f1 + $f1;

        if ($c2a > 0.0) {
            $cz = $cy - $cz / $c2a;
        }

        $e = $cz**2 * 2.0 - 1.0;
        $c = ((-3.0 * $c2a + 4.0) * $f + 4.0) * $c2a * $f / 16.0;
        $d = $x;
        $x = (($e * $cy * $c + $cz) * $sy * $c + $y) * $sa;
        $x = (1.0 - $c) * $x * $f + $tlng - $lng;
    }

    my $dir = atan2($tu1,$tu2) / $rd;
    $x = sqrt((1 / ($r**2) -1) * $c2a +1);
    $x += 1;
    $x = ($x - 2.0) / $x;
    $c = 1.0 - $x;
    $c = ($x**2 / 4.0 + 1.0) / $c;
    $d = (0.375 * $x**2 - 1.0) * $x;
    $x = $e * $cy;
    my $dis = (((($sy**2 * 4.0 - 3.0) * (1.0 - $e - $e) * $cz * $d / 6.0 - $x) * $d / 4.0 + $cz) * $sy * $d + $y) * $c * $a * $r;
  
    return ($dir,$dis);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Direction::Distance - Process between Lat-Lng coordinates and direction - distance


=head1 SYNOPSIS

  use Geo::Direction::Distance;
  # Export two functions, dirdist2latlng and latlng2dirdist.
  
  # Calcurate direction/distance from two coordinates (in wgs84 ellipsoid,degree format)
  # Return values are direction (0-360 degree format), distance [m unit].
  my @fromlatlng  = (35.000,135.000);
  my @tolatlng    = (36.000,136.000);
  my ($dir,$dist) = latlng2dirdist(@fromlatlng,@tolatlng);
  
  # Calcurate coordinate from one coordinate and direction, distance.
  # Return values are direction (0-360 degree format), distance [m unit].
  my @fromlatlng  = (35.000,135.000);
  my ($dir,$dist) = (270.000,5000.00);
  my @tolatlng    = dirdist2latlng(@fromlatlng,$dir,$dist);
  
  # If you want to use other ellipsoid, you can set ellipsoid name as option.
  my ($dir,$dist) = latlng2dirdist(@fromlatlng,@tolatlng,{ellps => clrk66});
  
  # You can also set original ellipsoid parameter.
  # parameter keys are same with proj4.
  my @tolatlng    = dirdist2latlng(@fromlatlng,$dir,$dist,{a => 6378165.0, rf => 298.3});


=head1 EXPORT METHODS

=over

=item * dirdist2latlng

=item * latlng2dirdist

=back


=head1 INTERNAL METHODS

=over

=item * p2v_pp

=item * set_af

=item * v2p_pp

=back


=head1 TODO

=over

=item Get ellipsoid information from Geo::Proj4, Geo::Proj or Geo::Shape object.

=item Can accept other distance unit 

=back


=head1 DEPENDENCIES

Math::Trig


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
