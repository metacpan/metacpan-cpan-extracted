use strict;
use warnings;
use Test::More tests => 1;
use File::Spec::Functions;
use lib catfile("..","lib");
use Math::ODE;
use Data::Dumper;

# analytic solution is y(x) = 5 x
my $o = new Math::ODE (
    step        => 0.1,
    initial     => [0],
    keep_values => 0,
    ODE         => [ \&DE1 ],
    t0          => 0,
    tf          => 1,
);

# check print to STDOUT?

if ( $o->evolve ) {
    ok( 1,  "keep_values => 0 and file => undef prints to STDOUT");
} else {
    ok( 0,  "keep_values => 0 and file => undef prints to STDOUT");
}

sub DE1 { my ($t,$y) = @_; return 5; }
