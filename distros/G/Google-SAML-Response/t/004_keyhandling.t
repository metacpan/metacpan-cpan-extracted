use Test::Most;
use Test::Exception;
use Google::SAML::Response;

my $modulus = '1b+m37u3Xyawh2ArV8txLei251p03CXbkVuWaJu9C8eHy1pu87bcthi+T5WdlCPK'
            . 'D7KGtkKn9vqi4BJBZcG/Y10e8KWVlXDLg9gibN5hb0Agae3i1cCJTqqnQ0Ka8w1X'
            . 'ABtbxTimS1B0aO1zYW6d+UYl0xIeAOPsGMfWeu1NgLChZQton1/NrJsKwzMaQy1V'
            . 'I8m4gUleit9Z8mbz9bNMshdgYEZ9oC4bHn/SnA4FvQl1fjWyTpzL/aWF/bEzS6Qd'
            . '8IBk7yhcWRJAGdXTWtwiX4mXb4h/2sdrSNvyOsd/shCfOSMsf0TX+OdlbH079Asx'
            . 'OwoUjlzjuKdCiFPdU6yAJw==';
my $exponent = 'Iw==';

my $request = 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf'
            . '1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzO'
            . 'nVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aay'
            . 'aB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfx'
            . 'csE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1'
            . '+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc';

my $saml = Google::SAML::Response->new( {
    key => 't/rsa.private.key',
    login => 'someone',
    request => $request,
} );
isa_ok $saml, 'Google::SAML::Response';

$saml = Google::SAML::Response->new( {
    key => 't/rsa.private.key',
    login => 'someone',
    request => $request,
} );

isa_ok $saml->{ key_obj }, 'Crypt::OpenSSL::RSA', 'Key object is valid';
is index( $saml->{KeyInfo}, $modulus ), 41, 'Modulus is correct';
is index( $saml->{KeyInfo}, $exponent), 405, 'Exponent is correct';

dies_ok {
    $saml = Google::SAML::Response->new( {
        key => 'foobar',
        request => $request,
        login => 'someguy',
    } ) }
'new shoud die when it cannot find the private key';
dies_ok {
    $saml = Google::SAML::Response->new( {
        key => 'README',
        request => $request,
        login => 'someguy',
    } )
}
'new shoud die when the private key is invalid';

done_testing;
