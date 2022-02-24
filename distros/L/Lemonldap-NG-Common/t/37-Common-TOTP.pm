# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Common.t'
#########################
use Time::Fake;

# Must subclass TOTP because it uses $self->logger etc.
package TestableTotp;
use Moose;
use Test::More;
use Lemonldap::NG::Common::TOTP;
use Lemonldap::NG::Common::Logger::Null;
extends 'Lemonldap::NG::Common::TOTP';
has logger     => ( is => "ro", lazy => 1, builder => '_null_logger' );
has userLogger => ( is => "ro", lazy => 1, builder => '_null_logger' );

sub _null_logger {
    return Lemonldap::NG::Common::Logger::Null->new;
}

package main;
use Test::More tests => 16;

BEGIN {
    use_ok('Lemonldap::NG::Common::TOTP');
}
use strict;

### WARNING FOR DEVELOPPERS ###
# These constants are not to be messed with. If this unit test breaks, do NOT
# modify them, fix the code instead.
#
# In particular, if the $stored_secret no longer decrypts to $cleartext_secret,
# it means that users will lose their encrypted TOTP secrets on the next
# upgrade.
# If you need to change the cryptographic algorithm, make sure you remain
# compatible with existing stored values

my $timestamp          = 1633009395;
my $totp_for_timestamp = 766039;
my $cleartext_secret   = "ggtoch5x6naorymli6nh72ku4khwd4jr";
my $key                = "azert";
my $encrypted_secret =
"{llngcrypt}TdEcd2vkmn4j0D8+str3v2D8zt0Dbm3sZ8TwlzdOKcang+qUmLraTQBztSrESRHDpAh+pQCKvDozuz9va7GxhHIkaKI3EZxOCWJ0rQCun/I=";

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $t = TestableTotp->new( key => $key, encryptSecret => 0 );

# Verification with no offset
Time::Fake->offset($timestamp);
is( $t->verifyCode( 30, 0, 6, $cleartext_secret, $totp_for_timestamp ),
    1, "TOTP code is valid" );

Time::Fake->offset( $timestamp + 30 );
is( $t->verifyCode( 30, 0, 6, $cleartext_secret, $totp_for_timestamp ),
    0, "TOTP code is no longer valid" );

Time::Fake->offset( $timestamp - 30 );
is( $t->verifyCode( 30, 0, 6, $cleartext_secret, $totp_for_timestamp ),
    0, "TOTP code is not valid yet" );

# Verification with offset 2 allows +1m and -1m
Time::Fake->offset( $timestamp + 45 );
is( $t->verifyCode( 30, 2, 6, $cleartext_secret, $totp_for_timestamp ),
    1, "TOTP code is valid" );

Time::Fake->offset( $timestamp - 45 );
is( $t->verifyCode( 30, 2, 6, $cleartext_secret, $totp_for_timestamp ),
    1, "TOTP code is valid" );

Time::Fake->offset( $timestamp + 95 );
is( $t->verifyCode( 30, 2, 6, $cleartext_secret, $totp_for_timestamp ),
    0, "TOTP code is no longer valid" );

Time::Fake->offset( $timestamp - 95 );
is( $t->verifyCode( 30, 2, 6, $cleartext_secret, $totp_for_timestamp ),
    0, "TOTP code is not valid yet" );

# TOTP encryption tests

$t = TestableTotp->new( key => $key, encryptSecret => 0 );
Time::Fake->offset($timestamp);
is( $t->verifyCode( 30, 0, 6, $encrypted_secret, $totp_for_timestamp ),
    1, "TOTP is valid with encrypted secret and encryption disabled" );

$t = TestableTotp->new( key => $key, encryptSecret => 1 );
Time::Fake->offset($timestamp);
is( $t->verifyCode( 30, 0, 6, $encrypted_secret, $totp_for_timestamp ),
    1, "TOTP is valid with encrypted secret and encryption enabled" );
Time::Fake->offset($timestamp);
is( $t->verifyCode( 30, 0, 6, $cleartext_secret, $totp_for_timestamp ),
    1, "TOTP is valid with cleartext secret and encryption enabled" );

# Encryption of TOTP secret, wrong key
$t = TestableTotp->new( key => "idunno", encryptSecret => 0 );
is( $t->verifyCode( 30, 0, 6, $encrypted_secret, $totp_for_timestamp ),
    -1, "TOTP code fails to verify" );

# Do not encrypt new secrets unless we configured it
$t = TestableTotp->new( key => $key, encryptSecret => 0 );
is( $t->get_storable_secret($cleartext_secret),
    $cleartext_secret,
    "TOTP secret is stored as-is when encryption is disabled" );

# Encrypt new secrets if we configured it
$t = TestableTotp->new( key => $key, encryptSecret => 1 );
my $new = $t->get_storable_secret($cleartext_secret);
like( $new, qr/^{llngcrypt}/, "Secret looks encrypted" );
unlike( $new, qr/$cleartext_secret/, "Secret looks encrypted" );

Time::Fake->offset($timestamp);
is( $t->verifyCode( 30, 0, 6, $new, $totp_for_timestamp ),
    1, "get_storable_secret produces working secret" );
