use strict;
use warnings;

use Test::More;

use Math::BigInt ();
use MaxMind::DB::Metadata;

my %args = (
    binary_format_major_version => 1,
    binary_format_minor_version => 1,
    build_epoch                 => time(),
    database_type               => 'Test',
    description                 => { foo => 'bar' },
    ip_version                  => 4,
    node_count                  => 100,
    record_size                 => 32,
);

{
    my $metadata = MaxMind::DB::Metadata->new(%args);

    ok( $metadata, 'code compiles' );
}

{
    my $metadata = MaxMind::DB::Metadata->new(
        %args,
        binary_format_major_version => Math::BigInt->bone,
    );

    ok( $metadata, 'Math::BigInt works as Int in Metadata' );
}

done_testing();
