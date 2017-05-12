use Test::Simple tests => 4;

use Language::Homespring;
require "t/harness.inc";

#
# bear
# Eats mature salmon.
#
 
ok(test_hs_return("bar hatchery foo  powers", ['','','','homelessfoo','homelessfoo']));
ok(test_hs_return("bear hatchery foo  powers", ['','','','foo','foo']));

#
# young bear
# Like a bear, but only kills every other mature fish.
#

ok(test_hs_return("young. bear hatchery foo  powers", ['','','','foo','homelessfoo','foo','homelessfoo']));

#
# bird
# Like a bear, but kills young fish.
#

ok(test_hs_return("bird hatchery foo  powers", ['','','','homeless','homeless']));
