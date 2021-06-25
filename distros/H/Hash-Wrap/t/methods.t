#! perl

use Test2::V0;

use Hash::Wrap ();

subtest api => sub {

    like(
        dies {
            Hash::Wrap->import( { -methods => [] } )
        },
        qr/-methods.*must be a hashref/,
        'wrong type of argument'
    );

    like(
        dies {
            Hash::Wrap->import( {
                    -methods => {
                        '!a' => sub { }
                    } } );
        },
        qr/Perl identifier/,
        'illegal method name'
    );


    like(
        dies {
            Hash::Wrap->import( { -methods => { a => [] } } );
        },
        qr/value for method "a" must be a coderef/,
        'wrong argument for method name'
    );

};

subtest 'method' => sub {
    ok(
        lives {
            Hash::Wrap->import( {
                    -as      => 'wh0',
                    -methods => {
                        a => sub { '!a' },
                        b => sub { '!b' }
                    } } )
        },
        'make constructor'
    ) or note $@;

    my $obj;
    ok( lives { $obj = wh0( { a => 'a' } ) }, "make instance" );

    subtest 'override initial attribute' => sub {
        ok( !!$obj->can( 'a' ), "has method" );
        is( $obj->a, '!a', "correct return from method" );
    };

    subtest 'override added attribute' => sub {
        $obj->{b} = 'b';
        ok( !!$obj->can( 'b' ), "has method" );
        is( $obj->b, '!b', "correct return from method" );
    };

};

done_testing;
