#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

my $module = 'Lingua::Word::Parser';

use_ok $module;

diag(sprintf( 'Testing %s %s with Perl %s, %s', $module, $module->VERSION, $], $^X ));

done_testing();
