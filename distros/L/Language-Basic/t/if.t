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
    25 REM IF with THEN but no else
    30 if 2>1 then print "Not ";
    40 print "Incorrect";
    50 print " IF with THEN"
ENDCODE
$expected = "Not Incorrect IF with THEN\n";
&setup_test($code, $expected);

$code =<<'ENDCODE';
    5 REM IF with THEN and ELSE
    10 if 2>1 then print "Correct"; else print "Incorrect";
    20 print " IF with THEN/ELSE"
ENDCODE
$expected = "Correct IF with THEN/ELSE\n";
&setup_test($code, $expected);

$code =<<'ENDCODE';
    10 REM implied goto
    20 if 2>1 then 40
    30 print "Incorrect";
    35 goto 50
    40 print "Correct";
    45 print " and ";
    50 if 1>2 then goto 110 else 90
    70 print "not ";
    90 print "correct implied goto"
    100 end
    110 print "If we got here, there's a problem with IF"
ENDCODE
$expected = "Correct and correct implied goto\n";
&setup_test($code, $expected);

&perform_tests;
