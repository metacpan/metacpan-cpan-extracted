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
    $duk->eval_string("new Date(123456)");
    $duk->push_string("\x82Value");
    $duk->get_prop(-2);
    printf("Date._Value: %s\n", $duk->safe_to_string(-1));
    printf("final top: %ld\n", $duk->get_top());
    return 0;
}

TEST_SAFE_CALL($duk, \&test_1, 'test_1');

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
Date._Value: 123456
final top: 2
==> rc=0, result='undefined'
