use strict;
use warnings;
use Config;
use Test::More;
BEGIN { plan skip_all => 'no ithreads' unless $Config{useithreads} }
use threads;
use Spike;

my @t = map { threads->create(sub { my $s = 0; $s += Spike::add($_, 1) for 1 .. 200000; $s }) } 1 .. 4;
my @s = map { $_->join } @t;
is($s[0], $s[1], 'four threads of 200000 adds each');
done_testing;
