# perl 5
#
# Math-GoldenBigMath.t
#
# Test of GoldenBigMath
#
# Ralf Peine, Wed Aug 20 08:50:23 2014

use strict;
use warnings;

$|=1;

use Test::More;       # see done_testing()

BEGIN { use_ok( 'Math::GoldenBigMath' ); }

my $testToStart = shift;

$testToStart = '' unless $testToStart;
my $printTestStr = $testToStart;
$printTestStr = "--- ALL ---" unless $printTestStr;

# diag "Start Tests: $printTestStr\n";

TestParsing()                               if !$testToStart  ||  lc($testToStart) eq 'parse';
TestComparison()                            if !$testToStart  ||  lc($testToStart) eq 'compare';
TestFormatting()                            if !$testToStart  ||  lc($testToStart) eq 'format';
TestAddition()                              if !$testToStart  ||  lc($testToStart) eq 'add';
TestSubtraction()                           if !$testToStart  ||  lc($testToStart) eq 'subtr';
TestBuildMultiplicationTableAsString ()     if !$testToStart  ||  lc($testToStart) eq 'multab';
TestMultiplication()                        if !$testToStart  ||  lc($testToStart) eq 'mul';
TestOperators()                             if !$testToStart  ||  lc($testToStart) eq 'op';

if (!$testToStart  ||  lc($testToStart) eq 'exceptions') {
	
	my $test_exception_installed = eval {
		require Test::Exception;
		1;
	};
	
	if ($test_exception_installed) {
		require 't/Math-GoldenBigMath_Exceptions.pl';		
	}
	else {
		diag ("Skip exception tests");
	}
	
}

done_testing();

# --- Parsing Tests ---------------------------------------------------------------
#

sub TestParsing {

    diag "--- Parsing Tests ---------------------------------------------------------------";

    is(new Math::GoldenBigMath('0')->GetValue(), '+0e+0', 't 0');
    is(new Math::GoldenBigMath('1')->GetValue(), '+1e+0', 't 1');
    is(new Math::GoldenBigMath('0.0')->GetValue(), '+0e+0', 't 0.0');
    is(new Math::GoldenBigMath('1.0')->GetValue(), '+1e+0', 't 1.0');
    is(new Math::GoldenBigMath('0.0e0')->GetValue(), '+0e+0', 't 0.0e0');
    is(new Math::GoldenBigMath('1.0e0')->GetValue(), '+1e+0', 't 1.0e0');
    is(new Math::GoldenBigMath('0.0e+0')->GetValue(), '+0e+0', 't 0.0e+0');
    is(new Math::GoldenBigMath('1.0e+0')->GetValue(), '+1e+0', 't 1.0e+0');
    is(new Math::GoldenBigMath('0.0e-0')->GetValue(), '+0e+0', 't 0.0e-0');
    is(new Math::GoldenBigMath('1.0e-0')->GetValue(), '+1e+0', 't 1.0e-0');

    is(new Math::GoldenBigMath('-0')->GetValue(), '+0e+0', 't -0');
    is(new Math::GoldenBigMath('-1')->GetValue(), '-1e+0', 't -1');
    is(new Math::GoldenBigMath('-0.0')->GetValue(), '+0e+0', 't -0.0');
    is(new Math::GoldenBigMath('-1.0')->GetValue(), '-1e+0', 't -1.0');
    is(new Math::GoldenBigMath('-0.0e0')->GetValue(), '+0e+0', 't -0.0e0');
    is(new Math::GoldenBigMath('-1.0e0')->GetValue(), '-1e+0', 't -1.0e0');
    is(new Math::GoldenBigMath('-0.0e+0')->GetValue(), '+0e+0', 't -0.0e+0');
    is(new Math::GoldenBigMath('-1.0e+0')->GetValue(), '-1e+0', 't -1.0e+0');
    is(new Math::GoldenBigMath('-0.0e-0')->GetValue(), '+0e+0', 't -0.0e-0');
    is(new Math::GoldenBigMath('-1.0e-0')->GetValue(), '-1e+0', 't -1.0e-0');

    is(new Math::GoldenBigMath('+0')->GetValue(), '+0e+0', 't +0');
    is(new Math::GoldenBigMath('+1')->GetValue(), '+1e+0', 't +1');
    is(new Math::GoldenBigMath('+0.0')->GetValue(), '+0e+0', 't +0.0');
    is(new Math::GoldenBigMath('+1.0')->GetValue(), '+1e+0', 't +1.0');
    is(new Math::GoldenBigMath('+0.0e0')->GetValue(), '+0e+0', 't +0.0e0');
    is(new Math::GoldenBigMath('+1.0e0')->GetValue(), '+1e+0', 't +1.0e0');
    is(new Math::GoldenBigMath('+0.0e+0')->GetValue(), '+0e+0', 't +0.0e+0');
    is(new Math::GoldenBigMath('+1.0e+0')->GetValue(), '+1e+0', 't +1.0e+0');
    is(new Math::GoldenBigMath('+0.0e-0')->GetValue(), '+0e+0', 't +0.0e-0');
    is(new Math::GoldenBigMath('+1.0e-0')->GetValue(), '+1e+0', 't +1.0e-0');

    is(new Math::GoldenBigMath('+0.0e+1')->GetValue(), '+0e+0', 't +0.0e+1');
    is(new Math::GoldenBigMath('+1.0e+1')->GetValue(), '+1e+1', 't +1.0e+1');
    is(new Math::GoldenBigMath('+0.0e-1')->GetValue(), '+0e+0', 't +0.0e-1');
    is(new Math::GoldenBigMath('+1.0e-1')->GetValue(), '+1e-1', 't +1.0e-1');

    is(new Math::GoldenBigMath('-0.e+0')->GetValue(), '+0e+0', 't -0.e+0');
    is(new Math::GoldenBigMath('-1.e+0')->GetValue(), '-1e+0', 't -1.e+0');
    is(new Math::GoldenBigMath('-0.e-0')->GetValue(), '+0e+0', 't -0.e-0');
    is(new Math::GoldenBigMath('-1.e-0')->GetValue(), '-1e+0', 't -1.e-0');

    is(new Math::GoldenBigMath('123456789')    ->GetValue(), '+123456789e+0',  't 123456789');
    is(new Math::GoldenBigMath('+1234567890')  ->GetValue(), '+123456789e+1', 't +1234567890');
    is(new Math::GoldenBigMath('-001234567890')->GetValue(), '-123456789e+1', 't -001234567890');

    is(new Math::GoldenBigMath('001234567890.000010000') ->GetValue(), '+123456789000001e-5', 't 001234567890.000010000');
    is(new Math::GoldenBigMath('+001234567890.000010000')->GetValue(), '+123456789000001e-5', 't +001234567890.000010000');
    is(new Math::GoldenBigMath('-001234567890.000010000')->GetValue(), '-123456789000001e-5', 't -001234567890.000010000');

    is(new Math::GoldenBigMath('001234567890.000010000e3001')  ->GetValue(), '+123456789000001e+2996',   't 001234567890.000010000e3001');
    is(new Math::GoldenBigMath('+001234567890.000012000e+3002')->GetValue(), '+1234567890000012e+2996',  't +001234567890.000012000e+3002');
    is(new Math::GoldenBigMath('-001234567890.000012300e-3003')->GetValue(), '-12345678900000123e-3010', 't -001234567890.000012300e-3003');
}

# --- Formatting Tests ---------------------------------------------------------
#

sub TestFormatting {

    diag "--- Formatting Tests ---------------------------------------------------------------";

    is(new Math::GoldenBigMath('001234567890.000010000e3001')->MoveDecimalPointToRight(10)->GetValue(),
	   '+1234567890000010000000000e+2986',   't 001234567890.000010000e3001 move right 10');
    is(new Math::GoldenBigMath('+001234567890.000012000e+3002')->MoveDecimalPointToRight(7)->GetValue(),
	   '+12345678900000120000000e+2989',  't +001234567890.000012000e+3002 move right 7');
    is(new Math::GoldenBigMath('-001234567890.000012300e-3003')->MoveDecimalPointToRight(11)->GetValue(),
	   '-1234567890000012300000000000e-3021', 't -001234567890.000012300e-3003 move right 11');

    my $z1 = new Math::GoldenBigMath('1');
    my $z2 = new Math::GoldenBigMath('2');
    is ($z1->AdoptExponents($z2)->GetValue(), '+1e+0', "Adopt  1   2");
    is ($z2->AdoptExponents($z1)->GetValue(), '+2e+0', "Adopt  2   1");

    $z1 = new Math::GoldenBigMath('10');
    is ($z1->AdoptExponents($z2)->GetValue(), '+10e+0', "Adopt 10   2");

    $z1 = new Math::GoldenBigMath('100');
    is ($z2->AdoptExponents($z1)->GetValue(), '+100e+0', "Adopt  2 100");

    $z1 = new Math::GoldenBigMath('0.3');
    is ($z1->AdoptExponents($z2)->GetValue(), '+20e-1', "Adopt 0.3   2");

    $z1 = new Math::GoldenBigMath('0.003');
    is ($z2->AdoptExponents($z1)->GetValue(), '+2000e-3', "Adopt 2   0.003");
}

# --- Comparision Tests --------------------------------------------------------
#

sub TestComparison {
	
	diag "--- Comparison Tests ---------------------------------------------------------------";

    is (Math::GoldenBigMath::Compare( 0,  0),  0, ' 0 == 0');
    is (Math::GoldenBigMath::Compare( 1,  0),  1, ' 1  >  0');
    is (Math::GoldenBigMath::Compare( 0,  1), -1, ' 0  <  1');
    is (Math::GoldenBigMath::Compare( 1,  1),  0, ' 1 ==  1');
    is (Math::GoldenBigMath::Compare( 2,  1),  1, ' 2  >  1');
    is (Math::GoldenBigMath::Compare( 1,  2), -1, ' 1  <  2');
    is (Math::GoldenBigMath::Compare( 9,  9),  0, ' 9 ==  9');
    is (Math::GoldenBigMath::Compare( 9,  1),  1, ' 9  >  1');
    is (Math::GoldenBigMath::Compare( 1,  9), -1, ' 1  <  9');
    is (Math::GoldenBigMath::Compare(10, 10),  0, '10 == 10');
    is (Math::GoldenBigMath::Compare( 9, 10), -1, ' 9  < 10');
    is (Math::GoldenBigMath::Compare(10,  9),  1, '10  >  9');
    is (new Math::GoldenBigMath(10)->Compare(9),  1, '10  >  9');
    is (new Math::GoldenBigMath(10)->Compare(new Math::GoldenBigMath( 9)),  1, '10  >  9');

    is (Math::GoldenBigMath::Compare( 99,  99),  0, ' 99 ==  99');
    is (Math::GoldenBigMath::Compare(100, 100),  0, '100 == 100');
    is (Math::GoldenBigMath::Compare( 99, 100), -1, ' 99  < 100');
    is (Math::GoldenBigMath::Compare(100,  99),  1, '100  >  99');

    my $s1 = '0012345678901234567890';
    my $s2 = '0012345678901234567891';
    my $s3 = '12345678901234567891';
    is (Math::GoldenBigMath::Compare($s2, $s1),  1, "$s2 > $s1");
    is (Math::GoldenBigMath::Compare($s1, $s2), -1, "$s1 < $s2");
    is (Math::GoldenBigMath::Compare($s3, $s1),  1, "  $s3 > $s1");
    is (Math::GoldenBigMath::Compare($s1, $s3), -1, "$s1 <   $s3");

    my $s6 = "+$s1";
    my $s7 = "+$s2";
    my $s8 = "+$s3";
    is (Math::GoldenBigMath::Compare($s2, $s6),  1, "$s2 > $s6");
    is (Math::GoldenBigMath::Compare($s1, $s7), -1, "$s1 < $s7");
    is (Math::GoldenBigMath::Compare($s3, $s6),  1, "  $s3 > $s6");
    is (Math::GoldenBigMath::Compare($s1, $s8), -1, "$s1 <   $s8");

    is (Math::GoldenBigMath::Compare($s7, $s6),  1, "$s7 > $s6");
    is (Math::GoldenBigMath::Compare($s6, $s7), -1, "$s6 < $s7");
    is (Math::GoldenBigMath::Compare($s8, $s6),  1, "  $s8 > $s6");
    is (Math::GoldenBigMath::Compare($s6, $s8), -1, "$s6 <   $s8");

    my $s16 = new Math::GoldenBigMath($s6);
    my $s17 = new Math::GoldenBigMath($s7);
    is (($s16 != $s16), 0, "$s6 == $s6");
    is (($s16 != $s17), 1, "$s6 != $s7");
    is (Math::GoldenBigMath::CompareNotEqual($s16, $s17), 1, "$s6 != $s7");
}

# --- Calc Tests ---------------------------------------------------------------
#

# --- Addition ---
sub TestAddition {

	diag "--- Addition Tests ---------------------------------------------------------------";

    is (Math::GoldenBigMath::Addition(0, 0)->GetValue(),  '+0e+0', '0 + 0'); 
    is (Math::GoldenBigMath::Addition(0, 1)->GetValue(),  '+1e+0', '1 + 0'); 
    is (Math::GoldenBigMath::Addition(1, 0)->GetValue(),  '+1e+0', '0 + 1'); 
    is (Math::GoldenBigMath::Addition(1, 1)->GetValue(),  '+2e+0', '1 + 1'); 
    is (Math::GoldenBigMath::Addition(8, 1)->GetValue(),  '+9e+0', '8 + 1'); 
    is (Math::GoldenBigMath::Addition(1, 8)->GetValue(),  '+9e+0', '1 + 8'); 
    is (Math::GoldenBigMath::Addition(9, 1)->DispenseExponent()->GetValue(), '+10e+0', '9 + 1'); 
    is (Math::GoldenBigMath::Addition(1, 9)->DispenseExponent()->GetValue(), '+10e+0', '1 + 9'); 
    is (Math::GoldenBigMath::Addition(5, 5)->DispenseExponent()->GetValue(), '+10e+0', '5 + 5'); 
    is (Math::GoldenBigMath::Addition(6, 5)->GetValue(), '+11e+0', '6 + 5'); 
    is (Math::GoldenBigMath::Addition(8, 8)->GetValue(), '+16e+0', '8 + 8'); 
    is (new Math::GoldenBigMath(9)->Addition(new Math::GoldenBigMath(9))->GetValue(), '+18e+0', '9 + 9'); 

# is (new Math::GoldenBigMath(-0)->Addition(new Math::GoldenBigMath(-1))->GetValue(),  '-1e+0', '-1 + -0'); 
# is (new Math::GoldenBigMath(-1)->Addition(new Math::GoldenBigMath(-0))->GetValue(),  '-1e+0', '-0 + -1'); 
    is (Math::GoldenBigMath::Addition(-1, -1)->GetValue(),  '-2e+0', '-1 + -1'); 
    is (Math::GoldenBigMath::Addition(-8, -1)->GetValue(),  '-9e+0', '-8 + -1'); 
    is (Math::GoldenBigMath::Addition(-1, -8)->GetValue(),  '-9e+0', '-1 + -8'); 
    is (Math::GoldenBigMath::Addition(-9, -1)->DispenseExponent()->GetValue(), '-10e+0', '-9 + -1'); 
    is (Math::GoldenBigMath::Addition(-1, -9)->DispenseExponent()->GetValue(), '-10e+0', '-1 + -9'); 
    is (Math::GoldenBigMath::Addition(-5, -5)->DispenseExponent()->GetValue(), '-10e+0', '-5 + -5'); 
    is (Math::GoldenBigMath::Addition(-6, -5)->GetValue(), '-11e+0', '-6 + -5'); 
    is (Math::GoldenBigMath::Addition(-8, -8)->GetValue(), '-16e+0', '-8 + -8'); 
    is (Math::GoldenBigMath::Addition(-9, -9)->GetValue(), '-18e+0', '-9 + -9'); 

    is (Math::GoldenBigMath::Addition( 10,   1)->GetValue(),   '+11e+0', ' 10 +   1'); 
    is (Math::GoldenBigMath::Addition( 10,  10)->DispenseExponent()->GetValue(),   '+20e+0', ' 10 +  10'); 
    is (Math::GoldenBigMath::Addition(999,   1)->DispenseExponent()->GetValue(), '+1000e+0', '999 +   1');
    is (Math::GoldenBigMath::Addition(  1, 999)->DispenseExponent()->GetValue(), '+1000e+0', '  1 + 999');
    is (Math::GoldenBigMath::Addition(999,  10)->GetValue(), '+1009e+0', '999 +  10');
    is (Math::GoldenBigMath::Addition( 10, 999)->GetValue(), '+1009e+0', ' 10 + 999');
    is (Math::GoldenBigMath::Addition(999, 999)->GetValue(), '+1998e+0', '999 + 999');

    my $s6 = '+0012345678901234567890';
    my $s7 = '0012345678901234567891';
    my $s8 = '12345678901234567891';

    is (Math::GoldenBigMath::Addition ($s6, $s7)->GetValue(), '+24691357802469135781e+0', "$s6 + $s7");
    is (Math::GoldenBigMath::Addition ($s6, $s8)->GetValue(), '+24691357802469135781e+0', "$s6 + $s8");
    is (Math::GoldenBigMath::Addition ($s7, $s8)->GetValue(), '+24691357802469135782e+0', "$s7 + $s8");

    # --- different signs ---

    $s6 =~ s/\+//o;
    $s8 =~ s/\+//o;

    is (Math::GoldenBigMath::Addition( 1, -1)->GetValue(),  '+0e+0', ' 1 + -1'); 
    is (Math::GoldenBigMath::Addition(-1,  1)->GetValue(),  '+0e+0', '-1 +  1'); 

    is (Math::GoldenBigMath::Addition( 2, -1)->GetValue(),  '+1e+0', ' 2 + -1'); 
    is (Math::GoldenBigMath::Addition(-2,  1)->GetValue(),  '-1e+0', '-2 +  1'); 

    is (Math::GoldenBigMath::Addition( 1, -2)->GetValue(),  '-1e+0', ' 1 + -2'); 
    is (Math::GoldenBigMath::Addition(-1,  2)->GetValue(),  '+1e+0', '-1 +  2'); 

    is (Math::GoldenBigMath::Addition ("+$s6", "-$s7")->GetValue(), '-1e+0', "$s6 + -$s7");
    is (Math::GoldenBigMath::Addition ("+$s6", "-$s8")->GetValue(), '-1e+0', "$s6 + -$s8");
    is (Math::GoldenBigMath::Addition (  $s7,  "-$s8")->GetValue(), '+0e+0', "$s7 + -$s8");

    is (Math::GoldenBigMath::Addition ("-$s6",  "$s7")->GetValue(), '+1e+0', "-$s6 +  $s7");
    is (Math::GoldenBigMath::Addition ("-$s6", "+$s8")->GetValue(), '+1e+0', "-$s6 + +$s8");
    is (Math::GoldenBigMath::Addition ("-$s7", "+$s8")->GetValue(), '+0e+0', "-$s7 + +$s8");

    # --- exp < 0 ---

    my $s10 = '0.1';
    my $s11 = '0.2';
    my $s12 = '0.01';

    is (Math::GoldenBigMath::Addition ($s10, $s11)->GetValue(),  '+3e-1', "$s10 + $s11");
    is (Math::GoldenBigMath::Addition ($s10, $s12)->GetValue(), '+11e-2', "$s10 + $s12");
    is (Math::GoldenBigMath::Addition ($s11, $s12)->GetValue(), '+21e-2', "$s11 + $s12");

    is (Math::GoldenBigMath::Addition ("+$s10", "-$s11")->GetValue(),  '-1e-1', "$s10 + -$s11");
    is (Math::GoldenBigMath::Addition ("+$s10", "-$s12")->GetValue(),  '+9e-2', "$s10 + -$s12");
    is (Math::GoldenBigMath::Addition (  $s11,  "-$s12")->GetValue(), '+19e-2', "$s11 + -$s12");

    is (Math::GoldenBigMath::Addition ("-$s10",  "$s11")->GetValue(),  '+1e-1', "-$s10 +  $s11");
    is (Math::GoldenBigMath::Addition ("-$s10", "+$s12")->GetValue(),  '-9e-2', "-$s10 + +$s12");
    is (Math::GoldenBigMath::Addition ("-$s11", "+$s12")->GetValue(), '-19e-2', "-$s11 + +$s12");

    is (Math::GoldenBigMath::Addition ("+$s6", "+$s12")->GetValue(), '+1234567890123456789001e-2', " $s6 +  $s12");
    is (Math::GoldenBigMath::Addition ("+$s6", "-$s12")->GetValue(), '+1234567890123456788999e-2', " $s6 + -$s12");
    is (Math::GoldenBigMath::Addition ("-$s6", "+$s12")->GetValue(), '-1234567890123456788999e-2', "-$s6 +  $s12");
    is (Math::GoldenBigMath::Addition ("-$s6", "-$s12")->GetValue(), '-1234567890123456789001e-2', "-$s6 + -$s12");

    # AdditionDoubleLoop(113, 111);
    # AdditionDoubleLoop(100, 20);
    # AdditionDoubleLoop( 20, 20);
    # AdditionDoubleLoop( 20, 12);
    # AdditionDoubleLoop( 10, 10);
    AdditionDoubleLoop( 6, 5);

    $a = new Math::GoldenBigMath('001234567890.000010000E+300001');
    $b = new Math::GoldenBigMath('-123456789.00000E+300002');
	
    is( ($a+$b)->GetValue(), '+1e+299996',   'Addition with + operator' );
}

# --- Subtraction ---
sub TestSubtraction {

	diag "--- Subtraction Tests ---------------------------------------------------------------";
	
    is (Math::GoldenBigMath::Subtraction( 0,  0)->GetValue(),  '+0e+0', ' 0 -  0'); 
    is (Math::GoldenBigMath::Subtraction( 0,  1)->GetValue(),  '-1e+0', ' 0 -  1'); 
    is (Math::GoldenBigMath::Subtraction( 1,  0)->GetValue(),  '+1e+0', ' 1 -  0'); 
    is (Math::GoldenBigMath::Subtraction( 1,  1)->GetValue(),  '+0e+0', ' 1 -  1'); 
    is (Math::GoldenBigMath::Subtraction(10,  1)->GetValue(),  '+9e+0', '10 -  1'); 
    is (Math::GoldenBigMath::Subtraction( 1, 10)->GetValue(),  '-9e+0', ' 1 - 10'); 
    is (Math::GoldenBigMath::Subtraction(11,  1)->DispenseExponent()->GetValue(), '+10e+0', '11 -  1'); 
    is (Math::GoldenBigMath::Subtraction( 1, 11)->DispenseExponent()->GetValue(), '-10e+0', ' 1 - 11'); 
    is (Math::GoldenBigMath::Subtraction( 5,  5)->GetValue(),  '+0e+0', ' 5 -  5'); 
    is (Math::GoldenBigMath::Subtraction( 6,  5)->GetValue(),  '+1e+0', ' 6 -  5'); 
    is (Math::GoldenBigMath::Subtraction( 8,  8)->GetValue(),  '+0e+0', ' 8 -  8'); 
    is (new Math::GoldenBigMath(9)->Subtraction(new Math::GoldenBigMath(9))->GetValue(), '+0e+0', '9 - 9'); 

    is (Math::GoldenBigMath::Subtraction(-1, -1)->GetValue(),  '+0e+0', '-1 - -1'); 
    is (Math::GoldenBigMath::Subtraction(-8, -1)->GetValue(),  '-7e+0', '-8 - -1'); 
    is (Math::GoldenBigMath::Subtraction(-1, -8)->GetValue(),  '+7e+0', '-1 - -8'); 
    is (Math::GoldenBigMath::Subtraction(-9, -1)->GetValue(),  '-8e+0', '-9 - -1'); 
    is (Math::GoldenBigMath::Subtraction(-1, -9)->GetValue(),  '+8e+0', '-1 - -9'); 
    is (Math::GoldenBigMath::Subtraction(-5, -5)->GetValue(),  '+0e+0', '-5 - -5'); 
    is (Math::GoldenBigMath::Subtraction(-6, -5)->GetValue(),  '-1e+0', '-6 - -5'); 
    is (Math::GoldenBigMath::Subtraction(-8, -8)->GetValue(),  '+0e+0', '-8 - -8'); 
    is (Math::GoldenBigMath::Subtraction(-9, -9)->GetValue(),  '+0e+0', '-9 - -9'); 

    is (Math::GoldenBigMath::Subtraction( 10,   1)->GetValue(),    '+9e+0', ' 10 -   1'); 
    is (Math::GoldenBigMath::Subtraction( 10,  10)->GetValue(),    '+0e+0', ' 10 -  10'); 
    is (Math::GoldenBigMath::Subtraction(999,   1)->GetValue(),  '+998e+0', '999 -   1');
    is (Math::GoldenBigMath::Subtraction(  1, 999)->GetValue(),  '-998e+0', '  1 - 999');
    is (Math::GoldenBigMath::Subtraction(999,  10)->GetValue(),  '+989e+0', '999 -  10');
    is (Math::GoldenBigMath::Subtraction( 10, 999)->GetValue(),  '-989e+0', ' 10 - 999');
    is (Math::GoldenBigMath::Subtraction(999, 999)->GetValue(),    '+0e+0', '999 - 999');

    my $s6 = '+0012345678901234567890';
    my $s7 = '0012345678901234567891';
    my $s8 = '+12345678901234567891';

    is (Math::GoldenBigMath::Subtraction ($s6, $s7)->GetValue(), '-1e+0', "$s6 - $s7");
    is (Math::GoldenBigMath::Subtraction ($s6, $s8)->GetValue(), '-1e+0', "$s6 - $s8");
    is (Math::GoldenBigMath::Subtraction ($s7, $s8)->GetValue(), '+0e+0', "$s7 - $s8");

    # --- different signs ---

    $s6 =~ s/\+//o;
    $s8 =~ s/\+//o;

    is (Math::GoldenBigMath::Subtraction( 1, -1)->GetValue(),  '+2e+0', ' 1 - -1'); 
    is (Math::GoldenBigMath::Subtraction(-1,  1)->GetValue(),  '-2e+0', '-1 -  1'); 

    is (Math::GoldenBigMath::Subtraction( 2, -1)->GetValue(),  '+3e+0', ' 2 - -1'); 
    is (Math::GoldenBigMath::Subtraction(-2,  1)->GetValue(),  '-3e+0', '-2 -  1'); 

    is (Math::GoldenBigMath::Subtraction( 1, -2)->GetValue(),  '+3e+0', ' 1 - -2'); 
    is (Math::GoldenBigMath::Subtraction(-1,  2)->GetValue(),  '-3e+0', '-1 -  2'); 

    is (Math::GoldenBigMath::Subtraction ("+$s6", "-$s7")->GetValue(), '+24691357802469135781e+0', "$s6 - -$s7");
    is (Math::GoldenBigMath::Subtraction (  $s6,  "-$s8")->GetValue(), '+24691357802469135781e+0', "$s6 - -$s8");
    is (Math::GoldenBigMath::Subtraction ("+$s7", "-$s8")->GetValue(), '+24691357802469135782e+0', "$s7 - -$s8");

    is (Math::GoldenBigMath::Subtraction ("-$s6",  "$s7")->GetValue(), '-24691357802469135781e+0', "-$s6 - $s7");
    is (Math::GoldenBigMath::Subtraction ("-$s6", "+$s8")->GetValue(), '-24691357802469135781e+0', "-$s6 - +$s8");
    is (Math::GoldenBigMath::Subtraction ("-$s7", "+$s8")->GetValue(), '-24691357802469135782e+0', "-$s7 - +$s8");

    # --- exp < 0 ---

    my $s10 = '0.1';
    my $s11 = '0.2';
    my $s12 = '0.01';

    is (Math::GoldenBigMath::Subtraction ($s10, $s11)->GetValue(),  '-1e-1', "$s10 - $s11");
    is (Math::GoldenBigMath::Subtraction ($s10, $s12)->GetValue(),  '+9e-2', "$s10 - $s12");
    is (Math::GoldenBigMath::Subtraction ($s11, $s12)->GetValue(), '+19e-2', "$s11 - $s12");

    is (Math::GoldenBigMath::Subtraction ("+$s10", "-$s11")->GetValue(),  '+3e-1', "$s10 - -$s11");
    is (Math::GoldenBigMath::Subtraction ("+$s10", "-$s12")->GetValue(), '+11e-2', "$s10 - -$s12");
    is (Math::GoldenBigMath::Subtraction (  $s11,  "-$s12")->GetValue(), '+21e-2', "$s11 - -$s12");

    is (Math::GoldenBigMath::Subtraction ("-$s10",  "$s11")->GetValue(),  '-3e-1', "-$s10 - $s11");
    is (Math::GoldenBigMath::Subtraction ("-$s10", "+$s12")->GetValue(), '-11e-2', "-$s10 - $s12");
    is (Math::GoldenBigMath::Subtraction ("-$s11", "+$s12")->GetValue(), '-21e-2', "-$s11 - $s12");

    is (Math::GoldenBigMath::Subtraction ("+$s6", "-$s12")->GetValue(), '+1234567890123456789001e-2', " $s6 - -$s12");
    is (Math::GoldenBigMath::Subtraction ("+$s6", "+$s12")->GetValue(), '+1234567890123456788999e-2', " $s6 -  $s12");
    is (Math::GoldenBigMath::Subtraction ("-$s6", "-$s12")->GetValue(), '-1234567890123456788999e-2', "-$s6 - -$s12");
    is (Math::GoldenBigMath::Subtraction ("-$s6", "+$s12")->GetValue(), '-1234567890123456789001e-2', "-$s6 -  $s12");
}

# --- to test the internal method creating a multiplication table
sub TestBuildMultiplicationTableAsString {

	diag "--- MultiplicationTable Tests ---------------------------------------------------------------";

    foreach my $i(0..23, 1237, 31415927) { # , 1234567890123) {
		is_deeply (Math::GoldenBigMath::buildMultiplicationTableAsString($i), BuildMultiplikationTable($i), " * table $i");
    } 

}

# --- Test Multiplication ---
sub TestMultiplication {

	diag "--- Multiplication Tests ---------------------------------------------------------------";

    is (Math::GoldenBigMath::Multiplication(0, 0)->GetValue(),  '+0e+0', '0 * 0'); 
    is (Math::GoldenBigMath::Multiplication(0, 1)->GetValue(),  '+0e+0', '1 * 0'); 
    is (Math::GoldenBigMath::Multiplication(1, 0)->GetValue(),  '+0e+0', '0 * 1'); 
    is (Math::GoldenBigMath::Multiplication(1, 1)->GetValue(),  '+1e+0', '1 * 1'); 
    is (Math::GoldenBigMath::Multiplication(1, 2)->GetValue(),  '+2e+0', '2 * 1'); 
    is (Math::GoldenBigMath::Multiplication(2, 1)->GetValue(),  '+2e+0', '1 * 2'); 
    is (Math::GoldenBigMath::Multiplication(8, 1)->GetValue(),  '+8e+0', '8 * 1'); 
    is (Math::GoldenBigMath::Multiplication(1, 8)->GetValue(),  '+8e+0', '1 * 8'); 
    is (Math::GoldenBigMath::Multiplication(9, 1)->GetValue(),  '+9e+0', '9 * 1'); 
    is (Math::GoldenBigMath::Multiplication(1, 9)->GetValue(),  '+9e+0', '1 * 9'); 
    is (Math::GoldenBigMath::Multiplication(5, 5)->GetValue(), '+25e+0', '5 * 5'); 
    is (Math::GoldenBigMath::Multiplication(6, 5)->GetValue(), '+3e+1', '6 * 5'); 
    is (Math::GoldenBigMath::Multiplication(8, 8)->GetValue(), '+64e+0', '8 * 8'); 
    is (new Math::GoldenBigMath(9)->Multiplication(new Math::GoldenBigMath(9))->GetValue(), '+81e+0', '9 * 9'); 
    is (Math::GoldenBigMath::Multiplication(13, 13)->GetValue(), '+169e+0', '13 * 13'); 

    is (Math::GoldenBigMath::Multiplication(    20,    300)->GetValue(), '+6e+3', '20    * 300');
    is (Math::GoldenBigMath::Multiplication("2e+1", "3e+2")->GetValue(), '+6e+3', ' 2e+1 *   3e+2');
    is (Math::GoldenBigMath::Multiplication("2e-1", "3e+2")->GetValue(), '+6e+1', ' 2e-1 *   3e+2');
    is (Math::GoldenBigMath::Multiplication( "0.2", "3e+2")->GetValue(), '+6e+1', ' 0.2  *   3e+2');
    is (Math::GoldenBigMath::Multiplication( "0.2",    300)->GetValue(), '+6e+1', ' 0.2  * 300');

    is (Math::GoldenBigMath::Multiplication(-1,  1)->GetValue(),  '-1e+0', '-1 *  1'); 
    is (Math::GoldenBigMath::Multiplication( 1, -1)->GetValue(),  '-1e+0', ' 1 * -1'); 
    is (Math::GoldenBigMath::Multiplication(-1, -1)->GetValue(),  '+1e+0', '-1 * -1');

    is (Math::GoldenBigMath::Multiplication(-2,  3)->GetValue(),  '-6e+0', '-2 *  3'); 
    is (Math::GoldenBigMath::Multiplication( 2, -3)->GetValue(),  '-6e+0', ' 2 * -3'); 
    is (Math::GoldenBigMath::Multiplication(-2, -3)->GetValue(),  '+6e+0', '-2 * -3');

    # MultiplicationDoubleLoop(113, 111);
    # MultiplicationDoubleLoop(100, 20);
    # MultiplicationDoubleLoop( 20, 20);
    # MultiplicationDoubleLoop( 20, 12);
    # MultiplicationDoubleLoop( 10, 10);
    MultiplicationDoubleLoop( 6, 5);

    my $z1 = '-31415927648267462591273462582862183462864e+34749';
    my $z2 =  '31415927648233578991273593972431987216509e-34601';
    my $result = '-986960510000111498010000221938758854367349836296579810447230672656288710129221776e+148';
    
    is (Math::GoldenBigMath::Multiplication
	($z1, $z2) ->GetValue(), $result, "$z1 * $z2 \n    = $result");

}

# --- Test operators + - * / < <= > >= <=>
sub TestOperators {

	diag "--- Operator Tests ---------------------------------------------------------------";

    my $gbm1 = new Math::GoldenBigMath(1);
    my $gbm2 = new Math::GoldenBigMath(2);

    ok ($gbm1 <  $gbm2, '1 <  2');
    ok ($gbm1 <= $gbm1, '1 <= 1');
    ok ($gbm1 <= $gbm2, '1 <= 2');

    ok ($gbm2 >  $gbm1, '2 >  1');
    ok ($gbm2 >= $gbm1, '2 >= 1');

    ok ($gbm2 == $gbm2, '2 == 2');
    ok ($gbm1 != $gbm2, '1 != 2');

    is ($gbm1 <=> $gbm2, -1, '1 <=> 2');
    is ($gbm2 <=> $gbm2,  0, '2 <=> 2');
    is ($gbm2 <=> $gbm1,  1, '2 <=> 1');

    is (($gbm1 + $gbm2)->GetValue(), '+3e+0', ' 1 + 2'); 
    is (($gbm1 - $gbm2)->GetValue(), '-1e+0', ' 1 - 2'); 
    is (($gbm1 * $gbm2)->GetValue(), '+2e+0', ' 1 * 2'); 
    # is (($gbm1 / $gbm2)->GetValue(), '+3e+0', ' 1 + 2'); 
    # is (($gbm1 % $gbm2)->GetValue(), '+3e+0', ' 1 + 2'); 

    is ("$gbm1 , $gbm2", '+1e+0 , +2e+0', '$string = "$gbm1 , $gbm2"');
}

# --- End of tests ---------------------------------------------------------------

sub BuildMultiplikationTable {
    my $z = shift;

    my @result;
    foreach my $i (0..9) {
	$result[$i] = $i * $z;
    }

    return \@result;
}

# --- Addition loop ---------------------------------------------------------------
sub AdditionDoubleLoop {
    my $maxOuter = shift;
    my $maxInner = shift;
    
    my $innerEnd;
    my $result;
    my $sum;
    
    foreach my $z1 (0..$maxOuter) {
	$innerEnd = $maxInner;
	$innerEnd = $z1 if $z1 < $innerEnd;
	foreach my $z2 (0..$innerEnd) {
	    $sum = $z1 + $z2;
	    $result = new Math::GoldenBigMath($z1)->Addition(new Math::GoldenBigMath($z2))->GetValue();
	    is ($result, new Math::GoldenBigMath("+${sum}e+0")->GetValue(), "Addition loop $z1 + $z2 = $result");
	    
	    # print "Ä \$result = new Math::GoldenBigMath($z1)->Addition(new Math::GoldenBigMath($z2))->GetValue();\n";
	    # print 'Ä is ($result, '."'+${sum}e+0', '$z1 + $z2 = $result');\n";
	    # print "Ä \n";
	    # print "Ä \$result = new Math::GoldenBigMath($z2)->Addition(new Math::GoldenBigMath($z1))->GetValue();\n";
	    # print 'Ä is ($result, '."'+${sum}e+0', '$z2 + $z1 = $result');\n";
	    # print "Ä # ---\n";

	    next if $z1 eq $z2;
	    
	    $result = new Math::GoldenBigMath($z2)->Addition(new Math::GoldenBigMath($z1))->GetValue();
	    is ($result, new Math::GoldenBigMath("+${sum}e+0")->GetValue(), "Addition loop $z2 + $z1 = $result");
	}
    }
}

# --- Multiplication loop ---------------------------------------------------------------
sub MultiplicationDoubleLoop {
    my $maxOuter = shift;
    my $maxInner = shift;
    
    my $innerEnd;
    my $result;
    my $mul;
    
    foreach my $z1 (0..$maxOuter) {
	$innerEnd = $maxInner;
	$innerEnd = $z1 if $z1 < $innerEnd;
	foreach my $z2 (0..$innerEnd) {
	    $mul = $z1 * $z2;
	    $result = new Math::GoldenBigMath($z1)->Multiplication(new Math::GoldenBigMath($z2))->GetValue();
	    is ($result, new Math::GoldenBigMath("+${mul}e+0")->GetValue(), "Multiplication loop $z1 * $z2 = $result");
	    
	    # print "Ä \$result = new Math::GoldenBigMath($z1)->Multiplication(new Math::GoldenBigMath($z2))->GetValue();\n";
	    # print 'Ä is ($result, '."'+${mul}e+0', '$z1 + $z2 = $result');\n";
	    # print "Ä \n";
	    # print "Ä \$result = new Math::GoldenBigMath($z2)->Multiplication(new Math::GoldenBigMath($z1))->GetValue();\n";
	    # print 'Ä is ($result, '."'+${mul}e+0', '$z2 + $z1 = $result');\n";
	    # print "Ä # ---\n";

	    next if $z1 eq $z2;
	    
	    $result = new Math::GoldenBigMath($z2)->Multiplication(new Math::GoldenBigMath($z1))->GetValue();
	    is ($result, new Math::GoldenBigMath("+${mul}e+0")->GetValue(), "Multiplication loop $z2 * $z1 = $result");
	}
    }
}


