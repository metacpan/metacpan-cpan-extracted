
sub DUK_ERR_INTERNAL_ERROR { 52 }


use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub test_1 {
    my $duk = shift;
    my $a = $duk->get_number(-3);
    my $b = $duk->get_number(-2);
    my $c = $duk->get_number(-1);

    $duk->push_number($a + $b);

    # just one return value
    return 1;
}

sub test_2 {
    # TODO duk->error
    # $duk->error(DUK_ERR_INTERNAL_ERROR, "test_2 error");
    $duk->eval_string("throw new Error('test_2 error');");
    printf("1st return value: %s\n", $duk->to_string(-1));
    return 0;
}

sub test {
    my $rc;

    $duk->set_top(0);

    $duk->push_string("foo");  # dummy

    # /* success case */
    $duk->push_int(10);
    $duk->push_int(11);
    $duk->push_int(12);

    $rc = $duk->safe_call(\&test_1, 3 , 2 );

    if ($rc == 0) {
        printf("1st return value: %s\n", $duk->to_string(-2));  # 21
        printf("2nd return value: %s\n", $duk->to_string(-1));  # undefined
    } else {
        printf("error: %s\n", $duk->to_string(-1));
    }
    $duk->pop_2();

    # error case
    $duk->push_int(10);
    $duk->push_int(11);
    $duk->push_int(12);
    $rc = $duk->safe_call(\&test_2, 3 , 2);
    if ($rc == 0) {
        printf("1st return value: %s\n", $duk->to_string(-2));  # 21
        printf("2nd return value: %s\n", $duk->to_string(-1));  # undefined
    } else {
        printf("error: %s\n", $duk->to_string(-2));
    }
    $duk->pop_2();

    # /* XXX: also test invalid input stack shapes (like not enough args) */

    printf("final top: %ld\n", $duk->get_top());
}

test();
test_stdout();

__DATA__
1st return value: 21
2nd return value: undefined
error: Error: test_2 error
final top: 1
