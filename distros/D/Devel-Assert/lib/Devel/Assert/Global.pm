package #hide from PAUSE
    Devel::Assert::Global;
use strict;

sub import {
    require Devel::Assert;
    push @_, 'global';
    goto &Devel::Assert::import;
}

1;

