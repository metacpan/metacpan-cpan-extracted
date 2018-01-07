#!/usr/bin/env perl

use strict;
use warnings;
use lib "lib";
use Test::More 1.302120 tests => 25;
use Test::Exception 0.43;
use Scalar::Util 1.49 qw/refaddr/;

use_ok "Digest::PBKDF2";

### Base class testing

my $rawsalted   = Crypt::PBKDF2->new;
my $rawunsalted = Crypt::PBKDF2->new;

is( $rawsalted->salt_len, 4, "By default my salt_len is 4" );
TODO: {
    local $TODO = "Intermittent 'usage' message here";
    throws_ok { $rawsalted->salt_len(5) } qr/read-only accessor/, "I cannot change my salt_len";
};

my $salted = $rawsalted->generate('bebop');
my $unsalted = $rawunsalted->generate( 'bebop', salt => undef );

isnt( $salted, $unsalted, "The unsalted does not equal the salted" );

ok( $rawsalted->validate( $salted, 'bebop' ),
    "I can validate my salted password without specifying the salt" );
ok( $rawunsalted->validate( $unsalted, 'bebop' ),
    "I can validate my unsalted password"
);

### My module testing

my $orig = Digest::PBKDF2->new;
can_ok( $orig, qw/new clone add digest/ );

diag "I will try a password_pre_salt first";
lives_ok( sub { $orig->add('cool') }, "I can add one chunk" );

lives_ok( sub { $orig->add('jazz') }, "I can add another chunk" );

my $clone;
lives_ok( sub { $clone = $orig->clone }, "I can clone my object" );
isnt(
    refaddr $orig,
    refaddr $clone,
    "Cloning gives me a new Digest::PBKDF2 object"
);
isnt(
    refaddr \$orig->{_data},
    refaddr \$clone->{_data},
    "Cloning gives me a new data slot"
);
lives_ok( sub { delete $clone->{_data} },
    "I can delete the data in my clone" );
is( $clone->{_data}, undef,      "And the data is gone" );
is( $orig->{_data},  'cooljazz', "And the original remains intact" );
lives_ok( sub { $clone->add('cooljazz') }, "I can put back the clone data" );

###
my ( $clone_digest, $clone2_digest, $orig_digest, $orig2_digest );

( $clone_digest, $orig_digest ) = ( $clone->digest, $orig->digest );

is( $clone_digest, $orig_digest,
    "Clone and orginal produce the same string" );

is( $clone_digest,
    '$PBKDF2$HMACSHA1:1000:Y29vbA==$6LZU9raZ5BzrMRo0mwa8Z7ON+Mc=',
    "And that string is what it should be"
);
is( $orig_digest,
    '$PBKDF2$HMACSHA1:1000:Y29vbA==$6LZU9raZ5BzrMRo0mwa8Z7ON+Mc=',
    "Making sure it is..."
);

### No salt

diag "I will try no salt this time";

my $orig2 = Digest::PBKDF2->new;

lives_ok( sub { $orig2->add('jazz') }, "I can add the password chunk" );

my $clone2;
lives_ok( sub { $clone2 = $orig2->clone }, "I can clone my object" );
isnt(
    refaddr $orig2,
    refaddr $clone2,
    "Cloning gives me a new Digest::PBKDF2 object"
);
( $clone2_digest, $orig2_digest ) = ( $clone2->digest, $orig2->digest );
is( $clone2_digest, $orig2_digest,
    "Clone and orginal produce the same string" );
is( $clone2_digest,
    '$PBKDF2$HMACSHA1:1000:$zpYCcE4kGAQD37LhEQa56B7/kCc=',
    "And that string is what it should be"
);
is( $orig2_digest,
    '$PBKDF2$HMACSHA1:1000:$zpYCcE4kGAQD37LhEQa56B7/kCc=',
    "Making sure it is..."
);
