#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;

my $MODULE = 'ExtUtils::CppGuess';
use_ok($MODULE);

my $guess = $MODULE->new;
isa_ok $guess, $MODULE;

diag 'EUMM:', Dumper { $guess->makemaker_options };
diag '---';
diag 'MB:', Dumper { $guess->module_build_options };
