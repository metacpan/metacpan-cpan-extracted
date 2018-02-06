#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

sub baz {
    return -T '/dev/null';
}

sub bar {
    baz();
}

sub foo {
    bar();
}

foo();

__DATA__
open("/dev/null", *, *) = * at last-call.pl line 8.
    main::baz() called at last-call.pl line 12
    main::bar() called at last-call.pl line 16
    main::foo() called at last-call.pl line 19
