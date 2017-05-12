use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

SET_PRINT_METHOD($duk);

sub my_constructor {
    return 0;
}

sub test1 {
    $duk->push_global_object();
    $duk->push_function(\&my_constructor, 0);     # constructor (function) */
    $duk->push_object();                          # prototype object -> [ global cons proto ] */
    $duk->push_string("inherited value");
    $duk->put_prop_string(-2, "inherited");     # set proto.inherited = "inherited value" */
    $duk->put_prop_string(-2, "prototype");     # set cons.prototype = proto; stack -> [ global cons ] */
    $duk->put_prop_string(-2, "MyConstructor"); # set global.MyConstructor = cons; stack -> [ global ] */
    $duk->pop();

    $duk->eval_string("var obj = new MyConstructor(); print(obj.inherited);");
    # $duk->dump();
    $duk->pop();

    printf("top at end: %ld\n", $duk->get_top());
    return 0;
}

TEST_SAFE_CALL($duk, \&test1, 'test1');

test_stdout();

__DATA__
*** test1 (duk_safe_call)
inherited value
top at end: 0
==> rc=0, result='undefined'
