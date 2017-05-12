use strict;
use warnings;

use Data::Dumper;
use Test::More;

BEGIN {
      use_ok( "Devel::SimpleProfiler" ) || BAIL_OUT( "Unable to load Devel::SimpleProfiler" );
}

my $funtimes = {
  'foo::bar' => [ 1, 3, 7, 99, 0, 1, ],
  'joe::blo' => [ 2,3,4, ],
  'jaz::waz' => [ 342,2,342,4324,2342 ],
};

my $funcalled = {};

my $funcalls = {};

my $txt = Devel::SimpleProfiler::_analyze( $funtimes, $funcalled, $funcalls, 'total' );

my $exp = '
 performance stats ( all times are in ms)

     sub  | # calls | total t |  mean t |   avg t |   max t |   min t
----------+---------+---------+---------+---------+---------+--------
jaz::waz  |       5 |    7352 |     342 |    1470 |    4324 |       2
foo::bar  |       6 |     111 |       3 |      18 |      99 |       0
joe::blo  |       3 |       9 |       3 |       3 |       4 |       2
';
is( $txt, $exp, "sorted by total" );

$txt = Devel::SimpleProfiler::_analyze( $funtimes, $funcalled, $funcalls, 'calls' );

$exp = '
 performance stats ( all times are in ms)

     sub  | # calls | total t |  mean t |   avg t |   max t |   min t
----------+---------+---------+---------+---------+---------+--------
foo::bar  |       6 |     111 |       3 |      18 |      99 |       0
jaz::waz  |       5 |    7352 |     342 |    1470 |    4324 |       2
joe::blo  |       3 |       9 |       3 |       3 |       4 |       2
';


is( $txt, $exp, "sorted by calls" );

done_testing;
