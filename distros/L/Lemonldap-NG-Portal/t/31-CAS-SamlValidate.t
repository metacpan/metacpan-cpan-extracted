use warnings;
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use MIME::Base64;
use XML::LibXML;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $res );

ok( $issuer = issuer(), 'Issuer portal' );
count(1);

my $s = "user=french&password=french";

# Login
ok(
    $res = $issuer->_post(
        '/',
        IO::String->new($s),
        accept => 'text/html',
        length => length($s),
    ),
    'Post authentication'
);
count(1);
my $idpId = expectCookie($res);

subtest "Missing service" => sub {
    my $ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );

    ok(
        $res = $issuer->_post(
            '/cas/samlValidate', "", accept => 'text/html',
        ),
        'Post authentication'
    );

    expectCasFail( $res, "Requester",
        "Missing mandatory parameters (service, ticket)" );
};

subtest "Missing ticket" => sub {
    my $ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );

    ok(
        $res = $issuer->_post(
            '/cas/samlValidate',
            "",
            query => {
                TARGET => "http://auth.sp.com",
            },
            accept => 'text/html',
        ),
        'Post authentication'
    );

    expectCasFail( $res, "Requester",
        "Missing mandatory parameters (service, ticket)" );
};

subtest "Invalid ticket" => sub {
    my $ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );

    ok(
        $res = $issuer->_post(
            '/cas/samlValidate',
            getSoapRequest("${ticket}xx"),
            query => {
                TARGET => "http://auth.sp.com",
            },
            accept => 'text/html',
        ),
        'Post authentication'
    );

    expectCasFail( $res, "Requester", "Ticket not found" );
};

subtest "Valid request" => sub {
    my $ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );

    ok(
        $res = $issuer->_post(
            '/cas/samlValidate',
            getSoapRequest($ticket),
            query => {
                TARGET => "http://auth.sp.com",
            },
            accept => 'text/html',
        ),
        'Post authentication'
    );

    expectCasSuccess(
        $res, 'french',
        {
            mail   => ['fa@badwolf.org'],
            cn     => ['Frédéric Accents'],
            uid    => ['french'],
            groups => [ 'earthlings', 'users' ],
        }
    );
};

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                issuerDBCASActivation  => 1,
                casAccessControlPolicy => 'error',
                casAppMetaDataOptions  => {
                    sp => {
                        casAppMetaDataOptionsService => 'http://auth.sp.com/',
                    },
                },
                casAppMetaDataExportedVars => {
                    sp => {
                        cn     => 'cn',
                        mail   => 'mail',
                        uid    => 'uid',
                        groups => 'groups',
                    },
                },
            }
        }
    );
}

sub casGetTicket {
    my ( $issuer, $id, $service ) = @_;
    ok(
        my $res = $issuer->_get(
            '/cas/login',
            cookie => "lemonldap=$id",
            query  => 'service=' . $service,
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    count(1);
    my ($ticket) =
      expectRedirection( $res, qr#^http://auth.sp.com/\?.*ticket=([^&]+)# );

    return $ticket;
}

sub casGetResponse {
    my ( $issuer, $ticket, $service ) = @_;
    ok(
        my $res = $issuer->_get(
            '/cas/p3/serviceValidate',
            query  => 'service=' . $service . '&' . $ticket,
            accept => 'text/html'
        ),
        'Query CAS server'
    );

    expectOK($res);
    count(1);
    return $res;
}

sub expectCasFail {
    my ( $res, $type, $message ) = @_;
    my $content = $res->[2]->[0];

    my $dom = XML::LibXML->load_xml( string => $content );
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs( 'samlp', 'urn:oasis:names:tc:SAML:1.0:protocol' );
    is(
        $xpc->findnodes(
            '//samlp:Response/samlp:Status/samlp:StatusCode/@Value')
          ->string_value(),
        "samlp:$type",
        "Expected status code"
    );
    is(
        $xpc->findnodes(
            '//samlp:Response/samlp:Status/samlp:StatusMessage/text()')
          ->string_value(),
        $message,
        "Expected status message"
    );
}

sub expectCasSuccess {
    my ( $res, $username, $attributes ) = @_;
    my $content = $res->[2]->[0];

    my $dom = XML::LibXML->load_xml( string => $content );
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs( 'samlp', 'urn:oasis:names:tc:SAML:1.0:protocol' );
    $xpc->registerNs( 'saml',  'urn:oasis:names:tc:SAML:1.0:assertion' );
    is(
        $xpc->findnodes(
            '//samlp:Response/samlp:Status/samlp:StatusCode/@Value')
          ->string_value(),
        "samlp:Success",
        "Status is successful"
    );

    is(
        $xpc->findnodes(
                '//samlp:Response/saml:Assertion/saml:AuthenticationStatement'
              . '/saml:Subject/saml:NameIdentifier/text()'
        )->string_value(),
        $username,
        "Expected username"
    );

    for my $attr ( keys %$attributes ) {
        is_deeply( [
                sort
                  map { my $text = $_->data; utf8::encode($text); $text }
                  $xpc->findnodes(
                    "//samlp:Response/saml:Assertion/saml:AttributeStatement"
                      . "/saml:Attribute[\@AttributeName='$attr']"
                      . "/saml:AttributeValue/text()"
                )->get_nodelist
            ],
            $attributes->{$attr},
            "Expected attributes"
        );
    }
}

sub getSoapRequest {
    my ($ticket) = @_;
    my $soap_message = <<EOF;
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
    <SOAP-ENV:Header/>
    <SOAP-ENV:Body>
        <samlp:Request xmlns:samlp="urn:oasis:names:tc:SAML:1.0:protocol" MajorVersion="1" MinorVersion="1" RequestID="_192.168.16.51.1024506224022" IssueInstant="2002-06-19T17:03:44.022Z">
            <samlp:AssertionArtifact>$ticket</samlp:AssertionArtifact>
        </samlp:Request>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
    return $soap_message;
}
