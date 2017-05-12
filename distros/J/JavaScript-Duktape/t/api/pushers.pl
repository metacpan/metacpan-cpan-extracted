use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;
my $res;

sub NULL { "\0" }

sub PRINTTOP {
    my $clen = 0;
    if ($duk->is_string(-1)) {
        $clen = $duk->get_length(-1);
    }

    printf("top=%ld type=%ld bool=%d num=%.6lf clen=%ld str='%s' str-is-NULL=%d ptr-is-NULL=%d\n",
        $duk->get_top(), $duk->get_type(-1), $duk->get_boolean(-1),
        $duk->get_number(-1), $clen, $duk->get_string(-1),
        ($duk->get_string(-1) ? 0 : 1),
        ($duk->get_pointer(-1) ? 0 : 1));
}

sub PRINTRESTOP {
    printf("-> res is %s\n", ((defined $res) ? "non-NULL" : "NULL"));
    PRINTTOP();
}

$duk->push_undefined(); PRINTTOP();
$duk->push_null(); PRINTTOP();
$duk->push_true(); PRINTTOP();
$duk->push_false(); PRINTTOP();
$duk->push_boolean(-1); PRINTTOP();
$duk->push_boolean(0); PRINTTOP();
$duk->push_boolean(1); PRINTTOP();
$duk->push_number(123.4); PRINTTOP();
$duk->push_int(234); PRINTTOP();
$duk->push_nan(); PRINTTOP();
$res = $duk->push_string("foo"); PRINTRESTOP();
$res = $duk->push_string("foo\0bar\0"); PRINTRESTOP();
$res = $duk->push_string(''); PRINTRESTOP();  # pushes empty
$res = $duk->push_string(NULL); PRINTRESTOP();  # pushes a NULL
$res = $duk->push_lstring("foobar", 4); PRINTRESTOP();
$res = $duk->push_lstring("foob\0\0", 6); PRINTRESTOP();
$res = $duk->push_lstring("\0", 1); PRINTRESTOP();  # pushes 1-byte string (0x00)
$res = $duk->push_lstring("\0", 0); PRINTRESTOP();  # pushes empty
$res = $duk->push_lstring(NULL, 0); PRINTRESTOP();  # pushes empty
$res = $duk->push_lstring(NULL, 10); PRINTRESTOP(); # pushes empty
# $res = $duk->push_sprintf("foo"); PRINTRESTOP();
# $res = $duk->push_sprintf("foo %d %s 0x%08lx", 123, "bar", 0x1234cafe); PRINTRESTOP();
# $res = $duk->push_sprintf(""); PRINTRESTOP();
# $res = $duk->push_sprintf(NULL); PRINTRESTOP();
# $res = test_vsprintf_3x_int(2, 3, 5); PRINTRESTOP();
# $res = test_vsprintf_empty(2, 3, 5); PRINTRESTOP();
# $res = test_vsprintf_null(2, 3, 5); PRINTRESTOP();
$duk->push_pointer(0); PRINTTOP();
$duk->push_pointer(0xdeadbeef); PRINTTOP();
