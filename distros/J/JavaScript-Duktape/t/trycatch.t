use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->push_function(sub {
    fail("failed from javascript land");
}, 1);

$duk->put_global_string("perlfail");

$duk->push_function(sub {
    ok(1, "success from javascript land");
}, 1);

$duk->put_global_string("perlok");

{
    my $count = 0;
    $duk->push_function(sub {
        eval { die; };
        $count++;
        $duk->push_string("hi");
        eval { die; };
        die;
        $duk->require_string(99);
        fail("never here");
        return 1;
    }, 10);

    $duk->put_global_string("perlFn");

    my $ret = $duk->peval_string(qq~
        var ret;
        try {
            ret = new perlFn(9);
            //should never get here
            perlfail();
        } catch (e){
            throw(e);
        };
        //should never get here
        perlfail();
        ret;
    ~);

    is($ret, 1); #failed call
    is($count, 1);

    my $top = $duk->get_top();
    is($top, 1);
    ok($duk->get_error_code(-1) > 0, "last stack element should be an error");
    $duk->pop();
}


{
    my $count = 0;
    $duk->push_function(sub {
        eval { die; };
        $count++;
        $duk->push_string("hi");
        eval { die; };
        $duk->require_pointer(99); ##error
        return 1;
    }, 10);

    $duk->put_global_string("perlFn");

    my $ret = $duk->peval_string(qq~
        var ret;
        try {
            ret = new perlFn(9);
        } catch (e){
            var error = e.toString();
            if (/^TypeError: pointer required/.test(error)){
                perlok();
            }
            perlok();
        };
        //should get here
        perlok();
        ret;
    ~);

    is($ret, 0, "sucess call"); #no error catched by try {} block
    is($count, 1, "called once");
    my $top = $duk->get_top();
    is($top, 1, "return value undefined");
    $duk->pop();
}

done_testing(10);
