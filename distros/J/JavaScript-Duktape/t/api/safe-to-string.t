use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub init_test_values {
    $duk->set_top(0);

    # Simple */
    $duk->push_int(123);

    # Object with toString() */
    $duk->eval_string("({ toString: function () { return 'toString result'; } })");

    # toString() throws an error */
    $duk->eval_string("({ toString: function () { throw new Error('toString error'); } })");

    # toString() throws an error which cannot be string coerced */
    $duk->eval_string("({ toString: function () { var e = new Error('cannot string coerce me');"
                        . "                           e.toString = function () { throw new Error('coercion error'); };"
                        . "                           throw e; } })");

    # XXX: add an infinite loop and timeout case */
}

sub test_1 {

    # $duk->safe_to_string() */
    init_test_values();
    my $n = $duk->get_top();
    for (my $i = 0; $i < $n; $i++) {
        printf("top=%ld\n", $duk->get_top());
        printf("duk_safe_to_string[%ld] = '%s'\n", $i, $duk->safe_to_string($i));
    }

    # $duk->safe_to_lstring() with NULL arg */
    init_test_values();
    $n = $duk->get_top();
    for (my $i = 0; $i < $n; $i++) {
        printf("top=%ld\n", $duk->get_top());
        my $str = $duk->safe_to_lstring($i, my $t);
        printf("duk_safe_to_lstring_null[%ld] = '%s'\n", $i, $str);
    }

    # $duk->safe_to_lstring() */
    init_test_values();
    $n = $duk->get_top();
    for (my $i = 0; $i < $n; $i++) {
        my $len;
        printf("top=%ld\n", $duk->get_top());
        my $str = $duk->safe_to_lstring($i, $len);
        printf("duk_safe_to_lstring[%ld] = '%s', len %lu\n", $i, $str, $len);
    }

    # $duk->safe_to_lstring() with negative stack indices */
    init_test_values();
    $n = $duk->get_top();
    for (my $i = 0; $i < $n; $i++) {
        my $len;
        printf("top=%ld\n", $duk->get_top());
        my $str = $duk->safe_to_lstring(-4 + $i, $len);
        printf("duk_safe_to_lstring[%ld] = '%s', len %lu\n", $i, $str, $len);
    }

    return 0;
}

TEST_SAFE_CALL($duk, \&test_1, 'test_1');


test_stdout();

__DATA__
*** test_1 (duk_safe_call)
top=4
duk_safe_to_string[0] = '123'
top=4
duk_safe_to_string[1] = 'toString result'
top=4
duk_safe_to_string[2] = 'Error: toString error'
top=4
duk_safe_to_string[3] = 'Error'
top=4
duk_safe_to_lstring_null[0] = '123'
top=4
duk_safe_to_lstring_null[1] = 'toString result'
top=4
duk_safe_to_lstring_null[2] = 'Error: toString error'
top=4
duk_safe_to_lstring_null[3] = 'Error'
top=4
duk_safe_to_lstring[0] = '123', len 3
top=4
duk_safe_to_lstring[1] = 'toString result', len 15
top=4
duk_safe_to_lstring[2] = 'Error: toString error', len 21
top=4
duk_safe_to_lstring[3] = 'Error', len 5
top=4
duk_safe_to_lstring[0] = '123', len 3
top=4
duk_safe_to_lstring[1] = 'toString result', len 15
top=4
duk_safe_to_lstring[2] = 'Error: toString error', len 21
top=4
duk_safe_to_lstring[3] = 'Error', len 5
==> rc=0, result='undefined'
