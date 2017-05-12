use strict;
use warnings;
use File::Spec::Functions;
use Test::More tests => 1;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::ODE;
use Data::Dumper;
my $file = catfile(qw/t data/);

# analytic solution is y(x) = 2 e^{-x}
my $o = new Math::ODE (
    file    => $file,
    step    => 0.1,
    initial => [2],
    ODE     => [ \&DE1 ],
    t0      => 0,
    tf      => 1,
);
$o->evolve;
my $res = abs($o->error - $o->{step}**4 );
ok( $res < 1e-12, "returns correct amount of error , res=$res" );
sub DE1 { my ($t,$y) = @_; return -$y->[0]; }


END { unlink $file };
