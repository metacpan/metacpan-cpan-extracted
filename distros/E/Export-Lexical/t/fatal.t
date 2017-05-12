#!perl -T

use 5.010;
use strict;
use warnings;
use lib 't';
use Test::More tests => 8 + 1;
use Test::NoWarnings;
use Test::Exception;

use DoFatal;

ok fatal1(), q{use DoFatal; fatal1();};
ok fatal2(), q{use DoFatal; fatal2();};

{
    no DoFatal;

    throws_ok { fatal1() } qr/^DoFatal::fatal1 not allowed here/;
    throws_ok { fatal2() } qr/^DoFatal::fatal2 not allowed here/;
}

ok fatal1(), q{use DoFatal; fatal1();};
ok fatal2(), q{use DoFatal; fatal2();};

{
    no DoFatal 'fatal2';

    ok fatal1(), q{use DoFatal; no DoFatal 'fatal2'; fatal1();};
    throws_ok { fatal2() } qr/^DoFatal::fatal2 not allowed here/;
}
