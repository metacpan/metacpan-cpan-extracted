#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;

use Flux::Simple qw( mapper );

my $left = mapper { $_[0] x 2 };
my $right = mapper { $_[0] . '2' };

my $mapper = $left | $right;
ok $mapper->does('Flux::Mapper');

is $mapper->write('a'), 'aa2';
is_deeply $mapper->write_chunk(['b', 'cc']), ['bb2', 'cccc2'];

# TODO - test commit
# TODO - test one-to-many

done_testing;
