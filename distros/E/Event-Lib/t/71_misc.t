# Objective:
# ----------
#
# Make sure that adding an event twice fails

use Test;
BEGIN { plan tests => 2 }
use Event::Lib;

my $t = timer_new(sub {});
$t->add;
ok(1);
eval { $t->add };
ok($@ =~ /^Attempt to add event a second time/);

