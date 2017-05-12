#!perl

use strict;
use warnings;
use Test::More tests => 1;

ok( 1, 'Keep Test::More happy' );

unlink('t/config.pl');
