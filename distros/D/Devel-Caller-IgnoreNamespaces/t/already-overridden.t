#!perl

use strict;
use warnings;
no warnings 'once';

use Test::More tests => 1;

BEGIN {
    # this check if to suppress an extra test result being spat out
    # when testing to see if being called from package DB
    my $dont_run_twice = 0;
    *CORE::GLOBAL::caller = sub (;$) {
        pass("if caller is already overridden it is wrapped, not ignored") unless($dont_run_twice++);
    };
}

$SIG{__WARN__} = sub { fail("Caught a warning: $_[0]"); };

eval 'use Devel::Caller::IgnoreNamespaces';

my $result = caller();
