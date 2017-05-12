use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

SET_PRINT_METHOD($duk);

#basic success case, non-strict target function (this gets coerced) */
$duk->eval_string("(function (x,y) { print(typeof this, this); return x+y; })");
$duk->push_int(123);  # this
$duk->push_int(10);
$duk->push_int(11);
my $rc = $duk->pcall_method(2);
printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
$duk->pop();

# basic success case, strict target function (this not coerced)) */
$duk->eval_string("(function (x,y) { 'use strict'; print(typeof this, this); return x+y; })");
$duk->push_int(123);  # this */
$duk->push_int(10);
$duk->push_int(11);
$rc = $duk->pcall_method(2);
printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
$duk->pop();

# basic error case
$duk->eval_string("(function (x,y) { throw new Error('my error'); })");
$duk->push_int(123);  # this */
$duk->push_int(10);
$duk->push_int(11);
$rc = $duk->pcall_method(2);
printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
$duk->pop();

printf("final top: %ld\n", $duk->get_top());

test_stdout();

__DATA__
object 123
rc=0, result='21'
number 123
rc=0, result='21'
rc=1, result='Error: my error'
final top: 0
