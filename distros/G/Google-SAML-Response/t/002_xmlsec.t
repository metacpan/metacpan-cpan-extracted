use Test::Most;
use File::Which;


BEGIN {
    use_ok( 'Google::SAML::Response' );
}

SKIP: {
    skip "xmlsec1 not installed", 6 unless which('xmlsec1');

    # Test whether xmlsec is correctly installed which 
    # doesn't seem to be the case on every cpan testing machine

    my $output = `xmlsec1 --version`;
    skip "xmlsec1 not correctly installed", 6 if $?;

    my $request = 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzOnVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aayaB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfxcsE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc';
    my $saml = Google::SAML::Response->new( { key => 't/rsa.private.key', login => 'someone', request => $request } );
    my $xml = $saml->get_response_xml();
    ok( $xml, "Got XML for the response" );
    ok( open XML, '>', 'tmp.xml' );
    print XML $xml;
    close XML;
    my $verify_response = `xmlsec1 --verify tmp.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "Response is OK for xmlsec1" )
        or warn "calling xmlsec1 failed: '$verify_response'\n";

    unlink 'tmp.xml';

    my $saml2 = Google::SAML::Response->new( { key => 't/dsa.private.key', login => 'someone', request => $request } );
    $xml = $saml2->get_response_xml();
    ok( $xml, "Got XML for the response" );
    ok( open XML, '>', 'tmp.xml' );
    print XML $xml;
    close XML;
    $verify_response = `xmlsec1 --verify tmp.xml 2>&1`;
    ok( $verify_response =~ m/^OK/, "Response is OK for xmlsec1" );

    unlink 'tmp.xml';
}

done_testing;
