use lib '../lib', 'blib', 'lib';
use Test2::V0;
use Config;
no warnings 'portable';    # Support for 64-bit ints required
my $_64BIT = $Config{ivsize} >= 8;
my ( $uint64, $hex_to_uint64 );
if ($_64BIT) {
    $uint64        = sub { $_[0] };
    $hex_to_uint64 = sub { hex( $_[0] ) };
}
else {
    require Math::Int64;
    Math::Int64->import(qw[uint64 hex_to_uint64]);
    $uint64        = \&Math::Int64::uint64;
    $hex_to_uint64 = \&Math::Int64::hex_to_uint64;
}
use Digest::xxHash qw[xxhash32 xxhash32_hex
    xxhash64 xxhash64_hex
    xxh3_64 xxh3_64_hex
    xxh3_128_hex xxh3_128
    xxh3_generate_secret];

# 32bit
is xxhash32( 'this is a test', 0xCAFEBABE ), 2811818255, 'Demo';
my $b1 = join '', map {chr} 0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F, 0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F, 0xB8, 0x1E, 0x85, 0xEB,
    0x51, 0xB8, 0x9E, 0x3F, 0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F, 0xB8, 0x1E, 0x85, 0xEB, 0x51, 0xB8, 0x9E, 0x3F, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x50, 0xC3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x13, 0x08, 0x12, 0x65, 0xE3, 0x6A, 0xC0;
my $b2 = join '', map {chr} 0xD7, 0xA3, 0x70, 0x3D, 0x0A, 0x57, 0x21, 0x40, 0x9A, 0x99, 0x99, 0x99, 0x99, 0x99, 0x21, 0x40, 0xA4, 0x70, 0x3D, 0x0A,
    0xD7, 0x23, 0x21, 0x40, 0x14, 0xAE, 0x47, 0xE1, 0x7A, 0x94, 0x21, 0x40, 0x14, 0xAE, 0x47, 0xE1, 0x7A, 0x94, 0x21, 0x40, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0xD8, 0x3C, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x13, 0x08, 0x13, 0xA9, 0xF1, 0xE2, 0x2A;
is xxhash32( $b1,    0x5262 ), xxhash32( $b2, 0x5262 ), 'Known 32 bit collision';
is xxhash32( 'test', 123 ),    2758658570,              'basic';
is xxhash32( 'test', 12345 ),  3834992036,              'basic w/ different seed';
is xxhash32_hex( 'test', 12345 ), 'e49555a4', 'xxhash32_hex';

# 64bit
is $uint64->( xxhash64( 'test64', 1123 ) ), $uint64->('18300740539230391133');
is $uint64->( xxhash64( 'test64', 5813 ) ), $uint64->('470519085964830776');
is xxhash64_hex( 'test64', 5813 ), '06879e9da2f9a838', 'xxhash64_hex';
my $SANITY_BUFFER_SIZE = 101;
my $prime              = 2654435761;
my $sanityBuffer       = pack 'H*', '9eff1f4b5e532fddb5544d2a952b57ae5dba74e9d3a64c983060c080';

sub BMK_testSequence {
    my ( $sentence, $len, $seed, $result ) = @_;
    is xxhash32( pack( 'a' . $len, $sentence ), $seed ), $result, 'line ' . ( caller() )[2];
}

sub BMK_testSequence64 {
    my ( $sentence, $len, $seed, $result ) = @_;
    is $uint64->( xxhash64( pack( 'a' . $len, $sentence ), $seed ) ), $hex_to_uint64->($result), 'line ' . ( caller() )[2];
}
BMK_testSequence( '',            0,                   0,      0x02CC5D05 );
BMK_testSequence( '',            0,                   $prime, 0x36B78AE7 );
BMK_testSequence( $sanityBuffer, 1,                   0,      0xB85CBEE5 );
BMK_testSequence( $sanityBuffer, 1,                   $prime, 0xD5845D64 );
BMK_testSequence( $sanityBuffer, 14,                  0,      0xE5AA0AB4 );
BMK_testSequence( $sanityBuffer, 14,                  $prime, 0x4481951D );
BMK_testSequence( $sanityBuffer, $SANITY_BUFFER_SIZE, 0,      0x1F1AA412 );
BMK_testSequence( $sanityBuffer, $SANITY_BUFFER_SIZE, $prime, 0x498EC8E2 );
BMK_testSequence64( '',            0,                   0,      'EF46DB3751D8E999' );
BMK_testSequence64( '',            0,                   $prime, 'AC75FDA2929B17EF' );
BMK_testSequence64( $sanityBuffer, 1,                   0,      '4FCE394CC88952D8' );
BMK_testSequence64( $sanityBuffer, 1,                   $prime, '739840CB819FA723' );
BMK_testSequence64( $sanityBuffer, 14,                  0,      'CFFA8DB881BC3A3D' );
BMK_testSequence64( $sanityBuffer, 14,                  $prime, '5B9611585EFCC9CB' );
BMK_testSequence64( $sanityBuffer, $SANITY_BUFFER_SIZE, 0,      '0EAB543384F878AD' );
BMK_testSequence64( $sanityBuffer, $SANITY_BUFFER_SIZE, $prime, 'CAA65939306F1E21' );

# Issue 4
is xxhash64_hex( 'b' x 100000, 890272 ), 'df8fee94dbf20a9d', 'uint64 fix to match xxHash.xs';
is xxhash64_hex( 'b' x 100000, 89 ),     '01aae2582443bbf0', 'expect leading zeros';

# XXH3-64 known-answer tests (empty string only)
# From xxHash sanity_test_vectors.h XSUM_XXH3_testdata[0..1]
is xxh3_64_hex( '', 0 ),                  lc '2D06800538D394C2', 'xxh3_64 empty, seed=0';
is xxh3_64_hex( '', 0x9E3779B185EBCA8D ), lc 'A8A6B918B2F0364A', 'xxh3_64 empty, golden seed';

# XXH3-128 known-answer tests (empty string only)
# From xxHash sanity_test_vectors.h XSUM_XXH128_testdata[0..2]
# C struct XXH128_hash_t is {low64, high64}; hexdigest outputs high64low64
is xxh3_128_hex( '', 0 ),                  lc '99AA06D3014798D8' . '6001c324468d497f', 'xxh3_128 empty, seed=0';
is xxh3_128_hex( '', 0x9E3779B185EBCA8D ), lc '00FEAA732A3CE25E' . 'a986dfc5d7605bfe', 'xxh3_128 empty, golden seed';

# XXH3-64 streaming tests (verify against single-shot)
subtest 'xxh3_64 streaming matches single-shot' => sub {
    my @test_cases = (
        [ '',                                            0 ],
        [ '',                                            0x9E3779B185EBCA8D ],
        [ 'Hello, xxHash world!',                        42 ],
        [ 'a' x 100,                                     0 ],
        [ 'a' x 100,                                     12345 ],
        [ 'The quick brown fox jumps over the lazy dog', 99999 ],
    );
    for my $tc (@test_cases) {
        subtest $tc->[0] || '(empty string)' => sub {
            my ( $data, $seed ) = @$tc;
            my $single = xxh3_64_hex( $data, $seed );
            my $desc   = sprintf 'xxh3_64 seed=%s len=%d', $seed, length($data);
            my $ctx    = Digest::xxHash->new( type => 'xxh3_64', seed => $seed );
            $ctx->add($data);
            is $ctx->hexdigest, $single, $desc . ' single add';
            my $ctx2   = Digest::xxHash->new( type => 'xxh3_64', seed => $seed );
            my @chunks = $data =~ /(.{1,5}|$)/g;
            pop @chunks if @chunks && $chunks[-1] eq '';
            $ctx2->add($_) for @chunks;
            is $ctx2->hexdigest, $single, $desc . ' incremental add';
            my $ctx3 = Digest::xxHash->new( type => 'xxh3_64', seed => $seed );

            for my $ch ( split //, $data ) {
                $ctx3->add($ch);
            }
            is $ctx3->hexdigest, $single, $desc . ' byte-by-byte';
        }
    }
};

# XXH3-128 streaming tests (verify against single-shot)
subtest 'xxh3_128 streaming matches single-shot' => sub {
    my @test_cases = ( [ '', 0 ], [ '', 0x9E3779B185EBCA8D ], [ 'Hello, xxHash world!', 42 ], [ 'a' x 100, 0 ], [ 'a' x 100, 12345 ], );
    for my $tc (@test_cases) {
        subtest $tc->[0] || '(empty string)' => sub {
            my ( $data, $seed ) = @$tc;
            my $single = xxh3_128_hex( $data, $seed );
            my $desc   = sprintf 'xxh3_128 seed=%s len=%d', $seed, length($data);
            my $ctx    = Digest::xxHash->new( type => 'xxh3_128', seed => $seed );
            $ctx->add($data);
            is $ctx->hexdigest, $single, $desc . ' single add';
            my $ctx2   = Digest::xxHash->new( type => 'xxh3_128', seed => $seed );
            my @chunks = $data =~ /(.{1,5}|$)/g;
            pop @chunks if @chunks && $chunks[-1] eq '';
            $ctx2->add($_) for @chunks;
            is $ctx2->hexdigest, $single, $desc . ' incremental add';
        }
    }
};
subtest 'xxh32 streaming matches single-shot' => sub {
    my $data   = 'Test xxh32 streaming';
    my $seed   = 12345;
    my $single = xxhash32_hex( $data, $seed );
    my $ctx    = Digest::xxHash->new( type => 'xxh32', seed => $seed );
    $ctx->add($data);
    is $ctx->hexdigest, $single, 'xxh32 streaming single add';
    my $ctx2 = Digest::xxHash->new( type => 'xxh32', seed => $seed );
    $ctx2->add('Test ');
    $ctx2->add('xxh32 ');
    $ctx2->add('streaming');
    is $ctx2->hexdigest, $single, 'xxh32 streaming incremental';
};
subtest 'xxh64 streaming matches single-shot' => sub {
    my $data   = 'Test xxh64 streaming';
    my $seed   = 12345;
    my $single = xxhash64_hex( $data, $seed );
    my $ctx    = Digest::xxHash->new( type => 'xxh64', seed => $seed );
    $ctx->add($data);
    is $ctx->hexdigest, $single, 'xxh64 streaming single add';
    my $ctx2 = Digest::xxHash->new( type => 'xxh64', seed => $seed );
    $ctx2->add('Test ');
    $ctx2->add('xxh64 ');
    $ctx2->add('streaming');
    is $ctx2->hexdigest, $single, 'xxh64 streaming incremental';
};
subtest 'clone produces independent copy' => sub {
    my $ctx = Digest::xxHash->new( type => 'xxh3_64', seed => 0 );
    $ctx->add('some data');
    my $clone = $ctx->clone;
    is $ctx->hexdigest, $clone->hexdigest, 'clone matches original after same input';
    $ctx->add(' more data');
    isnt $ctx->hexdigest, $clone->hexdigest, 'clone unaffected by original changes';
    $clone->add(' different data');
    isnt $ctx->hexdigest, $clone->hexdigest, 'original unaffected by clone changes';
};
subtest 'clone works for xxh3_128' => sub {
    my $ctx = Digest::xxHash->new( type => 'xxh3_128', seed => 42 );
    $ctx->add('some data');
    my $clone = $ctx->clone;
    is $ctx->hexdigest, $clone->hexdigest, 'xxh3_128 clone matches original';
    $ctx->add(' more');
    isnt $ctx->hexdigest, $clone->hexdigest, 'xxh3_128 clone independent';
};
subtest 'reset reuses context' => sub {
    for my $type (qw[xxh32 xxh64 xxh3_64 xxh3_128]) {
        my $ctx = Digest::xxHash->new( type => $type, seed => 0 );
        $ctx->add('some data');
        my $first = $ctx->hexdigest;
        $ctx->reset;
        $ctx->add('some data');
        my $second = $ctx->hexdigest;
        is $first, $second, 'reset produces same result for ' . $type;
    }
};
subtest 'xxh3_generate_secret returns 192 bytes' => sub {
    my $secret = xxh3_generate_secret(0);
    is length($secret), 192, 'secret is 192 bytes';
    my $secret2 = xxh3_generate_secret(42);
    is length($secret2), 192,      'secret from seed 42 is 192 bytes';
    isnt $secret,        $secret2, 'different seeds produce different secrets';
};
subtest 'XXH3 with custom secret' => sub {
    my $data   = 'test data';
    my $secret = xxh3_generate_secret(42);
    my $ctx    = Digest::xxHash->new( type => 'xxh3_64', secret => $secret );
    $ctx->add($data);
    my $hex = $ctx->hexdigest;
    is length($hex), 16, 'xxh3_64 with secret produces 16-char hex';
    my $ctx2 = Digest::xxHash->new( type => 'xxh3_128', secret => $secret );
    $ctx2->add($data);
    my $hex2 = $ctx2->hexdigest;
    is length($hex2), 32, 'xxh3_128 with secret produces 32-char hex';
    my $ctx3 = Digest::xxHash->new( type => 'xxh3_64', seed => 42 );
    $ctx3->add($data);
    isnt $ctx->hexdigest, $ctx3->hexdigest, 'secret-based differs from seed-based';
};
subtest 'empty input' => sub {
    is xxh3_64_hex( '', 0 ),            lc '2D06800538D394C2', 'xxh3_64 empty string';
    is length( xxh3_128_hex( '', 0 ) ), 32,                    'xxh3_128 empty string has 32 hex chars';
};
subtest 'b64digest' => sub {
    my $ctx = Digest::xxHash->new( type => 'xxh3_64', seed => 0 );
    $ctx->add('test');
    my $b64 = $ctx->b64digest;
    like $b64, qr/^[A-Za-z0-9+\/]+=*$/, 'b64digest looks like base64';
};
subtest errors => sub {
    like dies { Digest::xxHash->new( type => 'fake' ) },             qr/Unknown hash type/, 'unknown type dies';
    like dies { Digest::xxHash->new( type => 'xxh32', fake => 1 ) }, qr/Unknown arguments/, 'unknown argument dies';
};
#
done_testing;
