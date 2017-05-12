use Test::Simple tests => 9;

use Language::Homespring;
require "t/harness.inc";

#
# powers
# Generates electricity for everything downstream of the 'powers' node
#
 
ok(test_hs_return("bear hatchery foo  powers", ['','','','foo','foo','foo']));
ok(test_hs_return("bear hatchery foo", ['','','','','','','']));
ok(test_hs_return("bear hatchery foo  powers marshy snowmelt", ['','','','foo','foo','','','']));

#
# hydro power
# Generates electricity only when supplied with water. This can be destroyed by snowmelt
#

ok(test_hs_return("bear hatchery foo  hydro. power", ['','','','','']));
ok(test_hs_return("bear hatchery foo  hydro. power bar", ['','','','foo','foo','foo']));
ok(test_hs_return("bear hatchery foo  hydro. power bar  marshy snowmelt", ['','','','foo','foo','','','']));

#
# power invert
# Blocks electricity; generates electricity when not powered. This can be destroyed by snowmelt.
#

ok(test_hs_return("bear hatchery foo  power. invert", ['','','','foo','foo','foo']));
ok(test_hs_return("bear hatchery foo  power. invert powers", ['','','','','']));
ok(test_hs_return("bear hatchery foo  power. invert marshy snowmelt", ['','','','foo','foo','','']));

