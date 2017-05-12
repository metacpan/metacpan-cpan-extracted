use strict;
use warnings;
use Test::More;
use File::Spec::Functions;
use lib catfile("..","lib");
use Math::ODE;
use Data::Dumper;

my $file = catfile(qw/t data/);

# analytic solution is y(x) = 5 x
my $o = new Math::ODE (
    file    => $file,
    step    => 0.1,
    initial => [0],
    ODE     => [ \&DE1 ],
    t0      => 0,
    tf      => 1,
);
isa_ok($o, 'Math::ODE');
isa_ok($o->evolve, 'Math::ODE');

cmp_ok($o->format(), 'eq', '%.12f');

$o->format("%.15g");

cmp_ok($o->format(), 'eq', '%.15g');

$o->format("%.12f");

if ($o) {
    my $eps = $o->{step} ** 4;	# because Math::ODE implements a 4th order Runge-Kutta method

    my $s = sprintf("%0.12f", 0.5);
    my @vals =  $o->values_at( $s );
    my $res = abs($vals[0] - 2.5);
    ok( $res < $eps, "Constant Coefficient Equation solved correctly, res=$res");
} else {
    ok( 0, 'Constant Coefficient Equation died due to numerical shenanigans');
}
sub DE1 { my ($t,$y) = @_; return 5; }
##############################
SKIP : {
    skip 'not blowing up enough', 1;
    # analytic solution is y(x) = -1/(x-1)
    $o = new Math::ODE (
        file    => $file,
        step    => 0.01,
        initial => [1],
        ODE     => [ \&DE2 ],
        t0      => 0,
        tf      => 2,
    );
    # should blow up at t=1
    my $ret = $o->evolve;
    my @vals =  $o->values_at( 1 );
    print "ret=$ret, val=" . $vals[0] . "\n";
    ok( ! defined $ret , 'evolve blows up in the right place');
}

sub DE2 { my ($t,$y) = @_; $y->[0] ** 2; }
##############################

$o = new Math::ODE (
    file => $file,
    step    => 0.1,
    csv     => 1,
    initial => [0],
    ODE     => [ \&DE1 ],
    t0      => 0,
    tf      => 1,
);
if ( $o->evolve ) {
    open (my $fh, '<',  $o->file) or die $!;
    my $first_line = <$fh>;
    ok( $first_line =~ /(\d+\.\d+),(\d+\.\d+)$/, "CSV works");
    close $fh or die $!;
} else {
    ok( 0, 'CSV died due to numerical shenanigans');
}

done_testing;
