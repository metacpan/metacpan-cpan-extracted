use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Plack::Request;
use Plack::Response;
use URI;
use XML::LibXML;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/cas-lib.pm';
}

our $loggedOut;

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);

        # Find provided ST for this host
        my $dom =
          XML::LibXML->load_xml( string => $req->parameters->{logoutRequest} );
        my $xc = XML::LibXML::XPathContext->new($dom);
        $xc->registerNs( 'samlp', 'urn:oasis:names:tc:SAML:2.0:protocol' );
        my $session_index =
          $xc->findnodes('/samlp:LogoutRequest/samlp:SessionIndex/text()')
          ->string_value();

        # Save it
        $loggedOut->{ $req->uri->host } = $session_index;

        # Return HTTP 200
        return Plack::Response->new(200)->finalize;
    }
);

my $debug = 'error';
my ( $issuer, $res );

subtest "Test IDP initiated logout" => sub {

    $loggedOut = {};

    # Login
    ok( $issuer = issuer(), 'Issuer portal' );
    my $id = $issuer->login("dwho");

    my $st1 = $issuer->casGetTicket( $id, 'http://auth.sp.com/' );
    expectCasSuccess(
        $issuer->casValidateTicket( $st1, 'http://auth.sp.com/' ) );

    $issuer->casGetAndValidateTicketSuccess( $id, 'http://auth.sp2.com/' );

    # Logout
    ok(
        $res = $issuer->_get(
            '/',
            query  => { logout => 1 },
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Initiate logout'
    );
    is( expectCookie($res), 0, "Cookie was cleared" );

    like( $res->[2]->[0], qr/My CAS App/, "Found CAS app name" );
    unlike( $res->[2]->[0], qr/My Other App/, "My other app is not displayed" );

    my ( $host, $url, $query ) =
      expectForm( $res, 'auth.example.com', '/?logout=1', 'logout' );
    is( $query, "logout=1", "Found logout option" );

    relaySpFromInfo( $issuer, $res );
    is( $loggedOut->{'auth.sp.com'},
        $st1, "Correct ticket sent to sp for logout" );
    ok( !$loggedOut->{'auth.sp2.com'}, "No ticket sent to sp2" );
};

subtest "Test App initiated logout, no redirect" => sub {

    $loggedOut = {};

    # Login
    ok( $issuer = issuer(), 'Issuer portal' );
    my $id = $issuer->login("dwho");

    my $st1 = $issuer->casGetTicket( $id, 'http://auth.sp.com/' );
    expectCasSuccess(
        $issuer->casValidateTicket( $st1, 'http://auth.sp.com/' ) );

    $issuer->casGetAndValidateTicketSuccess( $id, 'http://auth.sp2.com/' );

    # Logout
    ok(
        $res = $issuer->_get(
            '/cas/logout',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Initiate logout'
    );
    is( expectCookie($res), 0, "Cookie was cleared" );
    my ( $host, $url, $query ) =
      expectForm( $res, 'auth.example.com', '/?logout=1', 'logout' );
    is( $query, "logout=1", "Found logout option" );

    like( $res->[2]->[0], qr/My CAS App/, "Found CAS app name" );
    unlike( $res->[2]->[0], qr/My Other App/, "My other app is not displayed" );

    relaySpFromInfo( $issuer, $res );
    is( $loggedOut->{'auth.sp.com'},
        $st1, "Correct ticket sent to sp for logout" );
    ok( !$loggedOut->{'auth.sp2.com'}, "No ticket sent to sp2" );
};

subtest "Test App initiated logout, with redirect" => sub {

    $loggedOut = {};

    # Login
    ok( $issuer = issuer(), 'Issuer portal' );
    my $id = $issuer->login("dwho");

    my $st1 = $issuer->casGetTicket( $id, 'http://auth.sp.com/' );
    expectCasSuccess(
        $issuer->casValidateTicket( $st1, 'http://auth.sp.com/' ) );

    $issuer->casGetAndValidateTicketSuccess( $id, 'http://auth.sp2.com/' );

    # Logout
    ok(
        $res = $issuer->_get(
            '/cas/logout',
            query  => { service => 'http://auth.sp.com/?logout=done' },
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Initiate logout'
    );
    is( expectCookie($res), 0, "Cookie was cleared" );

    my ( $host, $url, $query ) =
      expectForm( $res, 'auth.sp.com', '/?logout=done' );
    is( $query, "logout=done", "Query string is preserved" );

    like( $res->[2]->[0], qr/My CAS App/, "Found CAS app name" );
    unlike( $res->[2]->[0], qr/My Other App/, "My other app is not displayed" );

    relaySpFromInfo( $issuer, $res );
    is( $loggedOut->{'auth.sp.com'},
        $st1, "Correct ticket sent to sp for logout" );
    ok( !$loggedOut->{'auth.sp2.com'}, "No ticket sent to sp2" );
};

subtest "Test App initiated logout, no redirect, no info" => sub {

    $loggedOut = {};

    # Login
    ok( $issuer = issuer(), 'Issuer portal' );
    my $id = $issuer->login("dwho");

    # Logout
    ok(
        $res = $issuer->_get(
            '/cas/logout',
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        'Initiate logout'
    );
    is( expectCookie($res), 0, "Cookie was cleared" );
    expectRedirection( $res, qr'^http://auth.example.com/\?logout=1$' );
};

sub relaySpFromInfo {
    my ( $issuer, $res ) = @_;

    my @relay_urls =
      map { $_->to_literal }
      getHtmlElement( $res, '//table[@class="sloState"]//img/@src' )
      ->get_nodelist;

    for my $url (@relay_urls) {
        my $u = URI->new($url);

        my $query = { $u->query_form };
        my $path  = $u->path;
        ok(
            $res = $issuer->_get(
                $path,
                query  => $query,
                accept => 'text/html',
            ),
            'Logout SP'
        );
    }
}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                issuerDBCASActivation      => 1,
                casBackChannelSingleLogout => 0,
                casAppMetaDataOptions      => {
                    sp1 => {
                        casAppMetaDataOptionsService => 'https://auth.sp.com/',
                        casAppMetaDataOptionsDisplayName => 'My CAS App',
                        casAppMetaDataOptionsLogout      => 1,
                    },
                    sp2 => {
                        casAppMetaDataOptionsService => 'https://auth.sp2.com/',
                        casAppMetaDataOptionsDisplayName => 'My Other App',
                        casAppMetaDataOptionsLogout      => -1,
                    },
                },
                casAccessControlPolicy => 'error',
            }
        }
    );
}
