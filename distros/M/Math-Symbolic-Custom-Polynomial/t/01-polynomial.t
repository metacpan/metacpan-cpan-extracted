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

my %tests3 = (
	"Test 3.01"	=>	{ expr => "k*x^2 + 3*x + 2", var => 'x', coeffs => ['k', 3, 2] },
	"Test 3.02"	=>	{ expr => "y^2 + 2", var => 'y', coeffs => [1, 0, 2] },
	"Test 3.03"	=>	{ expr => "z^3 - 3*z + 2", var => 'z', coeffs => [1, 0, -3, 2] },
	"Test 3.04"	=>	{ expr => "k*V1^3 - 5*V1^2 + k - 1", var => 'V1', coeffs => ['k', -5, 0, 'k - 1'] },
	"Test 3.05"	=>	{ expr => "-(y^2) - y - 1", var => 'y', coeffs => [-1, -1, -1] },
	"Test 3.06"	=>	{ expr => "y^2 - y - 1", var => 'y', coeffs => [1, -1, -1] },
	"Test 3.07"	=>	{ expr => "0.5*x^2 + k*x + 12", var => "x", coeffs => ['1 / 2', 'k', 12] },
	"Test 3.08"	=>	{ expr => "u*t + (1/2)*a*t^2", var => "t", coeffs => ['a / 2', 'u', 0] },
	"Test 3.09"	=>	{ expr => "x^2 + 5*x + 6", var => "x", coeffs => [1, 5, 6] },
	"Test 3.10"	=>	{ expr => "4*x^3 - 3*x^2 + 7*x - 2", var => "x", coeffs => [4, -3, 7, -2] },
	"Test 3.11"	=>	{ expr => "7*x^4 + 2*x^3 - x^2 + 8", var => "x", coeffs => [7, 2, -1, 0, 8] },
	"Test 3.12"	=>	{ expr => "x^6 + 6*x^5 - 5*x^4 + 4*x^3 - 3*x^2 + 2*x + 1", var => "x", 
						coeffs => [1, 6, -5, 4, -3, 2, 1] },
	"Test 3.13"	=>	{ expr => "p*z^3 + q*z^2 + r*z + s", var => "z", coeffs => ['p', 'q', 'r', 's'] },
	"Test 3.14"	=>	{ expr => "phi^8 + 3*phi^7 - 5*phi^6 + 2*phi^5 -7*phi^4 + phi^3 + phi^2 - 2*phi + 9", var => "phi", 
						coeffs => [1, 3, -5, 2, -7, 1, 1, -2, 9] },
    "Test 3.15"	=>	{ expr => "a*x^2 + c*x + e - d*x + b*x^2", var => "x", coeffs => ['a + b', 'c - d', 'e'] },
	"Test 3.16"	=>	{ expr => "(k-1)*x^2 + 3*k*x + 2", var => "x", coeffs => ['k - 1', '3 * k', 2] },
	"Test 3.17"	=>	{ expr => "(m-n)*x^4 + (p+q)*x^3 - x^2 + (a-b)*x + c", var => "x", 
						coeffs => ['m - n', 'p + q', -1, 'a - b', 'c'] },
	"Test 3.18"	=>	{ expr => "k*x^5 - r*x + o*x^3 + (l-m)*x^4 + o*x^3 + n*x^3 + p*x^2 + q*x + s", var => "x", 
						coeffs => ['k', 'l - m', 'n + (2 * o)', 'p', 'q - r'] },
);
	
TEST: foreach my $test (sort keys %tests3) {

	my $expr = parse_from_string($tests3{$test}{expr});
	ok(defined($expr), "Expression parsed ($expr)");
	
    # check test_polynomial() operation without specifying indeterminate variable
	my ($v, $co) = $expr->test_polynomial();
	ok(defined($v) && defined($co), "test_polynomial() returned output");
	
	ok($v eq $tests3{$test}{var}, "test_polynomial() detected indeterminate variable ($v)");
	
	my @test_coeffs = @{$tests3{$test}{coeffs}};
	my $num_coeffs = scalar(@test_coeffs);
	my $coeffs_match = 1;
	# assume test_polynomial() returns the correct coefficients and try to disprove that
	CHECK_COEFF: foreach my $i (0..$num_coeffs-1) {
		if (!defined($co->[$i])) {
			$coeffs_match = 0;
			last CHECK_COEFF;
		}
		elsif ( $co->[$i]->to_string() ne $test_coeffs[$i] ) {
			$coeffs_match = 0;
			last CHECK_COEFF;
		}
	}
	
	ok($coeffs_match, "test_polynomial() returns correct coefficients");
}

# test apply_synthetic_division()
my %synth_div_const_tests = (
    "Test 01"   =>  { var => 'x', coeffs => [2, -6, 2, -1], divisor => 3, quotient => [2, 0, 2], remainder => 5 }, 
    "Test 02"   =>  { var => 'y', coeffs => [5, -8, 9, 12], divisor => 3, quotient => [5, 7, 30], remainder => 102 },
    "Test 03"   =>  { var => 'z', coeffs => [3, -1, 0, 4, -8], divisor => 1, quotient => [3, 2, 2, 6], remainder => -2 },
    "Test 04"   =>  { var => 'x', coeffs => [2, -5, -8, 15], divisor => 3, quotient => [2, 1, -5], remainder => 0 },
    "Test 05"   =>  { var => 'x', coeffs => [1, 2, -4, 1], divisor => 1, quotient => [1, 3, -1], remainder => 0 },
    "Test 06"   =>  { var => 'x', coeffs => [3, -2, 0, -150], divisor => 4, quotient => [3, 10, 40], remainder => 10 },
    "Test 07"   =>  { var => 'x', coeffs => [2, 3, -5, 6], divisor => 2, quotient => [2, 7, 9], remainder => 24 },
    "Test 08"   =>  { var => 'x', coeffs => [5, -22, 9, -6, 14], divisor => 4, quotient => [5, -2, 1, -2], remainder => 6 },
    "Test 09"   =>  { var => 'x', coeffs => [1, 0, -3, 0, -4, -1], divisor => 1, quotient => [1, 1, -2, -2, -6], remainder => -7 },
);

foreach my $test_name (sort keys %synth_div_const_tests) {

    my $test = $synth_div_const_tests{$test_name};

    my $f = symbolic_poly($test->{var}, $test->{coeffs});

    my ($full_expr, $divisor, $quotient, $remainder) = $f->apply_synthetic_division($test->{divisor});

    ok($f->test_num_equiv($full_expr), "Synthetic division $test_name: original polynomial P numerically equivalent to D*Q + R");

    my $test_quotient = symbolic_poly($test->{var}, $test->{quotient});
    ok($test_quotient->test_num_equiv($quotient), "Synthetic division $test_name: quotient numerically equivalent ($test_quotient |vs| $quotient)" );

    my $test_remainder = parse_from_string($test->{remainder});
    ok($test_remainder->test_num_equiv($remainder), "Synthetic division $test_name: remainder numerically equivalent ($test_remainder |vs| $remainder)" );
}

# test apply_polynomial_division()
my %poly_div_const_tests = (
    "Test 01"   =>  { var => 'x', coeffs => [2, -3, -3, 2], divisor => [1, -2], quotient => [2, 1, -1], remainder => [0] }, 
    "Test 02"   =>  { var => 'x', coeffs => [2, 3, 0, -1], divisor => [2, -1], quotient => [1, 2, 1], remainder => [0] },
    "Test 03"   =>  { var => 'x', coeffs => [2, -11, 12, -35], divisor => [1, -5], quotient => [2, -1, 7], remainder => [0] },
    "Test 04"   =>  { var => 'x', coeffs => [-3, 11, -13, 26, -15], divisor => [1, -3], quotient => [-3, 2, -7, 5], remainder => [0] },
    "Test 05"   =>  { var => 'x', coeffs => [-18, 33, -29, 10], divisor => [-3, 2], quotient => [6, -7, 5], remainder => [0] },
    "Test 06"   =>  { var => 'x', coeffs => [2, 12, 14, -8, 0], divisor => [1, 4], quotient => [2, 4, -2, 0], remainder => [0] }, 
    "Test 07"   =>  { var => 'x', coeffs => [4, 4, -1, 1], divisor => [2, 1], quotient => [2, 1, -1], remainder => [2] }, 
    "Test 08"   =>  { var => 'x', coeffs => [15, -1, 7, 0, 5], divisor => [3, 1], quotient => [5, -2, 3, -1], remainder => [6] }, 
    "Test 09"   =>  { var => 'x', coeffs => [3, 19, -25, -57, 130], divisor => [-1, -7], quotient => [-3, 2, 11, -20], remainder => [-10] }, 
    "Test 10"   =>  { var => 'x', coeffs => [-8, 24, -12, 17, -26], divisor => [-2, 5], quotient => [4, -2, 1, -6], remainder => [4] }, 
    "Test 11"   =>  { var => 'x', coeffs => [3, 4, 0, 1, 3, 1], divisor => [1, 2, 1], quotient => [3, -2, 1, 1], remainder => [0] }, 
    "Test 12"   =>  { var => 'x', coeffs => [-2, 13, -3, 37, 35], divisor => [2, -1, 7], quotient => [-1, 6, 5], remainder => [0] }, 
    "Test 13"   =>  { var => 'x', coeffs => [-2, 3, -4, -24, 7], divisor => [1, -3, 7], quotient => [-2, -3, 1], remainder => [0] }, 
    "Test 14"   =>  { var => 'x', coeffs => [2, 6, 11, -11, 5, -7], divisor => [2, 0, 1], quotient => [1, 3, 5, -7], remainder => [0] }, 
    "Test 15"   =>  { var => 'x', coeffs => [-6, -12, 25, -10, -14, 12], divisor => [-3, 0, 2], quotient => [2, 4, -7, 6], remainder => [0] }, 
    "Test 16"   =>  { var => 'x', coeffs => [3, -4, 12, -6, 11], divisor => [1, 0, 2], quotient => [3, -4, 6], remainder => [2, -1] }, 
    "Test 17"   =>  { var => 'x', coeffs => [1, 1, 0, 10, 10, 7], divisor => [1, 2, 0], quotient => [1, -1, 2, 6], remainder => [-2, 7] }, 
    "Test 18"   =>  { var => 'x', coeffs => [-6, 3, -4, 20, -3, 10], divisor => [3, 0, 2], quotient => [-2, 1, 0, 6], remainder => [-3, -2] }, 
    "Test 19"   =>  { var => 'x', coeffs => [4, -4, -4, 6, -7], divisor => [2, 2, -1], quotient => [2, -4, 3], remainder => [-4, -4] }, 
    "Test 20"   =>  { var => 'x', coeffs => [-3, 3, -19, -3, 17, -9], divisor => [-1, 1, -7], quotient => [3, 0, -2, 1], remainder => [2, -2] }, 

);

foreach my $test_name (sort keys %poly_div_const_tests) {

    my $test = $poly_div_const_tests{$test_name};
    my $var = $test->{var};

    my $f = symbolic_poly($var, $test->{coeffs});
    my $d = symbolic_poly($var, $test->{divisor});

    my ($full_expr, $divisor, $quotient, $remainder) = $f->apply_polynomial_division($d);

    ok($f->test_num_equiv($full_expr), "Polynomial division $test_name: original polynomial P numerically equivalent to D*Q + R");

    my $test_quotient = symbolic_poly($var, $test->{quotient});
    ok($test_quotient->test_num_equiv($quotient), "Polynomial division $test_name: quotient numerically equivalent ($test_quotient |vs| $quotient)" );
    
    my $test_remainder = symbolic_poly($var, $test->{remainder});
    ok($test_remainder->test_num_equiv($remainder), "Polynomial division $test_name: remainder numerically equivalent ($test_remainder |vs| $remainder)" );
}

done_testing( 6*scalar(keys %tests) + scalar(keys %tests2) + 4*scalar(keys %tests3) + 3*scalar(keys %synth_div_const_tests)  + 3*scalar(keys %poly_div_const_tests));


