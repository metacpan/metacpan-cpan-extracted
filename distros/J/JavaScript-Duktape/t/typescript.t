use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

use FindBin '$Bin';
my $ts_path = "$Bin/data/typescript.js";


subtest 'typescript compile' => sub {
    my $js = JavaScript::Duktape->new;

    $js->set( load => sub { _load_ts(); } );

    $js->eval(q{
        var module = {};
        var exports = module.exports = {};
        function require(){
            eval(load());
            return module.exports;
        }
    });

    my $ts = $js->eval( q{
        var ts = require('ts');
        ts;
    } );

    is ref( $ts->{transpile} ), 'CODE';
};

subtest 'typescript transpile' => sub {
    my $js = JavaScript::Duktape->new;

    $js->set( load=>sub{ _load_ts(); } );

    $js->eval(q{
        var module = {};
        var exports = module.exports = {};
        function require(){
            eval(load());
            return module.exports;
        }
    });

    my $code = $js->eval( q{
        var ts = require('ts');
        var code = ts.transpile('class Foo { bar: string; constructor(){ this.bar="baz" }; };');
        code;
    } );

    like $code, qr/Foo.*function/;

    my $ret = $js->eval( $code . "; (new Foo()).bar" );

    is $ret, 'baz';
};

done_testing;

sub _load_ts {
    local $/;
    open my $ff,'<', $ts_path;
    <$ff>;
}
