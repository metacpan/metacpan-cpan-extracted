use Test::Most;
use Test::Exception;

BEGIN {
    use_ok( 'Google::SAML::Response' );
}

my $modulus = '1b+m37u3Xyawh2ArV8txLei251p03CXbkVuWaJu9C8eHy1pu87bcthi+T5WdlCPKD7KGtkKn9vqi4BJBZcG/Y10e8KWVlXDLg9gibN5hb0Agae3i1cCJTqqnQ0Ka8w1XABtbxTimS1B0aO1zYW6d+UYl0xIeAOPsGMfWeu1NgLChZQton1/NrJsKwzMaQy1VI8m4gUleit9Z8mbz9bNMshdgYEZ9oC4bHn/SnA4FvQl1fjWyTpzL/aWF/bEzS6Qd8IBk7yhcWRJAGdXTWtwiX4mXb4h/2sdrSNvyOsd/shCfOSMsf0TX+OdlbH079AsxOwoUjlzjuKdCiFPdU6yAJw==';
my $exponent = 'Iw==';

my $request = 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzOnVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aayaB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfxcsE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc';

my $saml = Google::SAML::Response->new( { key => 't/rsa.private.key', login => 'someone', request => $request } );
isa_ok( $saml, 'Google::SAML::Response' );

$saml = Google::SAML::Response->new( { key => 't/rsa.private.key', login => 'someone', request => $request } );

isa_ok( $saml->{ key_obj }, 'Crypt::OpenSSL::RSA', 'Key object is valid' );
is( index( $saml->{KeyInfo}, $modulus ), 41, 'Modulus is correct' );
is( index( $saml->{KeyInfo}, $exponent), 405, 'Exponent is correct' );

dies_ok { $saml = Google::SAML::Response->new( { key => 'foobar', request => $request, login => 'someguy' } ) } 'new shoud die when it cannot find the private key';
dies_ok { $saml = Google::SAML::Response->new( { key => 'README', request => $request, login => 'someguy' } ) } 'new shoud die when the private key is invalid';

done_testing;
