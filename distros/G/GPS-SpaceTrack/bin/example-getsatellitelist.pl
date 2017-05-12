#!/usr/bin/perl -w

=head1 NAME

example-getsatellitelist.pl - GPS::SpaceTrack getsatellitelist method example

=cut

use strict;
use lib qw{./lib ../lib};
use GPS::SpaceTrack;

my $lat=shift()||38.870997;    #degrees
my $lon=shift()||-77.05596;    #degrees
my $hae=shift()||13;           #meters

my $filename="";
$filename="../doc/gps.tle" if -r "../doc/gps.tle";
$filename="./doc/gps.tle" if -r "./doc/gps.tle";
$filename="./gps.tle" if -r "./gps.tle";
$filename="../gps.tle" if -r "../gps.tle";
$filename="../../gps.tle" if -r "../../gps.tle";

my $obj=GPS::SpaceTrack->new(filename=>$filename) || die();

my $i=0;
print join("\t", qw{Count PRN ELEV Azim SNR USED}), "\n";
foreach ($obj->getsatellitelist({lat=>$lat, lon=>$lon, alt=>$hae})) {
  print join "\t", ++$i,
                   $_->prn,
                   sprintf("%0.2f", $_->elev),
                   sprintf("%0.2f", $_->azim),
                   sprintf("%0.2f", $_->snr),
                   $_->used;
  print "\n";
}

__END__

=head1 SAMPLE OUTPUT

  Count PRN     ELEV    Azim    SNR     USED
  1     22      70.58   328.81  40.03   1
  2     18      65.94   102.37  37.52   1
  3     14      46.89   280.48  23.99   1
  4     09      40.82   49.97   19.23   1
  5     15      40.75   196.72  19.17   1
  6     121     38.85   144.56  17.71   1
  7     05      24.55   116.73  7.77    0
  8     21      23.25   180.50  7.01    0
  9     135     17.73   246.95  4.17    0
  10    120     13.49   108.81  2.45    0
  11    30      13.08   146.78  2.30    0
  12    122     10.85   253.59  1.59    0
  13    01      6.67    259.68  0.61    0
  14    31      5.83    211.34  0.46    0
  15    19      2.42    288.94  0.08    0
  16    25      -2.55   216.77  0.00    0
  17    26      -4.45   71.53   0.00    0
  18    03      -5.32   263.07  0.00    0
  19    11      -7.68   332.60  0.00    0
  20    124     -11.96  80.61   0.00    0
  21    29      -12.30  75.62   0.00    0
  22    07      -17.12  168.81  0.00    0
  23    28      -17.55  0.20    0.00    0
  24    126     -17.82  82.21   0.00    0
  25    06      -17.88  163.98  0.00    0
  26    17      -18.51  33.75   0.00    0
  27    134     -19.64  279.38  0.00    0
  28    10      -32.01  126.62  0.00    0
  29    16      -33.80  223.76  0.00    0
  30    24      -34.17  143.09  0.00    0
  31    20      -41.60  301.78  0.00    0
  32    137     -41.94  304.95  0.00    0
  33    12      -43.95  262.53  0.00    0
  34    129     -44.54  309.68  0.00    0
  35    23      -53.46  240.32  0.00    0
  36    02      -55.24  115.83  0.00    0
  37    08      -58.84  16.24   0.00    0
  38    04      -65.14  58.87   0.00    0
  39    13      -72.84  206.34  0.00    0
  40    27      -75.81  4.22    0.00    0

=cut
