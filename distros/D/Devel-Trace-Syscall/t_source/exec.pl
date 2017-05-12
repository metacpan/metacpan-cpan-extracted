#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

sub foo {
    exec 'ls';
}

foo();

__DATA__
# bailing: 1
