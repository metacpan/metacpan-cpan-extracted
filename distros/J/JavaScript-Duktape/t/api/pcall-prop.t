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
    # basic success case: own property
    $duk->eval_string("({ name: 'me', foo: function (x,y) { print(this.name); return x+y; } })");  # idx 1
    $duk->push_string("foo");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(1, 2);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_2 {

    # use plain number as 'this', add function to Number.prototype; non-strict handler
    #causes this to be coerced to Number.

    $duk->eval_string("Number.prototype.func_nonstrict = function (x,y) { print(typeof this, this); return x+y; };");
    $duk->pop();  # pop result
    $duk->push_int(123);  # obj
    $duk->push_string("func_nonstrict");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(-4, 2);  # use relative index for a change
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_3 {

    # use plain number as 'this', add function to Number.prototype; strict handler
    #causes this to remain a plain number.

    $duk->eval_string("Number.prototype.func_strict = function (x,y) { 'use strict'; print(typeof this, this); return x+y; };");
    $duk->pop();  # pop result
    $duk->push_int(123);  # obj
    $duk->push_string("func_strict");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(1, 2);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_4 {

    # basic error case
    $duk->eval_string("({ name: 'me', foo: function (x,y) { throw new Error('my error'); } })");  # idx 1
    $duk->push_string("foo");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(1, 2);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_5 {

    # property lookup fails: base value does not allow property lookup
    $duk->push_undefined();
    $duk->push_string("foo");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(1, 2);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_6 {

    # property lookup fails: getter throws
    $duk->eval_string("({ get prop() { throw new RangeError('getter error'); } })");
    $duk->push_string("prop");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(1, 2);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_7 {

    # invalid object index
    $duk->eval_string("({ foo: 1, bar: 2 })");
    $duk->push_string("foo");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(-6, 2);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_8 {

    # invalid arg count, causes 'key' to be identified with the object in the stack
    $duk->eval_string("({ foo: function () { print('foo called'); } })");
    $duk->push_string("foo");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(1, 3);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

sub test_9 {

    # Invalid arg count, 'key' would be below start of stack.  This
    # results in an actual (uncaught) error at the moment, and matches
    # the behavior of other protected call API functions.

    $duk->eval_string("({ foo: function () { print('foo called'); } })");
    $duk->push_string("foo");
    $duk->push_int(10);
    $duk->push_int(11);
    my $rc = $duk->pcall_prop(1, 8);
    printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
    $duk->pop();  # res
    $duk->pop();  # obj

    return 0;
}

$duk->push_string("foo");

TEST_SAFE_CALL($duk, \&test_1, 'test_1');
TEST_SAFE_CALL($duk, \&test_2, 'test_2');
TEST_SAFE_CALL($duk, \&test_3, 'test_3');
TEST_SAFE_CALL($duk, \&test_4, 'test_4');
TEST_SAFE_CALL($duk, \&test_5, 'test_5');
TEST_SAFE_CALL($duk, \&test_6, 'test_6');
TEST_SAFE_CALL($duk, \&test_7, 'test_7');
TEST_SAFE_CALL($duk, \&test_8, 'test_8');
TEST_SAFE_CALL($duk, \&test_9, 'test_9');

$duk->pop();  # dummy */

printf("final top: %ld\n", $duk->get_top());

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
me
rc=0, result='21'
==> rc=0, result='undefined'
*** test_2 (duk_safe_call)
object 123
rc=0, result='21'
==> rc=0, result='undefined'
*** test_3 (duk_safe_call)
number 123
rc=0, result='21'
==> rc=0, result='undefined'
*** test_4 (duk_safe_call)
rc=1, result='Error: my error'
==> rc=0, result='undefined'
*** test_5 (duk_safe_call)
rc=1, result='TypeError: cannot read property 'foo' of undefined'
==> rc=0, result='undefined'
*** test_6 (duk_safe_call)
rc=1, result='RangeError: getter error'
==> rc=0, result='undefined'
*** test_7 (duk_safe_call)
rc=1, result='RangeError: invalid stack index -6'
==> rc=0, result='undefined'
*** test_8 (duk_safe_call)
rc=1, result='TypeError: undefined not callable'
==> rc=0, result='undefined'
*** test_9 (duk_safe_call)
==> rc=1, result='TypeError: invalid args'
final top: 0
