#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Stubb::Home;

ok(-d home, 'home ok');

done_testing;

# vim: expandtab shiftwidth=4
