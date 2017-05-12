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
    10 print "It did "; : print "not ";
    20 print "fail. ";
    30 for a = 1 to 3 : gosub 50 : next a
    40 END
    50 print a;
    60 return
ENDCODE
$expected = "It did not fail. 1 2 3 ";
&setup_test($code, $expected);

&perform_tests;
