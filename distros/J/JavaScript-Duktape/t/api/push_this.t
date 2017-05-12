use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub func {
    eval{};
    $duk->push_this();
    my $t = $duk->get_type(-1);
    printf("this binding: type=%ld, value='%s'\n", $t, $duk->to_string(-1));
}

$duk->push_c_function(\&func, 0);
$duk->push_undefined();
$duk->push_null();
$duk->push_true();
$duk->push_false();
$duk->push_number(123.456);
$duk->push_string("foo");
$duk->push_object();
$duk->push_array();
$duk->push_fixed_buffer(16);
$duk->push_pointer(0xdeadbeef);

my $n = $duk->get_top();
printf("top: %ld\n", $n);
for (my $i = 1; $i < $n; $i++) {
    $duk->dup(0);
    $duk->dup($i);
    $duk->pcall_method(0); # [ ... func this ] -> [ ret ] */
    $duk->pop();
}

test_stdout();


__DATA__
top: 11
this binding: type=1, value='undefined'
this binding: type=2, value='null'
this binding: type=3, value='true'
this binding: type=3, value='false'
this binding: type=4, value='123.456'
this binding: type=5, value='foo'
this binding: type=6, value='[object Object]'
this binding: type=6, value=''
this binding: type=7, value='[object Uint8Array]'
#skip - this binding: type=8, value='DEADBEEF'
