use Test::More 'no_plan';

use List::Maker::OtherModule;
use List::Maker;

# INCLUSIVE...

is_deeply [<1..10>],  [1,2,3,4,5,6,7,8,9,10]     => '<1..10>';
is_deeply [<9.9..1.1>], [map { 10-$_+0.9 } 1..9] => '<9.9..1.1>';

ok List::Maker::OtherModule::_regular_glob()     => 'Ignored in other modules';
ok main::_regular_glob()                         => 'Ignored in other files';

package Elsewhere;

my @data = <1..10>;
::ok @data != 10, 'Ignored in other packages';

