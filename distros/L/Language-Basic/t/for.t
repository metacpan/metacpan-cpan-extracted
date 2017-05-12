# Test script for Language::Basic.
# Uses tools from testbasic.pl, which allow it to run under Test::Harness
# $code is a BASIC program, $expected is its expected output (note whitespace!)
# Call &setup_test for each $code,$expected pair.
# Then call &perform_tests at the end.

# Include subs
push @INC, "t";
do 'testbasic.pl';

my ($code, $expected); # one program & its expected outpt

# Use single quotes because of "$" et al.
$code =<<'ENDCODE';
    10 for x = 1 to 3
    20 print x;
    30 next x
ENDCODE
$expected = "1 2 3 ";
&setup_test($code, $expected);

$code =<<'ENDCODE';
    10 for x = 3 to 1 step -1
    20 print x;
    30 next x
ENDCODE
$expected = "3 2 1 ";
&setup_test($code, $expected);

&perform_tests;
