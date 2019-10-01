#! perl

use Test2::V0;

use Scalar::Util qw( blessed refaddr );

use Hash::Wrap;

subtest 'default' => sub {

    my %hash = ( a => 1, b => 2 );

    my $hash = \%hash;

    my $obj = wrap_hash $hash;

    is( refaddr( $obj ), refaddr( $hash ), "same hash reference" );

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );

    $hash{a} = 2;
    is( $obj->a, 2, 'object scalar not independent of hash' );


    like( dies { $obj->c }, qr/locate object method/, 'unknown attribute' );

    $obj->{c} = 3;
    is( $obj->c, 3, 'retrieve value added through hash' );

    delete $obj->{c};
    like(
        dies { $obj->c },
        qr/locate object method/,
        'retrieve deleted attribute'
    );


    $obj->a( 22 );
    is( $obj->a,  22, 'setter' );
    is( $hash{a}, 22, 'setter reflected in hash' );

};

subtest 'no hash' => sub {

    my $hash = wrap_hash;

    $hash->{a} = 1;

    is( $hash->a, 1, "set" );
};


use Hash::Wrap ( {
    -as   => 'return_copied',
    -copy => 1,
});


subtest 'copied' => sub {

    my %hash = ( a => 1, b => 2, c => [9] );
    my $hash = \%hash;

    my $obj = return_copied $hash;

    isnt( refaddr( $obj ), refaddr( $hash ), "same hash reference" );

    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );
    is( $obj->c, [9], 'retrieve another value' );

    $hash{a} = 2;
    is( $obj->a, 1, 'object scalar independent of hash' );


    $hash{c}->[0] = 10;
    is( $obj->c, [10], 'object arrayref contents not independent of hash' );

    $obj->a( 22 );
    is( $obj->a, 22, 'setter' );
    isnt( $hash{a}, 22, 'setter not reflected in hash' )
      or note qq[\$hash = $hash{a} (!22 ?)];

};

use Hash::Wrap ({
    -as    => 'return_cloned',
    -clone => 1,
});


subtest 'cloned' => sub {

    my %hash = ( a => 1, b => 2, c => [9] );
    my $hash = \%hash;

    my $obj = return_cloned $hash;

    isnt( refaddr( $obj ), refaddr( $hash ), "same hash reference" );
    is( $obj->a, 1, 'retrieve value' );
    is( $obj->b, 2, 'retrieve another value' );
    is( $obj->c, [9], 'retrieve another value' );

    $hash{a} = 2;
    is( $obj->a, 1, 'object scalar independent of hash' );

    $hash{c} = [10];
    is( $obj->c, [9], 'object arrayref contents independent of hash' );

};


use Hash::Wrap ({
    -as     => 'return_created_class',
    -class  => 'My::CreatedClass',
  });

# check that caching and alternative classing with creation works
subtest 'cache + create class' => sub {

    my $obj = return_created_class { a => 1 };

    my $class = blessed $obj;

    isa_ok( $obj, ['My::CreatedClass'], 'created alternative class' );

    no strict 'refs';

    ok( !defined( *{"${class}::a"}{CODE} ), "no accessor for 'a'" );

    is( $obj->a, 1, "retrieve 'a'" );

    my $accessor = *{"${class}::a"}{CODE};

    is( $obj->can( 'a' ), $accessor, "can() returns cached accessor" );

};

use Hash::Wrap ({
    -as     => 'test_can',
    -class  => 'My::TestCan',
  });


subtest 'can() on existing attribute without constructed accessor' => sub {

    my $obj = test_can { a => 1 };

    ok(  lives { $obj->can('a') },
         'constructs accessor' );

};


done_testing;
