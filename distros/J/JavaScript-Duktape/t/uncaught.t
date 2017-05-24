use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

my $count = 0;

$duk->push_function(
    sub {
        eval { };
        $count++;
        $duk->push_string("hi");
        die;
        $duk->require_string(99);
        fail("should never get here");
    }
);

$duk->put_global_string("perlFn");

{   #eval with try
    eval {
        $duk->eval_string(q{
            try {
                perlFn();
            } catch (e){
                throw(e);
            };
        });
    };
    ok( $@, $@ );
    is( $count, 1, "called once" );
}

{    #eval without try
    $count = 0;
    eval {
        $duk->eval_string(q{
            perlFn();
        });
    };
    ok( $@, $@ );
    is( $count, 1, "called once" );
}

{   #peval with try/catch
    #reset
    $count = 0;
    eval {
        $duk->peval_string(q{
            var ret;
            try {
                perlFn();
                perlFn();
            } catch (e){
                throw(e);
            };
        });
    };

    ok( !$@, 'Eval Error' );
    is( $count, 1, "called once" );
    ok( $duk->is_error(-1), "Error is on top" );
    $duk->pop();
}

{   #peval without try/catch
    #reset
    $count = 0;
    eval {
        $duk->peval_string(q{
            perlFn();
            perlFn();
        });
    };

    ok( !$@, $@ );
    is( $count, 1, "called once" );

    ok( $duk->is_error(-1), "Error is on top" );
    my $err_str = $duk->to_string(-1);
    ok( $err_str =~ /^Error: Died at/, $err_str );
}

{
    #overwrite perl function
    $js->set(
        'perlFn',
        sub {
            eval { };
            $count++;
            $duk->push_string("hi");
            $duk->require_string(99);
            fail("should never get here");
        }
    );

    $duk->peval_string("perlFn");
    eval { $duk->call(0); };

    ok( $@ =~ /^uncaught/, $@ );

    $duk->eval_string("perlFn");
    eval { $duk->pcall(0); };
    ok( !$@ );

    my $str = $duk->to_string(-1);
    is( $str, "TypeError: string required, found none (stack index 99)" );
}

done_testing(14);
