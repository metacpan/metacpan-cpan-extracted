#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Fancy::Module;

ok is_it_the_number(41) eq "No, it's not", 'was not the number';
ok is_it_the_number(42) eq "It is the number", 'was the number';

done_testing();

