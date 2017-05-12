#!/usr/bin/env perl
use warnings;
use strict;
use Dist::HomeDir lib => [ qw/foo bar/ ];
use Test::More;
use lib 't/lib';
my $found = grep { /foo|bar$/} @INC;
is ( $found, 2, 'foo and bar are in @INC');

use Dist::HomeDir lib => [ qw/baz/ ];

$found = grep { /foo|bar|baz$/} @INC;
is ( $found, 3, 'baz now found in @INC');

done_testing;
