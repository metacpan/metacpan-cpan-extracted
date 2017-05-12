use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

SET_PRINT_METHOD($duk);

sub test_string {
    my $rc;

    $duk->eval_string("print('Hello world!'); 123;");
    printf("return value is: %lf\n", $duk->get_number(-1));
    $duk->pop();

    $duk->eval_string("'testString'.toUpperCase()");
    printf("result is: '%s'\n", $duk->get_string(-1));
    $duk->pop();

    $rc = $duk->peval_string("print('Hello world!'); 123;");
    printf("return value is: %s (rc=%ld)\n", $duk->safe_to_string(-1), $rc);
    $duk->pop();

    $rc = $duk->peval_string("throw new Error('eval error');");
    printf("return value is: %s (rc=%ld)\n", $duk->safe_to_string(-1), $rc);
    $duk->pop();

    $rc = $duk->peval_string("throw new Error('eval error'); obj = {");
    printf("return value is: %s (rc=%ld)\n", $duk->safe_to_string(-1), $rc);
    $duk->pop();

    #noresult variants */

    printf("top=%ld\n", $duk->get_top());
    $duk->eval_string_noresult("print('Hello world!'); 123;");

    printf("top=%ld\n", $duk->get_top());
    $rc = $duk->peval_string_noresult("print('Hello world!'); 123;");
    printf("no result, rc=%ld\n", $rc);

    printf("top=%ld\n", $duk->get_top());
    $rc = $duk->peval_string_noresult("print('Hello world!'); obj = {");
    printf("no result, rc=%ld\n", $rc);

    printf("top: %ld\n", $duk->get_top());
    return 0;
}

sub test_lstring {
    my $rc;
    my $src1 = "print('Hello world!'); 123;@";
    my $src2 = "'testString'.toUpperCase()@";
    my $src3 = "throw new Error('eval error');@";
    my $src4 = "throw new Error('eval error'); obj = {@";
    my $src5 = "print('Hello world!'); obj = {@";

    $duk->eval_lstring($src1, length($src1) - 1);
    printf("return value is: %lf\n", $duk->get_number(-1));
    $duk->pop();

    $duk->eval_lstring($src2, length($src2) - 1);
    printf("result is: '%s'\n", $duk->get_string(-1));
    $duk->pop();

    $rc = $duk->peval_lstring($src1, length($src1) - 1);
    printf("return value is: %s (rc=%ld)\n", $duk->safe_to_string(-1), $rc);
    $duk->pop();

    $rc = $duk->peval_lstring($src3, length($src3) - 1);
    printf("return value is: %s (rc=%ld)\n", $duk->safe_to_string(-1), $rc);
    $duk->pop();

    $rc = $duk->peval_lstring($src4, length($src4) - 1);
    printf("return value is: %s (rc=%ld)\n", $duk->safe_to_string(-1), $rc);
    $duk->pop();

    #noresult variants */

    printf("top=%ld\n", $duk->get_top());
    $duk->eval_lstring_noresult($src1, length($src1) - 1);

    printf("top=%ld\n", $duk->get_top());
    $rc = $duk->peval_lstring_noresult($src1, length($src1) - 1);
    printf("no result, rc=%ld\n", $rc);

    printf("top=%ld\n", $duk->get_top());
    $rc = $duk->peval_lstring_noresult($src5, length($src5) - 1);
    printf("no result, rc=%ld\n", $rc);

    printf("top: %ld\n", $duk->get_top());
    return 0;
}


TEST_SAFE_CALL($duk, \&test_string, 'test_string');
TEST_SAFE_CALL($duk, \&test_lstring, 'test_lstring');

test_stdout();

__DATA__
*** test_string (duk_safe_call)
Hello world!
return value is: 123.000000
result is: 'TESTSTRING'
Hello world!
return value is: 123 (rc=0)
return value is: Error: eval error (rc=1)
return value is: SyntaxError: invalid object literal (line 1) (rc=1)
top=0
Hello world!
top=0
Hello world!
no result, rc=0
top=0
no result, rc=1
top: 0
==> rc=0, result='undefined'
*** test_lstring (duk_safe_call)
Hello world!
return value is: 123.000000
result is: 'TESTSTRING'
Hello world!
return value is: 123 (rc=0)
return value is: Error: eval error (rc=1)
return value is: SyntaxError: invalid object literal (line 1) (rc=1)
top=0
Hello world!
top=0
Hello world!
no result, rc=0
top=0
no result, rc=1
top: 0
==> rc=0, result='undefined'
