use strict;
use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Polynomial;
use Math::Complex;
use Test::More;

my %tests = (
    # real roots
    "Test 01 - real roots" =>     { coeffs => [1, -5, 6], ans => [2, 3] },
    "Test 02 - real roots" =>     { coeffs => [1, 2, -8], ans => [-4, 2] },
    "Test 03 - real roots" =>     { coeffs => [2, -8, 6], ans => [1, 3] },
    "Test 04 - real roots" =>     { coeffs => [1, -7, 12], ans => [3, 4] },
    "Test 05 - real roots" =>     { coeffs => [3, 5, -2], ans => [-2, 1/3] },
    "Test 06 - real roots" =>     { coeffs => [1, 0, -9], ans => [-3, 3] },
    "Test 07 - real roots" =>     { coeffs => [1, -4, 4], ans => [2, 2] },
    "Test 08 - real roots" =>     { coeffs => [5, -20, 15], ans => [1, 3] },

    # complex roots
    "Test 09 - complex roots" =>     { coeffs => [1, 1, 1], ans => [cplx(-1/2, sqrt(3)/2), cplx(-1/2, -sqrt(3)/2)] },
    "Test 10 - complex roots" =>     { coeffs => [1, 2, 5], ans => [cplx(-1, 2), cplx(-1, -2)] },
    "Test 11 - complex roots" =>     { coeffs => [2, 3, 4], ans => [cplx(-3/4, sqrt(23)/4), cplx(-3/4, -sqrt(23)/4)] },
    "Test 12 - complex roots" =>     { coeffs => [1, -2, 5], ans => [cplx(1, 2), cplx(1, -2)] },
    "Test 13 - complex roots" =>     { coeffs => [3, 4, 5], ans => [cplx(-2/3, sqrt(11)/3), cplx(-2/3, -sqrt(11)/3)] },
    "Test 14 - complex roots" =>     { coeffs => [1, 6, 10], ans => [cplx(-3, 1), cplx(-3, -1)] },
    "Test 15 - complex roots" =>     { coeffs => [1, 4, 13], ans => [cplx(-2, 3), cplx(-2, -3)] },
    "Test 16 - complex roots" =>     { coeffs => [2, 2, 5], ans => [cplx(-1/2, 3/2), cplx(-1/2, -3/2)] },
);

foreach my $k (sort keys %tests) {

    my $v = $tests{$k};
    my $coeffs = $v->{coeffs};
    my $ans = $v->{ans};

    # create a polynomial with these coefficients using symbolic_poly()
    my $f = symbolic_poly('x', $coeffs);

    # check that this created expression evaluates to zero (or  
    # numerically close to it) when evaluated with the roots
    my $a1 = $f->value('x' => $ans->[0]);
    my $a2 = $f->value('x' => $ans->[1]);

    if ( $k =~ /complex/ ) {
        ok( (sprintf("%.9f", Re($a1)) == 0) && (sprintf("%.9f", Im($a1)) == 0) &&
            (sprintf("%.9f", Re($a2)) == 0) && (sprintf("%.9f", Im($a2)) == 0), "symbolic_poly: created polynomial expression evaluates to zero with roots ($k)"); 
    }
    else {
        ok((sprintf("%.9f", $a1) == 0) && (sprintf("%.9f", $a2) == 0), "symbolic_poly: created polynomial expression evaluates to zero with roots ($k)"); 
    }

    # now try to reverse engineer the created polynomial using test_polynomial()
    if ( my $is_poly = $f->test_polynomial('x') ) {

        my ($var, $coeffs, $disc, $roots) = @{$is_poly};           

        # check indeterminate variable 
        ok($var eq 'x', "test_polynomial: correct variable ('x') ($k)");

        # check degree
        my $degree = scalar(@{$coeffs})-1;
        ok($degree == 2, "test_polynomial: correct degree (2) ($k)");
            
        # check discriminant
        ok(defined $disc, "test_polynomial: discriminant expression was returned ($k)");

        if ( defined $disc ) {
            my $disc_val = $disc->value();
            if ( $k eq "Test 07 - real roots" ) {
                ok($disc_val == 0, "test_polynomial: discriminant correctly predicts repeated root for test quadratic no. 7 ($k)");
            }
            elsif ( $k =~ /real/ ) {
                ok($disc_val > 0, "test_polynomial: discriminant correctly predicts two real roots ($k)");
            }
            else {
                ok($disc_val < 0, "test_polynomial: discriminant correctly predicts two complex roots ($k)");
            }
        }

        # check roots
        my @root_vals;
        $root_vals[0] = $roots->[0]->value( 'i' => i );    # put in i in case of complex root 
        $root_vals[1] = $roots->[1]->value( 'i' => i );    # it will be ignored if not present

        ok( (($root_vals[0] == $ans->[0]) && ($root_vals[1] == $ans->[1])) || 
            (($root_vals[1] == $ans->[0]) && ($root_vals[0] == $ans->[1])), "test_polynomial: roots match ($k)" );
    }
    else {
        fail("test_polynomial has failed to recognize expression ($k)");
    }

}

my %tests2 = (
    # Cubics
    'Cubic 1'       =>      { coeffs => [1, -6, 11, -6], ans => [1, 2, 3] },
    'Cubic 2'       =>      { coeffs => [1, -3, 3, -1], ans => [1, 1, 1] },
    'Cubic 3'       =>      { coeffs => [1, 0, 0, -8], ans => [2, cplx(-1, -sqrt(3)), cplx(-1, sqrt(3))] },
    'Cubic 4'       =>      { coeffs => [1, -1, 1, -1], ans => [1, cplx(0, 1), cplx(0, -1)] },
    'Cubic 5'       =>      { coeffs => [1, 1, 1, 1], ans => [-1, cplx(0, 1), cplx(0, -1)] },
    'Cubic 6'       =>      { coeffs => [1, -4, 5, -2], ans => [2, 1, 1] },
);

foreach my $k (sort keys %tests2) {

    my $v = $tests2{$k};
    my $coeffs = $v->{coeffs};
    my $ans = $v->{ans};

    # create a polynomial with these coefficients using symbolic_poly()
    my $f = symbolic_poly('x', $coeffs);

    # check that this created expression evaluates to zero (or  
    # numerically close to it) when evaluated with the roots
    my $a1 = sprintf("%.9f", abs($f->value('x' => $ans->[0])));
    my $a2 = sprintf("%.9f", abs($f->value('x' => $ans->[1])));
    my $a3 = sprintf("%.9f", abs($f->value('x' => $ans->[2])));

    ok(($a1 == 0) && ($a2 == 0) && ($a3 == 0), "Roots take polynomial to zero ($k)");
}

done_testing( 6*scalar(keys %tests) + scalar(keys %tests2) );


