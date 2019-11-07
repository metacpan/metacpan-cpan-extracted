#! perl

use Test2::V0;

use Scalar::Util qw( blessed refaddr );

use Hash::Wrap ( { -as => wrap_hash_asis =>  -lockkeys => 1 } );
use Hash::Wrap ( { -as => wrap_hash_extra =>  -lockkeys => [ qw( f g h ) ] } );

subtest 'existing attrs only' => sub {

    my %hash = ( a => 1, b => 2 );

    my $hash = \%hash;

    my $obj = wrap_hash_asis $hash;

    subtest 'existing attribute' => sub {

        ok( lives { $obj->a(3) }, "set a" )
            or note $@;

        is( $obj->a, 3, "get a" );
    };

    subtest 'new attribute' => sub {

        like(
            dies { $hash{c} = 1 },
            qr/access/,
            'hash'
            );

        like(
            dies { $obj->{c} = 1 },
            qr/access/,
            'object hash'
            );

        like(
            dies { $obj->c(2) },
            qr/locate object method/,
            'accessor'
            );
    };
};

subtest 'extra attrs' => sub {

    my %hash = ( a => 1, b => 2 );

    my $hash = \%hash;

    my $obj = wrap_hash_extra $hash;

    subtest 'existing attribute' => sub {

        is( $obj->a, 1, "a" );
        is( $obj->b, 2, "b" );
    };

    subtest 'non-existing but allowed attribute' => sub {

        ok( lives { $hash{f} = 2; }, "hash" )
            or note $@;
        ok( lives { $obj->{g} = 3; }, "object hash" )
            or note $@;

        is( $obj->f, 2, "f" );
        is( $obj->g, 3, "g" );
    };


    subtest 'non-allowed attribute' => sub {

        like(
            dies { $hash{c} = 1 },
            qr/access/,
            'hash is locked'
            );

        like(
            dies { $obj->{c} = 1 },
            qr/access/,
            'object hash is locked'
            );

        like(
            dies { $obj->c(2) },
            qr/locate object method/,
            'accessor'
            );
    };
};

done_testing();
