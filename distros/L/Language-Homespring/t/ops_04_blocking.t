use Test::Simple tests => 8;

use Language::Homespring;
require "t/harness.inc";

#
# net
# Blocks mature salmon.
#
 
ok(test_hs_return("bar hatchery foo  powers", ['','','','homelessfoo','homelessfoo']));
ok(test_hs_return("net hatchery foo  powers", ['','','','foo','foo']));

#
# current
# Blocks young salmon.
#

ok(test_hs_return("current hatchery foo  powers", ['','','','homeless','homeless']));

#
# insulated
# Blocks electricity.
#

ok(test_hs_return("net hatchery foo  bar powers", ['','','','foo','foo']));
ok(test_hs_return("net hatchery foo  insulated powers", ['','','','','']));

#
# force field
# Blocks everything when powered. Things can enter it, but they can't pass through it.
#

ok(test_hs_return("bear hatchery force. field foo   powers", ['','','','','','foo','foo']));
ok(test_hs_return("bear hatchery force. field foo  powers", ['','','','','','','']));
ok(test_hs_return("bear hatchery force. field powers   powers", ['','','','nameless','nameless','nameless']))

#
# bridge
# Blocks everything if it is destroyed by snowmelt.
#

#
# waterfall
# Blocks fish moving upstream. They can enter it, but they can't pass through it. As such they will spawn at the waterfall.
#

#
# evaporates
# Blocks water and snowmelt when powered.
#

#
# pump
# Fish can only enter this node when it is powered.
#

#
# fear
# Fish can not enter this node when it is powered.
#

#
# lock
# Downstream salmon cannot enter this node when it is powered.
#

#
# inverse lock
# Downstream salmon cannot enter this node unless it is powered.
#

#
# narrows
# Only one salmon can enter at a time.
#
