#! perl

use Test2::V0;
use Test2::API qw/ context /;

use Scalar::Util 'blessed';

skip_all( "lvalue support requires perl 5.16 or later" )
  if $] lt '5.016000';

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

use if $] ge '5.016000',
  'Hash::Wrap' => ( { -as => 'lvalued', -lvalue => 1 } );

subtest 'default' => sub {

    test_generator( \&lvalued );

};

use if $] ge '5.016000',
  'Hash::Wrap' => ( {
    -as     => 'lvalued_created_class',
    -lvalue => 1,
    -class  => 'My::CreatedClass::Lvalue',
    -create => 1
} );

subtest 'create class' => sub {

    test_generator( \&lvalued_created_class );
};

{
    package My::Bogus::LValue::Class;
    use parent 'Hash::Wrap::Base';
}

like(
    dies {
        Hash::Wrap->import( {
                -as     => 'bogus_lvalue_class',
                -lvalue => 1,
                -class  => 'My::Bogus::LValue::Class'
            } )
    },
    qr/does not add ':lvalue'/,
    'bad lvalue class'
);

done_testing;
