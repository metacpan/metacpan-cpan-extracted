#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More tests => 3;

use lib (File::Spec->catdir($Bin, 'lib'));

# pre-leak sanity-check
use_ok('Outer');
is(Outer::outer(), 'Outer');
is_deeply(Outer::inner(), [ 1, 'Inner' ]);
