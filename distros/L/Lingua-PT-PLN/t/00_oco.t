# -*- cperl -*-

use Test::More tests => 11;
use Lingua::PT::PLN;

my %o = oco({from=>"file"},"t/00_oco.ex");

is( $o{primeiro}  , 5   ,"oco from file");
is( $o{dos}       , 38  ,"oco from file");
is( $o{"roll-off"}, 2   ,"oco from file");

%o = oco({from=>"string"},
          "era era era uma vez, lindo um gato maltês, um lindo gato");

is( $o{era}       , 3  ,"oco from string");
is( $o{uma}       , 1  ,"oco from string");
is( $o{vez}       , 1  ,"oco from string");
is( $o{lindo}     , 2  ,"oco from string");
is( $o{um}        , 2  ,"oco from string");
is( $o{gato}      , 2  ,"oco from string");
is( $o{"maltês"}  , 1  ,"oco from string");
is( $o{rum}       , undef  ,"oco from string");


1;
