#!perl

use Test::More tests => 1;

use HTTP::Headers::Fancy;

my $class = 'HTTP::Headers::Fancy';

isa_ok $class->new, $class;

done_testing;
