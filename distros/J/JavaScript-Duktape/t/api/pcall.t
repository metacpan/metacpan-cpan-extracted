use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;


my $rc;

# basic success case
$duk->eval_string("(function (x,y) { return x+y; })");
$duk->push_int(10);
$duk->push_int(11);
$rc = $duk->pcall(2);
printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
$duk->pop();
printf("top after pop: %ld\n", $duk->get_top());

# basic error case
$duk->eval_string("(function (x,y) { throw new Error('my error'); })");
$duk->push_int(10);
$duk->push_int(11);
$rc = $duk->pcall(2);
printf("rc=%d, result='%s'\n", $rc, $duk->safe_to_string(-1));
$duk->pop();
printf("top after pop: %ld\n", $duk->get_top());
printf("final top: %ld\n", $duk->get_top());

test_stdout();

1;

__DATA__
rc=0, result='21'
top after pop: 0
rc=1, result='Error: my error'
top after pop: 0
final top: 0
