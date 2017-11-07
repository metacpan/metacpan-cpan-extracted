# Toby Thurston -- 24 Sep 2015 
# test map finding

use Geo::Coordinates::OSGB::Grid qw/
   parse_grid 
   format_grid_trad 
   format_grid_landranger
   format_grid_map 
   parse_landranger_grid
   parse_map_grid/;

use Test::More tests => 18;
#
# test for some edge conditions first
my ($sq, $e, $n, @sheets) = format_grid_landranger(320000,305000); # NE corner of Sheep 136
ok( $sq eq 'SJ' &&  $e == 200 && $n == 50, "$sq $e $n @sheets" );
my $f = format_grid_trad(parse_landranger_grid($sheets[0],sprintf("%03d",$e),sprintf("%03d",$n)));
ok( 'SJ 200 050' eq $f, $f);

($sq, $e, $n, @sheets) = format_grid_landranger(280000,265000); # SW corner of Sheep 136
ok( $sq eq 'SN' &&  $e == 800 && $n == 650, "$sq $e $n @sheets" );
$f = format_grid_trad(parse_landranger_grid($sheets[1],sprintf("%03d",$e),sprintf("%03d",$n)));
ok( 'SN 800 650' eq $f, $f);

my ($pt, $s, $t);

$pt = format_grid_trad(parse_map_grid('C:158',653,950));
ok("$pt" eq 'SU 653 950', "Point $pt");

$pt = format_grid_trad(parse_map_grid('B:OL1E','299009'));
ok("$pt" eq 'SE 299 009', "Point $pt");

$s = join ' ', format_grid_map(parse_grid("TQ 102 606"));
$t = 'TQ 102 606 A:176 A:187 B:161 C:170';
ok($s eq $t, "$s  ??  $t");

$s = format_grid_map(parse_grid("SP 516 066"));
ok($s eq 'SP 516 066 on A:164, B:180E, C:158', $s);

$s = format_grid_map(parse_grid("NN 241 738"));
ok($s eq "NN 241 738 on A:41, B:392, C:47, H:105, J:112", $s);

$s = format_grid_map(parse_grid("SU 029 269"));
ok($s eq 'SU 029 269 on A:184, B:118N, B:130S, C:167', $s);

is(format_grid_map(parse_grid("ST 889 933")),
'ST 889 933 on A:162, A:163, A:173, B:168, C:156, C:157',
'Tetbury Museum');

is(format_grid_map(406000, 130000), 'SU 060 300 on A:184, B:130S, C:167', 'Points on upper right edges not on map');
is(format_grid_map(383000, 110000),
'ST 830 100 on A:194, B:118N, C:178', 
'Points on lower left edges are included');

# now test some extensions
is(format_grid_map(432100, 405900),
'SE 321 059 on A:110, A:111, B:278N, B:OL1E, C:102', 
'Junction 37 on the M1 shown on OL1E in an extension');
is(format_grid_map(432100, 403900),
'SE 321 039 on A:110, A:111, B:278N, C:102', 
'but 2km due S of J37 is not on the extension area on OL1E');

use Geo::Coordinates::OSGB::Maps qw/%name_for_map_series/;
is($name_for_map_series{'A'}, 'OS Landranger', "Series A == OS Landranger");
is($name_for_map_series{'B'}, 'OS Explorer',   "Series B == OS Explorer");
is($name_for_map_series{'C'}, 'OS One-Inch 7th series',   "Series C == OS One-Inch");
