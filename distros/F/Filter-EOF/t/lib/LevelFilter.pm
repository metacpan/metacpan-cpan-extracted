package LevelFilter;
use warnings;
use strict;

use base 'RealLevelFilter';

sub import {
    my ($class, @args) = @_;
    RealLevelFilter->import(scalar(caller), @args);
}

1;
