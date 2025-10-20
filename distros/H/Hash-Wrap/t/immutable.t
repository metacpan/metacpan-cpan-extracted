#! perl

use Test2::V0;

use Scalar::Util qw( blessed refaddr );

use Hash::Wrap (
    { -immutable => 1,            -class => 'Immutable',     -as => 'immutable' },
    { -immutable => [ 'c', 'd' ], -class => 'ImmutablePlus', -as => 'immutable_plus' },
);

sub common {
    my $ctor = shift;
    my $ctx  = context;

    my %hash = ( a => 1, b => 2 );
    my $hash = \%hash;
    my $obj  = $ctor->( $hash );

    subtest 'existing attribute' => sub {
        like( dies { $hash{a} = 2 }, qr{Modification of a read-only .* at t/immutable.t}, 'hash' );
        like( dies { $obj->{a} = 2 }, qr{Modification of a read-only .* at t/immutable.t}, 'object hash' );
        like( dies { $obj->a( 2 ) }, qr{Modification of a read-only .* at t/immutable.t}, 'accessor' );
    };

    subtest 'new attribute' => sub {
        like( dies { $hash{z} = 1 }, qr{access disallowed key .* at t/immutable.t}, 'hash' );
        like( dies { $obj->{z} = 1 }, qr{access disallowed key .* at t/immutable.t}, 'object hash' );
        like( dies { $obj->z( 2 ) }, qr{locate object method .* at t/immutable.t}, 'accessor' );
    };

    $ctx->release;
    return $obj;
}


subtest 'immutable' => sub {
    common( \&immutable );
};

subtest 'immutable_plus' => sub {

    my $obj = common( \&immutable_plus );

    subtest 'unset' => sub {
        is( $obj->c, U(), 'unset' );
        like( dies { $obj->{c} = 2 }, qr{Modification of a read-only .* at t/immutable.t}, 'object hash' );
        like( dies { $obj->c( 2 ) },  qr{Modification of a read-only .* at t/immutable.t}, 'accessor' );
    };
};

done_testing();
