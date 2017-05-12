# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 2;

BEGIN {
    use_ok( 'Google::SAML::Request' );
}

my $saml = Google::SAML::Request->new(
    {
        ProviderName => 'somebody.invalid',
        AssertionConsumerServiceURL => 'https://login.somebody.invalid/fooBar',
    }
);

isa_ok( $saml, 'Google::SAML::Request' );

