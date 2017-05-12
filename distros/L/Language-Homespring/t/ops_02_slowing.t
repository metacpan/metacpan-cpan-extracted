use Test::Simple tests => 5;

use Language::Homespring;
require "t/harness.inc";

#
# marshy
# Snowmelts take two turns to pass through
#

ok(test_hs_return("universe hatchery foo  powers  marshy marshy snowmelt", ['','','','homelessfoo','homelessfoo','']));
ok(test_hs_return("universe hatchery foo  powers  snowmelt", ['','','','','','']));
ok(test_hs_return("marshy hatchery foo  powers", ['','','','homelessfoo','homelessfoo','homelessfoo']));

#
# shallows
# Similar to marshy, but it affects mature salmon.
#

ok(test_hs_return("shallows hatchery foo  powers", ['','','','foo','homelessfoo','homelessfoo']));

#
# rapids
# Similar to shallows, but for young salmon.
#

ok(test_hs_return("rapids hatchery foo  powers", ['','','','homeless','foohomeless','foohomeless']));
