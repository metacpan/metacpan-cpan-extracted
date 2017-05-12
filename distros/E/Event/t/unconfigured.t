#!./perl -w

use strict;
use Test; plan test => 6;
use Event;

my @p = (cb=>\&die);

eval { Event->io(@p) };
ok $@, '/unconfigured/';

eval { Event->signal(@p) };
ok $@, '/without signal/';

eval { Event->timer(@p) };
ok $@, '/unset/';

eval { Event->var(@p) };
ok $@, '/watching what/';

my $var = 1;

eval { Event->var(@p, poll => 0, var => \$var) };
ok $@, '/without poll events/';

eval { Event->var(@p, var => \$]) };
ok $@, '/read\-only/';
