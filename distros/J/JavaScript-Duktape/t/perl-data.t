use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$js->set( ok => \&Test::More::ok );

my $data = {
    num  => 9,
    func => sub {
        is( 1,     $_[0] );
        is( "Hi",  $_[1] );
        is( $_[2], true );    #true
        ok( $_[2] );          #true

        is( $_[3], false );   #false
        ok( !$_[3] );         #false

        #XXX : test null $_[4]
        ok( !$_[4] );
        is( $_[4], null );

        ##fifth argument passed as javascript function
        $_[5]->(
            sub {
                my $d = shift;
                is( $d, "Hi again" );
                return [ 1, 2, 3 ];
            }
        );

        return { h => 9999 };
    },
    str => 'Hello',
    un  => undef,
    n   => null,
    t   => true,
    f   => false
};

$js->set( 'perl', $data );

$duk->peval_string(q{
    ok (perl.str === 'Hello')
    ok (typeof perl.un === 'undefined')
    ok (perl.n === null)
    ok (perl.t === true)
    ok (perl.f === false)
    ok (typeof perl.func === 'function')

    var obj = perl.func(1, "Hi", true, false, null, function(d){
        var ret = d('Hi again');
        ok (typeof ret === 'object')
        ok (ret.length === 3)
    });
    ok (obj.h === 9999)
});

done_testing(18);
