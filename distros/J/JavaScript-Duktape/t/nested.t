use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Test::More;
use Test::Fatal;

use Try::Tiny;

subtest 'try-tiny interaction' => sub {
    sub eval_js {
        my $code = shift;

        my $js = JavaScript::Duktape->new;

        try {
            $js->eval( $code );
        } catch {
            my $err = $_;
            warn "CAUGHT ERR: $err";
            die "JS ERR: $err";
        };
    }

    eval {
        eval_js(q{
            throw new Error('oh boy!');
        });
    };
    isnt $@, '', 'error message comes through';
};

subtest 'simple nested thrown exception' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( each => sub{
        my $arr = shift;
        my $cb = shift;
        for(@$arr) {
            $cb->($_);
        }
    });
    like exception { $js->eval(q{
        var x=0; each([11,22], function(i){
            throw new Error('foo error!');
        });
    }) }, qr/foo error/;
};

subtest 'try-catch caught nested thrown exception' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( each => sub{
        my $arr = shift;
        my $cb = shift;
        for(@$arr) {
            $cb->($_);
        }
    });
    my $ret;
    ok !exception { $ret =$js->eval(q{
        var x=0;
        try {
            each([11,22], function(i){
                x+=i;
                throw new Error('foo error!');
            });
        } catch(e) {
        }
        x;
    }) };
    is $ret, 11;
};

subtest 'rewrap func with nested call' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( inc => sub{
        return 1 + shift();
    });
    $js->set( each => sub{
        my $arr = shift;
        my $cb = shift;
        for(@$arr) {
            $cb->($_);
        }
    });
    my $ret = $js->eval(q{
        var x=0; each([11,22], function(i){ x+=i; x=inc(x); }); x
    });
    is $ret, 35,
};

subtest 'trap callback error' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( each => sub{
        die "foo here";
    });
    like exception { $js->eval(q{
        var x=0; each([11,22], function(i){ x+=i });
    }) }, qr/foo here/;
};

subtest 'exception javascript' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( each => sub{
        my $arr = shift;
        my $cb = shift;
        for(@$arr) {
            $cb->($_);
        }
    });
    like exception { $js->eval(q{
        var x=0; var foo={};
        each([11,22], function(i){ foo.bar() });
    }) }, qr/not callable/;
};

subtest 'exception in perl' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( each => sub{
        die('no good');
    });
    like exception { $js->eval(q{
        var x=0; var foo={};
        each([11,22], function(i){ return 33 });
    }) }, qr/no good/;
};

subtest 'exception in callback function' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( each => sub{
        my $arr = shift;
        my $cb = shift;
        for(@$arr) {
            $cb->($_);
        }
    });
    like exception { $js->eval(q{
        var x=0; each([11,22], function(i){ not_a_function() });
    }) }, qr/not_a_function.*undefined/;
};

subtest 'trap rewrap func error within nested call' => sub{
    my $js = JavaScript::Duktape->new();
    $js->set( inc => sub{
        die "error bar here";
    });
    $js->set( each => sub{
        my $arr = shift;
        my $cb = shift;
        for(@$arr) {
            $cb->($_);
        }
    });
    like exception { $js->eval(q{
        var x=0; each([11,22], function(i){ x+=i; x=inc(x); });
    }) }, qr/error bar here/;
};

done_testing;
