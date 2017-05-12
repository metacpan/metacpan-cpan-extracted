#! /usr/bin/env perl

use strict;
use warnings;
use Math::Random::MT::Perl;
use Math::Random::MT;
use Benchmark 'cmpthese';

my $count = $ARGV[0] || 10000;
print "Doing $count iterations\n";
my $p = Math::Random::MT::Perl->new(1);
my $c = Math::Random::MT->new(1);
cmpthese( $count, {
    Perl => sub { $p->rand() },
    C    => sub { $c->rand() }, }
);

__DATA__
C:\Math-Random-MT-Perl-1.03\t>benchmark.pl 10000000
Doing 10000000 iterations
         Rate Perl    C
Perl 114654/s   -- -63%
C    308880/s 169%   --
