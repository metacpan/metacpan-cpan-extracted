#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use EBook::Gutenberg::Home;

ok(-d home, "home ok");

done_testing;

# vim: expandtab shiftwidth=4
