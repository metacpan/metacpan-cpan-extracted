#! perl

use Test2::V0;
use Test2::API qw/ context /;

use Scalar::Util 'blessed';

sub test_generator {

    my ( $generator ) = @_;

    my $ctx = context();

    my %hash = ( a => 1, b => 2 );

    my $obj = $generator->( \%hash );

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );

    $hash{a} = 2;
    is( $obj->a, 2, 'object scalar not independent of hash' );


    is( $obj->c, undef, 'unknown attribute' );

    $hash{c} = 4;
    is( $obj->c, 4, 'retrieve value added through hash' );

    delete $obj->{c};
    is( $obj->c, undef, 'retrieve deleted attribute' );

    $obj->a( 22 );
    is( $obj->a,  22, 'setter' );
    is( $hash{a}, 22, 'setter reflected in hash' );

    $ctx->release;
};

use Hash::Wrap ( { -as => 'undefined', -undef => 1 } );

subtest 'default' => sub {

    test_generator( \&undefined );

};

use Hash::Wrap ( {
    -as     => 'undefined_created_class',
    -undef => 1,
    -class  => 'My::CreatedClass::Lvalue',
    -create => 1
} );

subtest 'create class' => sub {

    test_generator( \&undefined_created_class );
};

done_testing;
