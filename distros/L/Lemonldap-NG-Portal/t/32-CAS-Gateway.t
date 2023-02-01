use lib 'inc';
use Test::More;
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

plan skip_all => "Missing dependencies: $@" if ($@);

# Access control "None"
ok( $issuer = issuer('none'), 'Issuer portal' );
count(1);

# Gateway to known URL is ok
$res = gatewayRequest( $issuer, "http://auth.sp.com/somewhere" );
expectRedirection( $res, 'http://auth.sp.com/somewhere' );

# Gateway to unknown URL is ok
$res = gatewayRequest( $issuer, "http://auth.unknown.com/somewhere" );
expectRedirection( $res, 'http://auth.unknown.com/somewhere' );

# Access control "Error"
ok( $issuer = issuer('error'), 'Issuer portal' );
count(1);

# Gateway to known URL is ok
$res = gatewayRequest( $issuer, "http://auth.sp.com/somewhere" );
expectRedirection( $res, 'http://auth.sp.com/somewhere' );

# Gateway to unknown URL is denied
$res = gatewayRequest( $issuer, "http://auth.unknown.com/somewhere" );
expectPortalError( $res, 107 );

# Access control "Fake ticket"
ok( $issuer = issuer('faketicket'), 'Issuer portal' );
count(1);

# Gateway to known URL is ok
$res = gatewayRequest( $issuer, "http://auth.sp.com/somewhere" );
expectRedirection( $res, 'http://auth.sp.com/somewhere' );

# Gateway to unknown URL is denied
$res = gatewayRequest( $issuer, "http://auth.unknown.com/somewhere" );
expectPortalError( $res, 107 );

clean_sessions();
done_testing( count() );

sub gatewayRequest {
    my ( $issuer, $url ) = @_;
    return $issuer->_get(
        '/cas/login',
        query => buildForm( {
                gateway => "true",
                service => $url,

            }
        ),
        accept => 'text/html',
    );
}

sub issuer {
    my ($policy) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'idp.com',
                portal                => 'http://auth.idp.com',
                authentication        => 'Demo',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casAppMetaDataOptions => {
                    sp2 => {
                        casAppMetaDataOptionsService => 'http://auth.sp.com/',
                        casAppMetaDataOptionsRule    => "0",
                    },
                },
                casAccessControlPolicy => $policy,
                multiValuesSeparator   => ';',
            }
        }
    );
}
