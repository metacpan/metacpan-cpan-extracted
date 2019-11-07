#! perl

use Test2::V0;

use Scalar::Util qw( blessed refaddr );

use Hash::Wrap ( { -immutable => 1 } );

subtest 'set' => sub {

    my %hash = ( a => 1, b => 2 );

    my $hash = \%hash;

    my $obj = wrap_hash $hash;

    subtest 'existing attribute' => sub {

        like(
            dies { $hash{a} = 2 },
            qr/read-only/,
            'hash'
            );

        like(
            dies { $obj->{a} = 2 },
            qr/read-only/,
            'object hash'
            );

        like(
            dies { $obj->a(2) },
            qr/read-only/,
            'accessor'
            );

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

done_testing();
