#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;

use Flux::Simple qw( array_in mapper );

my $in = array_in(['a', 'b', 'c']);
my $mapped_in = $in | mapper { $_[0] x 2 };

ok $mapped_in->does('Flux::In');
is $mapped_in->read, 'aa';
is $mapped_in->read, 'bb';

is $in->read, 'c';

# TODO - test ->commit delegation
# TODO - test ->does behavior details

done_testing;
