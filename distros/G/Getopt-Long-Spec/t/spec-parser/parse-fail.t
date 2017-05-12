#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan( tests => 1);

my $CLASS = 'Getopt::Long::Spec::Parser';

use_ok( $CLASS ) or die "Couldn't compile [$CLASS]\n";

### test for expected failure attempting to parse *invalid* getopt specs


