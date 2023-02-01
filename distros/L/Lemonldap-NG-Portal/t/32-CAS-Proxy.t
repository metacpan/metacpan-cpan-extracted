use lib 'inc';
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use XML::LibXML;

use LWP::UserAgent;
use LWP::Protocol::PSGI;

our $PGTs = {};

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        my $iou = $req->param("pgtIou");
        my $pgt = $req->param("pgtId");
        $PGTs->{$iou} = $pgt;
        return [ 200, [], [] ];
    }
);

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $res );

eval { require XML::Simple };
plan skip_all => "Missing dependencies: $@" if ($@);

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

# Request to an unknown service is rejected
ok(
    $res = $issuer->_get(
        '/cas/login',
        cookie => "lemonldap=$idpId",
        query  => 'service=http://auth.sp3.com/',
        accept => 'text/html'
    ),
    'Query CAS server'
);
count(1);

expectPortalError( $res, 107, "Unknown CAS service" );

my $ticket;
my $iou;

# Get a ticket for CAS application
$ticket = casGetTicket( $issuer, $idpId, "http://casapp.com/" );

# CAS application gets PGT
my $pgt = casGetPgt( $issuer, $ticket, "http://casapp.com/",
    "http://casapp.com/proxy" );

# CAS application gets PT for web service
my $pt = casGetProxyTicket( $issuer, $pgt, "http://service.com/srv" );

# Service validate PT and gets PGT
my $pgt2 = casGetPgt( $issuer, $pt, "http://service.com/srv",
    "http://service.com/proxy" );

# Service gets PT for sub-service
my $pt2 = casGetProxyTicket( $issuer, $pgt2, "http://subservice.com/srv" );

# Sub-service validates PT
my $res = casGetProxyResponse( $issuer, $pt2, "http://subservice.com/srv" );
expectCasSuccess($res);

is_deeply( [
        casXPathAll(
            $res->[2]->[0],
            '/cas:serviceResponse/cas:authenticationSuccess'
              . '/cas:proxies/cas:proxy/text()'
        )
    ],
    [ "http://service.com/proxy", "http://casapp.com/proxy" ],
    "Found proxies in correct order"
);
count(1);

# Make sure PGT is still valid a long time later
Time::Fake->offset("+10h");
my $pt = casGetProxyTicket( $issuer, $pgt, "http://service.com/srv" );
expectCasSuccess(
    casGetProxyResponse( $issuer, $pt, "http://service.com/srv" ) );

clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'idp.com',
                portal                => 'http://auth.idp.com',
                authentication        => 'Demo',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casTicketExpiration   => '300',
                casAppMetaDataOptions => {
                    sp => {
                        casAppMetaDataOptionsService => 'http://casapp.com/',
                    },
                },
                casAppMetaDataExportedVars => {
                    sp => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    },
                    sp2 => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    },
                },
                casAccessControlPolicy => 'error',
                multiValuesSeparator   => ';',
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
      expectRedirection( $res, qr#^http://casapp.com/\?.*ticket=([^&]+)# );

    return $ticket;
}

sub casGetPgt {
    my ( $issuer, $ticket, $service, $pgtUrl ) = @_;
    ok(
        my $res = $issuer->_get(
            '/cas/p3/proxyValidate',
            query => buildForm( {
                    service => $service,
                    ticket  => $ticket,
                    pgtUrl  => $pgtUrl,
                }
            ),
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    count(1);

    expectOK($res);

    my $pgt = casXPath( $res->[2]->[0], '//cas:proxyGrantingTicket/text()' );
    return $PGTs->{$pgt};
}

sub casGetProxyResponse {
    my ( $issuer, $ticket, $service ) = @_;
    ok(
        my $res = $issuer->_get(
            '/cas/p3/proxyValidate',
            query  => buildForm( { service => $service, ticket => $ticket } ),
            accept => 'text/html'
        ),
        'Query CAS server'
    );

    expectOK($res);
    count(1);
    return $res;
}

sub casGetProxyTicket {
    my ( $issuer, $pgt, $service ) = @_;
    ok(
        my $res = $issuer->_get(
            '/cas/proxy',
            query => buildForm( {
                    pgt           => $pgt,
                    targetService => $service,
                }
            ),
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    count(1);

    my $pt = casXPath( $res->[2]->[0],
        '/cas:serviceResponse/cas:proxySuccess/cas:proxyTicket/text()' );
    return $pt;
}

sub expectCasSuccess {
    my ($res) = @_;
    my $content = $res->[2]->[0];
    ok(
        casXPath( $content, '/cas:serviceResponse/cas:authenticationSuccess' ),
        "Cas response contains authenticationSuccess"
    );
    count(1);
}

sub casXPath {
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
    my ( $xmlString, $expr ) = @_;

    my $dom = XML::LibXML->load_xml( string => $xmlString );
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs( 'cas', 'http://www.yale.edu/tp/cas' );
    return $xpc->findnodes($expr);
}
