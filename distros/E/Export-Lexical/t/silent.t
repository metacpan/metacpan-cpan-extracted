#!perl -T

use 5.010;
use strict;
use warnings;
use lib 't';
use Test::More tests => 8 + 1;
use Test::NoWarnings;

use DoSilent;

ok silent1(), q{use DoSilent; silent1();};
ok silent2(), q{use DoSilent; silent2();};

{
    no DoSilent;

    ok !silent1(), q{no DoSilent; silent1();};
    ok !silent2(), q{no DoSilent; silent2();};
}

ok silent1(), q{use DoSilent; silent1();};
ok silent2(), q{use DoSilent; silent2();};

{
    no DoSilent 'silent2';

    ok silent1(), q{use DoSilent; no DoSilent 'silent2'; silent1();};
    ok !silent2(), q{use DoSilent; no DoSilent 'silent2'; silent2();};
}
