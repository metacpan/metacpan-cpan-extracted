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
    10 read a
    20 read b$, c, d$, e
    30 print a; b$; c; d$; e;
    40 data 1, "+ "
    50 data 1, "is ", 2
ENDCODE
$expected = "1 + 1 is 2 ";
&setup_test($code, $expected);

&perform_tests;
