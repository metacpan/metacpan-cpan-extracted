use warnings;
use strict;

use Test::More tests => 1;

BEGIN { use_ok "IPC::Signal::Force", qw(force_raise); }

1;
