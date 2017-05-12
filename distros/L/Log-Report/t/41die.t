#!/usr/bin/env perl
# Convert die into report

use warnings;
use strict;
use lib 't';

use POSIX;

eval { setlocale(LC_ALL, 'POSIX') };

$! = 3;
my $errno  = $!+0;
my $errstr = "$!";

#### Carp only works in package != main
use DieTests;

# we need a short stack trace
sub simple_wrapper() { DieTests::run_tests() }
simple_wrapper();
