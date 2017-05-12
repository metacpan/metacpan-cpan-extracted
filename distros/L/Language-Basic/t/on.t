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
    10 for a = 3 to 1 step -1
    20 on a gosub 100, 200, 300
    30 next a
    40 print "After gosubs"
    50 end
    100 print "Third gosub"
    110 return
    200 print "Second gosub and ";
    210 return
    300 print "First gosub and ";
    310 return
ENDCODE
$expected = "First gosub and Second gosub and Third gosub\nAfter gosubs\n";
&setup_test($code, $expected);

&perform_tests;
