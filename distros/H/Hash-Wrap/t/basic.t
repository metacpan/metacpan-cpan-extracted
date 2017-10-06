#! perl

use Test2::V0;

use Scalar::Util 'blessed';

use Hash::Wrap;

subtest 'default' => sub {

    my %hash = ( a => 1, b => 2 );

    my $obj = wrap_hash \%hash;

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

use Hash::Wrap ( {
    -as   => 'return_copied',
    -copy => 1,
});


subtest 'copied' => sub {

    my %hash = ( a => 1, b => 2, c => [9] );

    my $obj = return_copied \%hash;

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

    my $obj = return_cloned \%hash;

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
    -create => 1,
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


{
    package My::ExistingClass;
    use parent 'Hash::Wrap::Base';
}

use Hash::Wrap ({
    -as    => 'return_existing_class',
    -class => 'My::ExistingClass',
  });

# check that caching and alternative classing with creation works
subtest 'cache + existing class' => sub {

    my $obj = return_existing_class { a => 1 };

    my $class = blessed $obj;

    isa_ok( $obj, ['My::ExistingClass'], 'existing alternative class' );

    no strict 'refs';

    ok( !defined( *{"${class}::a"}{CODE} ), "no accessor for 'a'" );

    is( $obj->a, 1, "retrieve 'a'" );

    my $accessor = *{"${class}::a"}{CODE};

    is( $obj->can( 'a' ), $accessor, "can() returns cached accessor" );

};

{
    package My::ExistingClassNoBase;
}

# check that caching and alternative classing with creation works
subtest 'existing class, bad base' => sub {

    like(
        dies {
            Hash::Wrap->import(
                {
                    -as    => 'return_existing_class_nobase',
                    -class => 'My::ExistingClassNoBase',
                } )
        },
        qr/not a subclass/,
        'requires parent class'
    );

};

{
    package My::ExistingClassWithConstructor;
    use parent 'Hash::Wrap::Base';

    sub new {
        my $class = shift;
        $class = ref $class || $class;
        bless shift, $class;
    }
}

use Hash::Wrap ({
    -as    => 'return_existing_class_with_constructor',
    -class => 'My::ExistingClassWithConstructor',
});

# check that caching and alternative classing with creation works
subtest 'existing class, constructor' => sub {

    my $obj;
    ok( lives { $obj = return_existing_class_with_constructor( { a => 1 } ) },
        "create object" )
      or note $@;

    my $new;
    ok( lives { $new = $obj->new( {} ) }, 'call new method' ) or note $@;

    isa_ok(
        $new,
        ['My::ExistingClassWithConstructor'],
        'new returns new object'
    );

};

use Hash::Wrap ({
    -as     => 'return_existing_class_with_clone_sub',
    -class  => 'My::ExistingClassWithCloneSub',
    -create => 1,
    -clone  => sub {
        my %new = %{ shift() };
        $new{c} = 5;
        \%new;
    },
});

# clone coderef
subtest 'existing class, clone sub' => sub {

    my $obj;
    ok( lives { $obj = return_existing_class_with_clone_sub( { a => 1 } ) },
        "create object" )
      or note $@;

    my $c;
    ok( lives { $c = $obj->c }, "access new attribute added by clone sub" )
      or note $@;

    is( $c, 5, "new attribute value" );
};

done_testing;
