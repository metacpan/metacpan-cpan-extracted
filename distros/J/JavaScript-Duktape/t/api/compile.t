use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

SET_PRINT_METHOD($duk);

sub test_1 {
    $duk->set_top(0);

    $duk->push_string("print('program');\n"
                        . "function hello() { print('Hello world!'); }\n"
                        . "123;");
    $duk->push_string("program");
    $duk->compile(0);
    $duk->call(0);      # [ func filename ] -> [ result ] */
    printf("program result: %lf\n", $duk->get_number(-1));
    $duk->pop();

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_2 {
    $duk->set_top(0);

    $duk->push_string("2+3");
    $duk->push_string("eval");
    $duk->compile(DUK_COMPILE_EVAL);
    $duk->call(0);      # [ func ] -> [ result ] */
    printf("eval result: %lf\n", $duk->get_number(-1));
    $duk->pop();

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_3 {
    $duk->set_top(0);

    $duk->push_string("function (x,y) { return x+y; }");
    $duk->push_string("function");
    $duk->compile(DUK_COMPILE_FUNCTION);
    $duk->push_int(5);
    $duk->push_int(6);
    $duk->call(2);      # [ func 5 6 ] -> [ result ] */
    printf("function result: %lf\n", $duk->get_number(-1));
    $duk->pop();

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_4 {

    $duk->set_top(0);

    # SyntaxError while compiling */

    $duk->push_string("print('program');\n"
                        . "function hello() { print('Hello world!'); }\n"
                        . "123; obj={");
    $duk->push_string("program");
    my $rc = $duk->pcompile(0);
    printf("compile result: %s (rc=%d)\n", $duk->safe_to_string(-1), $rc);
    $duk->pop();

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}


TEST_SAFE_CALL($duk, \&test_1, 'test_1');
TEST_SAFE_CALL($duk, \&test_2, 'test_2');
TEST_SAFE_CALL($duk, \&test_3, 'test_3');
TEST_SAFE_CALL($duk, \&test_4, 'test_4');

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
program
program result: 123.000000
final top: 0
==> rc=0, result='undefined'
*** test_2 (duk_safe_call)
eval result: 5.000000
final top: 0
==> rc=0, result='undefined'
*** test_3 (duk_safe_call)
function result: 11.000000
final top: 0
==> rc=0, result='undefined'
*** test_4 (duk_safe_call)
compile result: SyntaxError: invalid object literal (line 3) (rc=1)
final top: 0
==> rc=0, result='undefined'
