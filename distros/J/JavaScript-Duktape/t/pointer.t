use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use JavaScript::Duktape;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->push_function(
    sub {
        my $i = $duk->require_pointer(0);
        is $i, 999;
        return 1;
    },
    1
);
$duk->put_global_string('_sendbackpointer');

$js->set(
    '_sendbackpointer2',
    sub {
        my $p = shift;
        is( ref $p, 'JavaScript::Duktape::Pointer' );
        is( $$p,    999 );
    }
);

$js->set(
    'ok',
    sub {
        ok( 1, "got from javascript" );
    }
);

$duk->peval_string(q{
    function test (){
        ok();
    }

    function test2 (p) {
        _sendbackpointer(p);
        _sendbackpointer2(p);
    }

    var t = Duktape.Pointer(test);
    t;
});

my $p = $duk->to_perl(0);
is( ref $p, 'JavaScript::Duktape::Pointer' );

$duk->push_heapptr($$p);
$duk->pcall(0);
$duk->pop_n(2);

my $test = TEST->new();

$duk->peval_string('test2');
$duk->push_pointer($$test);
$duk->pcall(1);
$duk->pop();

done_testing(5);

#################################################
package TEST;
{
    sub new {
        my $t = 999;
        return bless \$t, __PACKAGE__;
    }
};
