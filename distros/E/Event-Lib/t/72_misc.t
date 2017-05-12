# Objective:
# ----------
#
# Check the return value of event_mainloop.
# We can only check a succesful-call as it is 
# tricky to come up with a case that produces
# an error for each kernel notification method.

use Test;
BEGIN { plan tests => 1 }
use Event::Lib;

ok(event_mainloop());
