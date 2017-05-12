use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

SET_PRINT_METHOD($duk);

sub test_1 {
    my $duk = shift;
    $duk->set_top(0);
    $duk->eval_string("({ myfunc: function(x,y,z) { print(this); return x+y+z; } })");
    $duk->push_string("myfunc");
    $duk->push_int(10);
    $duk->push_int(11);
    $duk->push_int(12);
    $duk->push_int(13); #clipped
    $duk->push_int(14); # clipped
    # [ ... obj "myfunc" 10 11 12 13 14 ]
    $duk->call_prop(0, 5);
    # [ ... obj res ]
    printf("result=%s\n", $duk->to_string(-1));
    $duk->pop();
    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_2 {
    my $duk = shift;
    # $duk->require_string(-2);
    $duk->set_top(0);
    $duk->eval_string("({ myfunc: function(x,y,z) { print(this); throw(new Error('my error')); } })");
    $duk->push_string("myfunc");
    $duk->push_int(10);
    $duk->push_int(11);
    $duk->push_int(12);
    $duk->push_int(13); # clipped
    $duk->push_int(14); # clipped
    # [ ... obj "myfunc" 10 11 12 13 14 ]
    $duk->call_prop(0, 5);
    # [ ... obj res ]
    printf("result=%s\n", $duk->safe_to_string(-1));
    $duk->pop();
    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_3 {
    my $duk = shift;
    $duk->set_top(0);
    # /* Use Number.prototype to stash new functions, and call "through" a
    # * plain number value. The 'this' binding is initially the plain number.
    # * A strict function gets the plain number as is, a non-strict function
    # * gets an object coerced version.
    # *
    # * NOTE: the strictness of the calling Duktape/C context is no longer
    # * inherited to the eval code in Duktape 0.12.0, so both strict and
    # * non-strict eval code can be evaluated.
    # */
    $duk->eval_string("Number.prototype.myfunc1 = function() { print(typeof this, this, Object.prototype.toString.call(this)); };");
    $duk->pop();
    $duk->eval_string("Number.prototype.myfunc2 = function() { 'use strict'; print(typeof this, this, Object.prototype.toString.call(this)); };");
    $duk->pop();
    $duk->push_int(1); # use '1' as 'obj' */
    $duk->push_string("myfunc1"); # -> [ ... obj "myfunc1" ] */
    $duk->call_prop(0, 0); # -> [ ... obj res ] */
    printf("result=%s\n", $duk->to_string(-1));
    $duk->pop();
    $duk->push_string("myfunc2"); # -> [ ... obj "myfunc2" ] */
    $duk->call_prop(0, 0); # -> [ ... obj res ] */
    printf("result=%s\n", $duk->to_string(-1));
    $duk->pop();
    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

TEST_SAFE_CALL($duk, \&test_1, 'test_1');
TEST_SAFE_CALL($duk, \&test_2, 'test_2');
TEST_SAFE_CALL($duk, \&test_3, 'test_3');


test_stdout();


__DATA__
*** test_1 (duk_safe_call)
[object Object]
result=33
final top: 1
==> rc=0, result='undefined'
*** test_2 (duk_safe_call)
[object Object]
==> rc=1, result='Error: my error'
*** test_3 (duk_safe_call)
object 1 [object Number]
result=undefined
number 1 [object Number]
result=undefined
final top: 1
==> rc=0, result='undefined'
