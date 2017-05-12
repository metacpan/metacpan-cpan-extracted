#!/usr/bin/perl
# vim: ts=2 sw=2 filetype=perl expandtab
use warnings;
use strict;

use Test::More tests => 1;

# idea from Test::Harness, thanks!
diag("Perl $], $^X on $^O");
pass("need a test to pass");
