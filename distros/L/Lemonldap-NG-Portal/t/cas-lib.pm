package main;
use Test::More;

sub expectCasSuccess {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($res) = @_;
    my $content = $res->[2]->[0];
    ok(
        casXPath( $content, '/cas:serviceResponse/cas:authenticationSuccess' ),
        "Cas response contains authenticationSuccess"
    );
    count(1);
}

sub casXPath {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $xmlString, $expr ) = @_;

    my $dom = XML::LibXML->load_xml( string => $xmlString );
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs( 'cas', 'http://www.yale.edu/tp/cas' );
    my ($match) = $xpc->findnodes($expr);
    ok($match);
    count(1);
    return $match;
}

sub casXPathAll {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $xmlString, $expr ) = @_;

    my $dom = XML::LibXML->load_xml( string => $xmlString );
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs( 'cas', 'http://www.yale.edu/tp/cas' );
    return $xpc->findnodes($expr);
}

package LLNG::Manager::Test;
use XML::LibXML;
use Test::More;

sub casLogin {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $issuer, $id, $service ) = @_;
    main::ok(
        my $res = $issuer->_get(
            '/cas/login',
            cookie => "lemonldap=$id",
            query  => 'service=' . $service,
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    main::count(1);
    return ($res);
}

sub casGetTicket {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $issuer, $id, $service ) = @_;
    my $res = $issuer->casLogin( $id, $service );
    my ($ticket) =
      main::expectRedirection( $res, qr#^$service\?.*ticket=([^&]+)# );

    return $ticket;
}

sub casValidateTicket {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $issuer, $ticket, $service ) = @_;
    main::ok(
        my $res = $issuer->_get(
            '/cas/p3/serviceValidate',
            query => {
                service => $service,
                ticket  => $ticket,
            },
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    main::count(1);

    main::expectOK($res);
    return $res;
}

sub casGetAndValidateTicketSuccess {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $issuer, $id, $service ) = @_;
    return main::expectCasSuccess(
        $issuer->casValidateTicket(
            $issuer->casGetTicket( $id, $service ), $service
        )
    );
}

1;
