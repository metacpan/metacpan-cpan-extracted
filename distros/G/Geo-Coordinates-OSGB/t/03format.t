use strict;
use warnings;

use Test::More tests => 24;

use Geo::Coordinates::OSGB qw /ll_to_grid/;
use Geo::Coordinates::OSGB::Grid qw/
  format_grid_trad
  format_grid_GPS
  format_grid_map
  format_grid_landranger
  format_grid
  /;

is(format_grid(0,0),   "SV 000 000",     "False origin");
is(format_grid(-1,-1), "WE 999 999",     "SW of False origin");

my ($ss, $ee, $nn) = format_grid(12345,67890);
is("$ss $ee $nn", "SV 123 678", "format_grid in list context");
($ss, $ee, $nn) = format_grid_GPS(12345,67890);
is("$ss $ee $nn", "SV 12345 67890", "format_grid_GPS in list context");

is(format_grid_trad(0,0),   "SV 000 000",     "False origin trad");
is(format_grid_trad(-1,-1), "WE 999 999",     "SW of False origin trad");

is(format_grid_GPS(0,0),    "SV 00000 00000", "False origin GPS");
is(format_grid_GPS(-1,-1),  "WE 99999 99999", "SW of False origin GPS");

# Rockall
my ($e, $n) = ll_to_grid(57.596304, -13.687308);
is(format_grid_trad($e, $n), 'MC 035 165', 'Rockall');

# OSHQ
$e = 438710.908;
$n = 114792.248;
is(format_grid($e, $n),                                              'SU 387 147',                               "format_grid with defaults");    
is(format_grid($e, $n, {form => 'SS EEE NNN', maps => 0, series => 'ABCHJ'}), 'SU 387 147',                      "format_grid with defaults");    
is(format_grid($e, $n, {form => 'SS'}),                              'SU',                                       "format_grid with SS");          
is(format_grid($e, $n, {form => 'SSEN'}),                            'SU31',                                     "format_grid with SSEN");          
is(format_grid($e, $n, {form => 'ss eee nnn'}),                      'SU 387 147',                               "format_grid with SS EEE NNN");    
is(format_grid($e, $n, {form => 'trad'}),                            'SU 387 147',                               "format_grid with trad");          
is(format_grid($e, $n, {form => 'gps' }),                            'SU 38710 14792',                           "format_grid with gps");           
is(format_grid($e, $n, {form => 'gps', maps => 1 }),                 'SU 38710 14792 on A:196, B:OL22E, C:180',  "format_grid with map");           
is(format_grid($e, $n, {form => 'trad', maps => 1, series => 'B'}),  'SU 387 147 on B:OL22E',                    "format_grid with map + options"); 
is(sprintf('GR %2$s %3$s on Sheet %4$s', format_grid_landranger($e, $n)),  
           'GR 387 147 on Sheet 196',               "format_grid with map + options"); 

$e = 132508;
$n = 830205;
is(format_grid_map($e, $n), 'NG 325 302 on A:32, B:410, B:411, C:33', 'format_grid_map');
is(format_grid_map($e, $n, { form => 'gps', series => 'B' }), 'NG 32508 30205 on B:410, B:411', 'format_grid_map + options');
is(format_grid_landranger($e, $n), 'NG 325 302 on Landranger sheet 32', 'format_grid_landranger');

# Rocky Point beach
$e = $n = 500025;
is(format_grid($e, $n, {form => 'SSEENN'}), 'OV0000', 'Rocky Point beach');

my @sheets;
($ss, $ee, $nn, @sheets) = format_grid_map(209300,887900, {series => 'H'});
my $gr = sprintf "%s %03d %03d", $ss, $ee, $nn;

use Geo::Coordinates::OSGB::Maps qw/%maps %name_for_map_series/;
my $m = $sheets[0];
my $title = $maps{$m}->{title};
is("An Teallach is at $gr on the $title sheet of the $name_for_map_series{H} series", 
   "An Teallach is at NH 093 879 on the Torridon & Fisherfield sheet of the Harvey British Mountain Maps series", "Harveys");

