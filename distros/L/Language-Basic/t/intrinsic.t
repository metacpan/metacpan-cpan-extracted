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
    10 print int(3.5);
    20 print mid$("Just another Perl hacker,", 14, 4);
    30 print chr$(34);
ENDCODE
$expected = "3 Perl\"";
&setup_test($code, $expected);

&perform_tests;
