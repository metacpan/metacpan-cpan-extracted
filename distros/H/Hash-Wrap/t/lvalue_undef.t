#! perl

use Test2::V0;
use Test2::API qw/ context /;

use Scalar::Util 'blessed';

my $HAS_LVALUE;

BEGIN {
    $HAS_LVALUE = $] ge '5.01600';
}

skip_all( "lvalue support requires perl 5.16 or later" )
  unless $HAS_LVALUE;

sub test_generator {

    my ( $generator ) = @_;

    my $ctx = context();

    my %hash = ( a => 1, b => 2 );

    my $obj = $generator->( \%hash );

    note ref $obj;

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );

    $hash{a} = 2;
    is( $obj->a, 2, 'object scalar not independent of hash' );


    is( $obj->c, undef, 'unknown attribute' );

    $hash{c} = 4;
    is( $obj->c, 4, 'retrieve value added through hash' );

    delete $obj->{c};
    is( $obj->c, undef, 'retrieve deleted attribute' );

    $obj->a = 22;
    is( $obj->a,  22, 'setter' );
    is( $hash{a}, 22, 'setter reflected in hash' );

    $ctx->release;
}

use if $HAS_LVALUE,
  'Hash::Wrap' => ( { -as => 'lvalued_undef', -lvalue => 1, -undef => 1 } );

subtest 'default' => sub {

    test_generator( \&lvalued_undef );

};

use if $HAS_LVALUE,
  'Hash::Wrap' => ( {
    -as     => 'created_class',
    -lvalue => 1,
    -undef => 1,
    -class  => 'My::CreatedClass::LvalueUndef',
} );

subtest 'create class' => sub {

    test_generator( \&created_class );
};

done_testing;
