#! perl


use Test2::V0;

{
    package Hashed;

    use Hash::Wrap ( { -base => 1 } );

}

{
    package Hashed::Potatoes;

    our @ISA = qw[ Hashed ];

    sub foo { 30 }
}

my $obj = Hashed::Potatoes->new( { foo => 10, bar => 20 } );

is( $obj->foo, 30, "method" );

SKIP: {

    my $bar;
    my $accessor_exists = ok( lives { $bar = $obj->bar }, "accessor exists" );

    unless ( $accessor_exists ) {
        note $@;
        skip( "accessor tests as accessors are broken\n" );

        is( $bar, 20, "accessor value" );

        $obj->{fries} = 40;

        is( $obj->fries, 40, "new accessor" );

        like(
            dies { $obj->cakes },
            qr/can't locate object method/i,
            "bad element"
        );

    }
}

done_testing;
