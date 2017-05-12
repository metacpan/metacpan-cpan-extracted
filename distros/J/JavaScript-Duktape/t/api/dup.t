use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';


my $NONEXISTENT_FILE = '/this/file/doesnt/exist';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;


sub test_1 {

    $duk->set_top(0);

    $duk->push_int(123);

    $duk->push_int(234);
    $duk->dup(-2);  #-> [ 123 234 123 ] */
    $duk->dup_top();  # -> [ 123 234 123 123 ] */

    my $n =  $duk->get_top();
    for (my $i = 0; $i < $n; $i++) {
        printf("%ld: %s\n", $i, $duk->to_string($i));
    }

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_2a {
    $duk->set_top(0);

    $duk->push_int(123);
    $duk->push_int(234);
    $duk->dup(-3);  # out of bounds

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_2b {
    $duk->set_top(0);

    $duk->push_int(123);
    $duk->push_int(234);
    $duk->dup(2);  # out of bounds */

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_2c {
    $duk->set_top(0);

    $duk->push_int(123);
    $duk->push_int(234);
    $duk->dup(-2147483648); #invalid index

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

sub test_3a {
    $duk->set_top(0);

    $duk->dup_top();  #empty

    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

TEST_SAFE_CALL($duk, \&test_1, 'test_1');
TEST_SAFE_CALL($duk, \&test_2a, 'test_2a');
TEST_SAFE_CALL($duk, \&test_2b, 'test_2b');
TEST_SAFE_CALL($duk, \&test_2c, 'test_2c');
TEST_SAFE_CALL($duk, \&test_3a, 'test_3a');

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
0: 123
1: 234
2: 123
3: 123
final top: 4
==> rc=0, result='undefined'
*** test_2a (duk_safe_call)
==> rc=1, result='RangeError: invalid stack index -3'
*** test_2b (duk_safe_call)
==> rc=1, result='RangeError: invalid stack index 2'
*** test_2c (duk_safe_call)
==> rc=1, result='RangeError: invalid stack index -2147483648'
*** test_3a (duk_safe_call)
==> rc=1, result='RangeError: invalid stack index -1'
