# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 26;
use Test::Exception;
use Date::Format;
use URI::Escape;

BEGIN {
    use_ok( 'Google::SAML::Request' );
}

my $request = 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzOnVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aayaB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfxcsE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc';

my $saml = Google::SAML::Request->new(
            {
                ProviderName                => 'provider',
                AssertionConsumerServiceURL => 'http://AssertionConsumerServiceURL'
            } );

isa_ok( $saml, 'Google::SAML::Request' );

dies_ok { $saml = Google::SAML::Response->new() } 'new should die when called without any parameters';
dies_ok { $saml = Google::SAML::Response->new( { ProviderName => 'foo' } ) } 'new should die when called without the AssertionConsumerServiceURL parameter';
dies_ok { $saml = Google::SAML::Response->new( { AssertionConsumerServiceURL => 'bar' } ) } 'new should die when called without the ProviderName parameter';

my $time = time;
$saml = Google::SAML::Request->new(
            {
                ProviderName                => 'provider',
                AssertionConsumerServiceURL => 'http://AssertionConsumerServiceURL'
            } );

is( $saml->{ProviderName}, 'provider', 'object knows about ProviderName' );
is( $saml->{AssertionConsumerServiceURL}, 'http://AssertionConsumerServiceURL', 'object knows about AssertionConsumerServiceURL' );
is( length $saml->{ID}, 40, 'a 40 characters ID was generated' );
ok( $saml->{IssueInstant} eq makeIssueInstant( $time ) || $saml->{IssueInstant} eq makeIssueInstant( $time + 1), 'IssueInstant looks ok' );


$saml = Google::SAML::Request->new(
            {
                ProviderName                => 'provider',
                AssertionConsumerServiceURL => 'http://AssertionConsumerServiceURL',
                IssueInstant                => 'fooBar',
            } );

is( $saml->{ProviderName}, 'provider', 'object knows about ProviderName' );
is( $saml->{AssertionConsumerServiceURL}, 'http://AssertionConsumerServiceURL', 'object knows about AssertionConsumerServiceURL' );
is( length $saml->{ID}, 40, 'a 40 characters ID was generated' );
is( $saml->{IssueInstant}, 'fooBar', 'IssueInstant looks ok' );


$time = time;
$saml = Google::SAML::Request->new(
            {
                ProviderName                => 'provider',
                AssertionConsumerServiceURL => 'http://AssertionConsumerServiceURL',
                ID                          => 'gabbagabbahey'
            } );

is( $saml->{ProviderName}, 'provider', 'object knows about ProviderName' );
is( $saml->{AssertionConsumerServiceURL}, 'http://AssertionConsumerServiceURL', 'object knows about AssertionConsumerServiceURL' );
is( $saml->{ID}, 'gabbagabbahey', 'object knows about ID' );
ok( $saml->{IssueInstant} eq makeIssueInstant( $time ) || $saml->{IssueInstant} eq makeIssueInstant( $time + 1), 'IssueInstant looks ok' );


$saml = Google::SAML::Request->new(
            {
                ProviderName                => 'provider',
                AssertionConsumerServiceURL => 'http://AssertionConsumerServiceURL',
                ID                          => 'gabbagabbahey',
                IssueInstant                => 'atimestampinadifferentformat'
            } );

is( $saml->ProviderName, 'provider', 'ProviderName accessor works' );
is( $saml->AssertionConsumerServiceURL, 'http://AssertionConsumerServiceURL', 'AssertionConsumerServiceURL accessor works' );
is( $saml->ID, 'gabbagabbahey', 'ID accessor works' );
is( $saml->IssueInstant,  'atimestampinadifferentformat', 'IssueInstant accessor works' );


$ENV{QUERY_STRING}   = "fooBar=" . uri_escape($request);
$ENV{REQUEST_METHOD} = 'GET';


my $saml4 = Google::SAML::Request->new_from_cgi( { param_name => 'fooBar' } );
isa_ok( $saml4, 'Google::SAML::Request', 'Got a Google::SAML::Request object' );
is( $saml4->ProviderName,                'google.com', 'ProviderName accessor works' );
is( $saml4->AssertionConsumerServiceURL, 'https://www.google.com/hosted/psosamldemo.net/acs', 'AssertionConsumerServiceURL accessor works' );
is( $saml4->ID,                          'fpagejpkbhmddfodlbmnfhdginimekieckijbeei', 'ID accessor works' );
is( $saml4->IssueInstant,                '2006-05-02T08:49:40Z', 'IssueInstant accessor works' );


sub makeIssueInstant {
    my $time = shift;
    return time2str( "%Y-%m-%dT%XZ", $time, 'UTC' )
}


