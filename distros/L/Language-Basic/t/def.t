# Test script for Language::Basic.
# Uses tools from testbasic.pl, which allow it to run under Test::Harness
# $code is a BASIC program, $expected is its expected output (including \n's!)
# Call &setup_test for each $code,$expected pair.
# Then call &perform_tests at the end.

# Include subs
push @INC, "t";
do 'testbasic.pl';

my ($code, $expected); # one program & its expected outpt

# Use single quotes because of "$" et al.
$code =<<'ENDCODE';
    10 def fnx(a) = a*2
    20 b = 3
    30 print fnx(b); fnx(fnx(b));
    40 def fny(c, d) = c+d
    50 print fnx(fny(1,1));
    60 def fnz(e) = 3
    70 print fnz(1); fnz(2);
ENDCODE
$expected = "6 12 4 3 3 ";
&setup_test($code, $expected);

&perform_tests;
