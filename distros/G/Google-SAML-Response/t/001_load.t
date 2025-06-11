use Test::Most;
use Google::SAML::Response;

my $request = 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf'
            . '1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzO'
            . 'nVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aay'
            . 'aB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfx'
            . 'csE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1'
            . '+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc';

my $saml = Google::SAML::Response->new( {
    key     => 't/rsa.private.key',
    request => $request,
    login   => 'somebody',
} );
isa_ok $saml, 'Google::SAML::Response';

my $saml2 = Google::SAML::Response->new( {
    key     => 't/dsa.private.key',
    request => $request,
    login   => 'somebody',
} );
isa_ok$saml2, 'Google::SAML::Response';

done_testing;
