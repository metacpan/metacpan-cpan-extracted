#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use File::Stubb::SubstTie;

tie my %tie, 'File::Stubb::SubstTie', one => 1, two => 2;

is($tie{ one }, 1, 'existing keys ok');
is($tie{ three }, '', 'non-existing keys ok');

done_testing;

# vim: expandtab shiftwidth=4
