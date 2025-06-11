use Test::Most;
use Google::SAML::Response;

my $request = 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf'
            . '1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzO'
            . 'nVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aay'
            . 'aB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfx'
            . 'csE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1'
            . '+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc';

my $saml = Google::SAML::Response->new( {
    key => 't/rsa.private.key',
    login => 'someone',
    request => $request
} );
isa_ok $saml, 'Google::SAML::Response';

dies_ok {
    $saml = Google::SAML::Response->new
} 'new should die when called without any parameters';
dies_ok {
    $saml = Google::SAML::Response->new( {
        login => 'someone',
        request => $request,
    } )
} 'new should die when called without the key parameter';
dies_ok {
    $saml = Google::SAML::Response->new( {
        key => 't/rsa.private.key',
        request => $request,
    } )
} 'new should die when called without the login parameter';
dies_ok {
    $saml = Google::SAML::Response->new( {
        login => 'someone',
        key => 't/rsa.private.key',
    } )
} 'new should die when called without the request parameter';

$saml = Google::SAML::Response->new( {
    key => 't/rsa.private.key',
    login => 'someone',
    request => $request,
} );
is $saml->{ttl}, 2*60, 'Default for ttl is 2 minutes';
is $saml->{canonicalizer}, 'XML::CanonicalizeXML', 'Default for canonicalizer is XML::CanonicalizeXML';
is $saml->{request}, $request, 'Request is stored in object';
is $saml->{login}, 'someone', 'Login is stored in object';
is $saml->{key}, 't/rsa.private.key', 'Key is stored in object';

done_testing;
