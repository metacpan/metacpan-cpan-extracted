use strict;
use Test;

BEGIN { plan tests => 1 }

require LWP::Authen::Wsse;
ok(LWP::Authen::Wsse->VERSION);
