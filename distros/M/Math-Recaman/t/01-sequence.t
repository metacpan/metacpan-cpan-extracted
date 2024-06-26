#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Math::Recaman;
$Math::Recaman::USING_INTSPAN=0;

require 't/01-sequence-common.pl';
is($Math::Recaman::USING_INTSPAN, 0, "Forced not using Set::IntSpan");