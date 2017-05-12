# Test script for Language::Basic.
# Uses tools from testbasic.pl, which allow it to run under Test::Harness
# $code is a BASIC program, $expected is its expected output (note whitespace!)
# Call &setup_test for each $code,$expected pair.
# Then call &perform_tests at the end.

# Include subs. Need to add "t" to @INC, because "make test" invokes this test
# with "perl t/whatever.t" and testbasic.pl is in t
push @INC, "t"; 
do 'testbasic.pl' or die "can't find testbasic.pl";

my ($code, $expected); # one program & its expected outpt

$code =<<'ENDCODE';
    10 dim c(100), d(2, 2, 2)
    20 a(5) = 95
    30 b$(5) = "is "
    40 print a(5); b$(5);
    50 for e = 90 to 100
    60 c(e) = e
    70 next e
    80 print c(95)
    90 d(1,1,1) = 3
    100 print d(1,1,1);
ENDCODE
$expected = "95 is 95\n3 ";
&setup_test($code, $expected);

&perform_tests;
