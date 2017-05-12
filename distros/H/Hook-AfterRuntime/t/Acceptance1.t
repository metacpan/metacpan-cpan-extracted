#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use vars qw/$TRIGGERED/;
use lib '.', './t';

use TestB;

ok( $main::TRIGGERED, "triggered" );

done_testing();
