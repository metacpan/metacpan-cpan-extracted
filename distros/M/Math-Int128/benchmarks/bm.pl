#!/usr/bin/perl

use 5.010;

use strict;
use warnings;

use Benchmark qw(cmpthese);

use Math::GMP;
use Math::GMPz;
use Math::Int128 qw(int128);

sub bigrand { join "", (1..9)[rand 9], map { (0..9)[rand 10] } 0..33 }

my @data = map bigrand(), 0..1000;



my @int128 = map int128($_), @data;
my @gmp = map Math::GMP->new($_), @data;
my @gmpz = map Math::GMPz->new($_), @data;

cmpthese(-1, { int128 => sub {
                   my $i;
                   $i = ($_ + (1 + $_)) / (10 + $_) for @int128
               },
               gmp => sub {
                   my $i;
                   $i = ($_ + (1 + $_)) / (10 + $_) for @gmp
               },
               gmpz => sub {
                   my $i;
                   $i = ($_ + (1 + $_)) / (10 + $_) for @gmpz
               }
             });

