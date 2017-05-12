# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 16;
use URI::Escape;

BEGIN {
    use_ok( 'Google::SAML::Request' );
}

my $saml = Google::SAML::Request->new(
            {
                ProviderName                => 'provider',
                AssertionConsumerServiceURL => 'http://AssertionConsumerServiceURL',
                ID                          => 'gabbagabbahey',
                IssueInstant                => 'atimestampinadifferentformat'
            } );

isa_ok( $saml, 'Google::SAML::Request', 'Got a Google::SAML::Request object' );

is( $saml->ProviderName,                'provider', 'ProviderName accessor works' );
is( $saml->AssertionConsumerServiceURL, 'http://AssertionConsumerServiceURL', 'AssertionConsumerServiceURL accessor works' );
is( $saml->ID,                          'gabbagabbahey', 'ID accessor works' );
is( $saml->IssueInstant,                'atimestampinadifferentformat', 'IssueInstant accessor works' );

my $getParam = $saml->get_get_param();
ok( $getParam, 'Got something back from get_get_param' );

if ( $getParam ) {
    my $saml2 = Google::SAML::Request->new_from_string( uri_unescape( $getParam ) );
    is( $saml2->ProviderName, $saml->ProviderName, 'ProviderName is the same' );
    is( $saml2->AssertionConsumerServiceURL, $saml->AssertionConsumerServiceURL, 'AssertionConsumerServiceURL is the same' );
    is( $saml2->ID, $saml->ID, 'ID is the same' );
    is( $saml2->IssueInstant, $saml->IssueInstant, 'IssueInstant is the same' );
}

my $request = uri_escape( 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzOnVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aayaB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfxcsE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc' );

$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = "SAMLRequest=$request";

my $saml4 = Google::SAML::Request->new_from_cgi();
isa_ok( $saml4, 'Google::SAML::Request', 'Got a Google::SAML::Request object' );
is( $saml4->ProviderName,                'google.com', 'ProviderName accessor works' );
is( $saml4->AssertionConsumerServiceURL, 'https://www.google.com/hosted/psosamldemo.net/acs', 'AssertionConsumerServiceURL accessor works' );
is( $saml4->ID,                          'fpagejpkbhmddfodlbmnfhdginimekieckijbeei', 'ID accessor works' );
is( $saml4->IssueInstant,                '2006-05-02T08:49:40Z', 'IssueInstant accessor works' );



















