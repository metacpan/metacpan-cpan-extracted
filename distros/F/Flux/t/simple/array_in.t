#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;

use Flux::Simple qw(array_in);

my $in = array_in(['a'..'z']);
ok $in->does('Flux::In'), 'array_in is In';

is $in->read, 'a';
is $in->read, 'b';
is_deeply $in->read_chunk(2), ['c', 'd'];
$in->read for 1..21;
is $in->read, 'z';
is $in->read, undef;
is scalar($in->read_chunk(3)), undef;
is_deeply [$in->commit], [];

done_testing;
