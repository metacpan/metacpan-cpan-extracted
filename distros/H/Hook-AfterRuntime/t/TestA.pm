package TestA;
use strict;
use warnings;
use Hook::AfterRuntime;

sub import {
    after_runtime { $main::TRIGGERED++ };
}

1;
