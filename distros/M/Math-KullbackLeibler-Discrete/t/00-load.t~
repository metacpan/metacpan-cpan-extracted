#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

BEGIN {
    use_ok( 'Math::KullbackLeibler::Discrete' ) || print "Bail out!\n";
}

diag( "Testing Math::KullbackLeibler::Discrete $Math::KullbackLeibler::Discrete::VERSION, Perl $], $^X" );


#P: a:1/2, b:1/4, c:1/4
#Q: a:7/12, b:2/12, d:3/12

my $P = { a => 1/2,
          b => 1/4,
          c => 1/4 };
my $Q = { a => 7/12,
          b => 2/12,
          d => 3/12 };

is( kl($P, $P), 0);
is( kl($Q, $Q), 0);
is( int(kl($Q, $P)), 2);
