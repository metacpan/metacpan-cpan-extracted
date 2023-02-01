use lib 'inc';
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

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

# Ticket cannot be validated against wrong service
$ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );
expectCasFail( casGetResponse( $issuer, $ticket, "http://auth.sp2.com/" ),
    "INVALID_SERVICE" );

# Tickets are invalidated after success response
$ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );
expectCasSuccess( casGetResponse( $issuer, $ticket, "http://auth.sp.com/" ) );
expectCasFail( casGetResponse( $issuer, $ticket, "http://auth.sp.com/" ) );

# Tickets are invalidated after failure response
$ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );
expectCasFail( casGetResponse( $issuer, $ticket, "http://auth.sp2.com/" ),
    "INVALID_SERVICE" );
expectCasFail( casGetResponse( $issuer, $ticket, "http://auth.sp.com/" ) );

# Ticket are no longer valid after TTL
$ticket = casGetTicket( $issuer, $idpId, "http://auth.sp.com/" );
Time::Fake->offset("+10m");
expectCasFail( casGetResponse( $issuer, $ticket, "http://auth.sp.com/" ) );

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
                        casAppMetaDataOptionsService => 'http://auth.sp.com/',
                    },
                    sp2 => {
                        casAppMetaDataOptionsService => 'http://auth.sp2.com/',
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
      expectRedirection( $res, qr#^http://auth.sp.com/\?.*(ticket=[^&]+)# );

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
    my ( $res, $code ) = @_;
    $code ||= "INVALID_TICKET";
    my $content = $res->[2]->[0];
    like(
        $content,
        qr,authenticationFailure code="([^"]+)",,
        "CAS response indicates success"
    );
    my ($response_code) = $content =~ qr,authenticationFailure code="([^"]+)",;
    is( $response_code, $code, "Incorrect CAS error code" );
    count(2);
}

sub expectCasSuccess {
    my ($res) = @_;
    my $content = $res->[2]->[0];
    like( $content, qr,cas:authenticationSuccess,,
        "CAS response indicates success" );
    count(1);
}
