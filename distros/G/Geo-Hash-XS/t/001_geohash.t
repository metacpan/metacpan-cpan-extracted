use strict;
use warnings;
use Test::More;
use Geo::Hash::XS;

my @tests = (
    {
        hash => 'ezs42',
        pos  => [ 42.6, -5.6 ],
        eps  => 0.01,
    },
    {
        hash => 'mh7w',
        pos  => [ -20, 50 ],
        eps  => 0.1,
    },
    {
        hash => 't3b9m',
        pos  => [ 10.1, 57.2 ],
        eps  => 0.1,
    },
    {
        hash => 'c2b25ps',
        pos  => [ 49.26, -123.26 ],
        eps  => 0.01,
    },
    {
        hash => '80021bgm',
        pos  => [ 0.005, -179.567 ],
        eps  => 0.001,
    },
    {
        hash => 'k484ht99h2',
        pos  => [ -30.55555, 0.2 ],
        eps  => 0.00001,
    },
    {
        hash => '8buh2w4pnt',
        pos  => [ 5.00001, -140.6 ],
        eps  => 0.00001,
    },
);

ok my $gh = Geo::Hash::XS->new, "created new Geo::Hash::XS object";
isa_ok $gh, 'Geo::Hash::XS';

for my $test ( @tests ) {
    my ( $hash, $pos, $eps ) = @{$test}{qw(hash pos eps)};
    is $gh->encode( @$pos, length $hash ), $hash, "$hash: encode";

    {
        my @got = $gh->decode( $hash );
        ok abs( $got[$_] - $pos->[$_] ) < $eps, "$hash: decode $_"
          for 0 .. 1;
    }

    {
        my $enc_hash = $gh->encode( @$pos );
        ok abs( length( $enc_hash ) - length( $hash ) ) <= 1,
          "$hash: auto precision";
        # diag "@$pos ($hash) -> $enc_hash";
        my @got = $gh->decode( $enc_hash );
        ok abs( $got[$_] - $pos->[$_] ) < $eps, "$hash: decode $_"
          for 0 .. 1;
    }
}

my @bad_cases = (
    {
        pos => [ '35.21.03.342', '138.34.45.725' ],
    },
    {
        pos => [ '112', '138.34.45.725' ],
    },
    {
        pos => [ '35.21.03.342', '95' ],
    }
);
for my $test ( @bad_cases ) {
    my ( $pos ) = @{$test}{qw( pos )};
    eval {
        $gh->encode( @$pos );
    };
    like $@, qr/encode\(\) only works on degrees, not dms values/,
        "@$pos is not encodable and dies with an error";
}

done_testing;
