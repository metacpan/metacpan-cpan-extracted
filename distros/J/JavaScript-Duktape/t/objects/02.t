#function caching tests

use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use JavaScript::Duktape;
use Test::More;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->eval_string(qq~
    var tt = {};
    tt.all = test;
    function test (fn){
        this.name       = 'Mamod';
        this.lastname   = "Foo";
        this.counter    = 0;
        this.test       = function(){
            this.counter++;
            fn();
        };
    }

    test.prototype.setLast = function(fn){
        this.lastname = fn;
        this.fullname = this.name + " " + fn('Mehy');
    }
    test;
~);

my $obj = $duk->to_perl_object(-1);
$duk->pop();

my $t = $obj->new(sub{
    ok(1);
});

$t->setLast( sub {
    my $last = shift() . "ar";
    return $last;
});

##getting function
my $testfunc = $t->test;

$testfunc->();

is $t->lastname('Mehy'), "Mehyar";
is $t->fullname, "Mamod Mehyar";
is $t->counter, 1;

done_testing(4);
