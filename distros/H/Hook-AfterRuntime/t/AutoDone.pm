package AutoDone;
use strict;
use warnings;
use Hook::AfterRuntime;
use Test::More;

sub import {
    my $class = shift;
    my $caller = caller;
    eval "package $caller; use Test::More; 1" || die $@;  ## no critic
    after_runtime { done_testing() };
}

1;
