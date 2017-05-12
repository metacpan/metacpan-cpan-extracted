#!perl -T

use 5.010;
use strict;
use warnings;
use lib 't';
use Test::More tests => 8 + 1;
use Test::NoWarnings;
use Test::Warn;

use DoWarn;

ok warn1(), q{use DoWarn; warn1();};
ok warn2(), q{use DoWarn; warn2();};

{
    no DoWarn;

    warning_like { warn1() } qr/^DoWarn::warn1 not allowed here/;
    warning_like { warn2() } qr/^DoWarn::warn2 not allowed here/;
}

ok warn1(), q{use DoWarn; warn1();};
ok warn2(), q{use DoWarn; warn2();};

{
    no DoWarn 'warn2';

    ok warn1(), q{use DoWarn; no DoWarn 'warn2'; warn1();};
    warning_like { warn2() } qr/^DoWarn::warn2 not allowed here/;
}
