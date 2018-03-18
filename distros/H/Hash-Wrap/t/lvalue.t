#! perl

use Test2::V0;
use Test2::API qw/ context /;

use Scalar::Util 'blessed';

use Hash::Wrap ();

my $HAS_LVALUE;

BEGIN {
    $HAS_LVALUE = $] ge '5.01600';
}

sub test_generator {

    my ( $generator ) = @_;

    my $ctx = context();

    my %hash = ( a => 1, b => 2 );

    my $obj = $generator->( \%hash );

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );

    $hash{a} = 2;
    is( $obj->a, 2, 'object scalar not independent of hash' );


    like( dies { $obj->c }, qr/locate object method/, 'unknown attribute' );

    $hash{c} = 4;
    is( $obj->c, 4, 'retrieve value added through hash' );

    delete $obj->{c};
    like(
        dies { $obj->c },
        qr/locate object method/,
        'retrieve deleted attribute'
    );

    $obj->a = 22;
    is( $obj->a,  22, 'setter' );
    is( $hash{a}, 22, 'setter reflected in hash' );

    $ctx->release;
}

if ( $HAS_LVALUE ) {

    {
        package My::Test::LValue::1;

        Hash::Wrap->import( { -as => 'lvalued', -lvalue => 1 } );

    }
    subtest 'default' => sub {
        test_generator( \&My::Test::LValue::1::lvalued );
    };


    {
        package My::Test::LValue::2;

        Hash::Wrap->import( {
            -as     => 'lvalued_created_class',
            -lvalue => 1,
            -class  => 'My::CreatedClass::Lvalue',
        } );
    }

    subtest 'create class' => sub {
        test_generator( \&My::Test::LValue::2::lvalued_created_class );
    };


}

else {

    ok(
        lives {
            package My::Test::LValue::3;

            Hash::Wrap->import( { -as => 'lvalued', -lvalue => 1 } );

            1;
        },
        "Perl < 5.16, lvalue => 1"
    ) or note $@;

    like(
        dies {
            package My::Test::LValue::4;

            Hash::Wrap->import( { -as => 'lvalued', -lvalue => -1 } );

            1;
        },
        qr/lvalue accessors require Perl 5.16 or later/,
        "Perl < 5.16, lvalue => -1"
    );

}


done_testing;
