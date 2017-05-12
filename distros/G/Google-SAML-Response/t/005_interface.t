use Test::Most;
use HTML::Entities;

BEGIN {
    use_ok( 'Google::SAML::Response' );
}


my $login   = 'someone';
my $key     = 't/rsa.private.key';
my $rs      = 'http%3A%2F%2Fwww.google.com%2Fhosted%2Fpsosamldemo.net%2FDashboard';
my $srvurl  = 'https://www.google.com/hosted/psosamldemo.net/acs';
my $request = 'eJxdkE1PwzAMhs/9F1XubcM00IjWTQOEmDTQtA8O3NrEa7M1donTjZ9P2UAgrraf1489nn64Jj6CZ0uYi6tUihhQk7FY5WK7eUxGYjoZc+GaVs26UOMK3jvgEEc9iKzOnVx0HhUVbFlh4YBV0Go9e16oQSpV6ymQpkZE84dc7Nqign17KGtnzI5MUzrc1aayaB0cLOiD3ZcAVsTR649Wn9LDzB3MkUOBoS9JeZPI60QONnKkhrdqKN9EtPxedWfxcsE/r/SvV3kZYvW02SyTFRjrQYdzyNEa8C89kYuKqGog1eRENGMGH3qle0LuHPg1+KPVsF0tclGH0LLKstPplP5CWU0cwGQt09erDDhKEUJWaBbZ5BPy1YRc';


my $saml = Google::SAML::Response->new( { key => $key, login => $login, request => $request } );

isa_ok( $saml, 'Google::SAML::Response' );

$saml = Google::SAML::Response->new( { key => $key, login => $login, request => $request } );

ok( $saml->{service_url} eq $srvurl, 'Decoded request contains login url' );

my $html = $saml->get_google_form( $rs );

ok( $html, 'get_google_form returns something' );
unlike( $html, qr|^Content-type: text/html\n\n|, 'Content-type is no longer included' );
like( $html, qr|<!DOCTYPE html>|, 'form contains a doctype' );
like( $html, qr|"RelayState">$rs</textarea>|, 'Form contains the relay state' );
like( $html, qr|action="$srvurl"|, 'Form contains service url as action' );
like( $html, qr|<samlp:Response xmlns="urn:oasis:names:tc:SAML:2.0:assertion"|, 'Form seems to contain response xml' );


$rs .= '&ltmpl=gp';
$html = $saml->get_google_form( $rs );

my $encoded_rs = encode_entities( $rs );

ok( $html, 'get_google_form returns something' );
unlike( $html, qr|^Content-type: text/html\n\n|, 'Content-type is no longer included' );
like( $html, qr|<!DOCTYPE html>|, 'form contains a doctype' );
like( $html, qr|"RelayState">$encoded_rs</textarea>|, 'Form contains the relay state' );
like( $html, qr|action="$srvurl"|, 'Form contains service url as action' );
like( $html, qr|<samlp:Response xmlns="urn:oasis:names:tc:SAML:2.0:assertion"|, 'Form seems to contain response xml' );

done_testing;
