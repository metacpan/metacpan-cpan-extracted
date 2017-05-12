use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

sub my_function {}

$duk->push_undefined();
$duk->push_null();
$duk->push_boolean(0);
$duk->push_boolean(123);
$duk->push_number(234);
$duk->push_string("foo");
$duk->push_object();
$duk->push_array();
$duk->push_function(\&my_function, DUK_VARARGS);
$duk->push_fixed_buffer(1024);
$duk->push_dynamic_buffer(1024);
$duk->push_pointer(0xdeadbeef);

my $i = 0;

my $n = $duk->get_top();
for ($i = 0; $i < $n + 1; $i++) {  # end on invalid index on purpose
    printf("stack[%ld] --> DUK_TYPE_NUMBER=%ld DUK_TYPE_NONE=%ld\n",
           $i, $duk->check_type($i, DUK_TYPE_NUMBER),
           $duk->check_type($i, DUK_TYPE_NONE));
}

test_stdout();

__DATA__
stack[0] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[1] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[2] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[3] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[4] --> DUK_TYPE_NUMBER=1 DUK_TYPE_NONE=0
stack[5] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[6] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[7] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[8] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[9] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[10] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[11] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=0
stack[12] --> DUK_TYPE_NUMBER=0 DUK_TYPE_NONE=1
