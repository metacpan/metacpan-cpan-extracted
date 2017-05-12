#!/usr/bin/env perl
#examples with references
use Modern::Perl;
use Scalar::Util qw(refaddr);
use Math::Vector::Real;

my $v = V(1,2,3);

say refaddr ($v);

my $a = $v;

say refaddr ($a);

my $b = $v + V(1,1,1);

say refaddr ($b);



