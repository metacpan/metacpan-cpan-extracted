#!/usr/bin/env perl

use Cwd qw(abs_path);
use FindBin;
use lib map { abs_path("$FindBin::Bin/../$_") } qw(t/lib lib);
use test_setup;

use Tie::Scalar;

my $FILE = __FILE__;
my $LINE = __LINE__;

run_eponymous_test;

#################################################

sub test_invocation_errors {
    banner;

    local $@;
    my $ERR;

    $LINE = __LINE__; like $ERR=dies { &watch },
        qr/^\QYou didn't pass a SCALAR (by reference)/,
        "watch dies when called without arguments";
    like $ERR, qr/\Q at $FILE line $LINE\E\b/, "exception chooses right line";

    like dies { &watch(\6.02e23) },
        qr/^\QCan't watch a readonly scalar/,
        "watch dies when called with reference to readonly scalar";

    our $var;
    *var = \"CONSTANT STRING LITERAL";

    like dies { watch $var },
        qr/^\QCan't watch a readonly scalar/,
        "watch dies when called with reference to readonly scalar";

    my $t = "Whatever";
    like dies { unwatch $t },
        qr/^\QCan't unwatch something that isn't tied/,
        "unwatch dies when attempting to unwatch a variable that wasn't watched";

    tie $t, "Tie::StdScalar";
    like dies { unwatch $t },
        qr/^\QCan't unwatch something that isn't watched/,
        "unwatch dies when attempting to unwatch a variable tied to the wrong class";

}
