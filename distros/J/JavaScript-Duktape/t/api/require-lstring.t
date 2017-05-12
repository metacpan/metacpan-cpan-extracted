use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub dump_string {
    my $p = shift;
    printf("string:%s%s\n", (length $p == 0 ? "" : " "), $p);
}

sub dump_string_size {
    my ($p, $sz) = @_;
    printf("string:%s%s (%ld)\n", (length $p == 0 ? "" : " "), $p, $sz);
}

sub test_1 {
    my $p;
    my $sz;

    $duk->set_top(0);
    $duk->push_lstring("foo\0bar", 7);
    $duk->push_string("");

    $sz = 0xdeadbeef;
    $p = $duk->require_lstring(0, $sz);
    dump_string_size($p, $sz);

    $sz = 0xdeadbeef;
    $p = $duk->require_lstring(0, $sz);
    dump_string($p);

    $sz = "\0";
    $p = $duk->require_lstring(1, $sz);
    dump_string_size($p, $sz);

    $sz = 'uuu';
    $p = $duk->require_lstring(1, $sz);
    dump_string($p);
    return 0;
}

sub test_2 {
    my $p;
    my $sz;

    $duk->set_top(0);
    $duk->push_null();

    $p = $duk->require_lstring(0, $sz);
    printf("string: %s (%ld)\n", $p, $sz);
    return 0;
}

sub test_3 {
    my $p;
    my $sz;

    $duk->set_top(0);

    $p = $duk->require_lstring(0, $sz);
    printf("string: %s (%ld)\n", $p, $sz);
    return 0;
}

sub test_4 {
    my $p;
    my $sz;

    $duk->set_top(0);

    $p = $duk->require_lstring(-2147483648, $sz);
    printf("string: %s (%ld)\n", $p, $sz);
    return 0;
}


TEST_SAFE_CALL($duk, \&test_1, 'test_1');
TEST_SAFE_CALL($duk, \&test_2, 'test_2');
TEST_SAFE_CALL($duk, \&test_3, 'test_3');
TEST_SAFE_CALL($duk, \&test_4, 'test_4');

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
string: foo (7)
string: foo
string: (0)
string:
==> rc=0, result='undefined'
*** test_2 (duk_safe_call)
==> rc=1, result='TypeError: string required, found null (stack index 0)'
*** test_3 (duk_safe_call)
==> rc=1, result='TypeError: string required, found none (stack index 0)'
*** test_4 (duk_safe_call)
==> rc=1, result='TypeError: string required, found none (stack index -2147483648)'
