#!perl

use strict;
use warnings;

use Test::More;

use Config;

BEGIN {
    plan skip_all => 'Perl compiled without ithreads'
        unless $Config{useithreads};
    plan skip_all => 'ithreads support requires perl 5.8 or newer'
        unless $] >= 5.008000;
    plan tests => 22;
}

use threads;

use Math::BigInt only => 'GMP';

my @threads = map {
    my $x = $_;
    threads->create(sub {
        (Math::BigInt->new($x))
    });
} 0 .. 19;

my @ret = map {
    $_->join
} @threads;

pass 'we survived our threads';

is(@ret, 20, 'got all the numbers we expected');
is($ret[$_], $_, 'numbers look sane') for 0 .. 19;
