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
    $duk->push_thread();
    my $ctx2 = $duk->require_context(-1);
    printf("top: %ld\n", $duk->get_top());
    $ctx2->eval_string_noresult("aiee;");  # ReferenceError
    return 0;
}

sub test_2 {
    my $duk = shift;

    $duk->push_thread_new_globalenv();
    my $ctx2 = $duk->require_context(-1);
    printf("top: %ld\n", $duk->get_top());

    $ctx2->eval_string_noresult("zork;");  # ReferenceError
    return 0;
}

TEST_SAFE_CALL($duk, \&test_1, 'test_1');
TEST_SAFE_CALL($duk, \&test_2, 'test_2');

test_stdout();

__DATA__
*** test_1 (duk_safe_call)
top: 1
==> rc=1, result='ReferenceError: identifier 'aiee' undefined'
*** test_2 (duk_safe_call)
top: 1
==> rc=1, result='ReferenceError: identifier 'zork' undefined'
