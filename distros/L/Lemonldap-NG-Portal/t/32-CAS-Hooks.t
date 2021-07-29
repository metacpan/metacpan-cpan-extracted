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

# Hook should make it fail with status 999
ok(
    $res = $issuer->_get(
        '/cas/login',
        cookie => "lemonldap=$idpId",
        query  => 'service=http://auth.sp2.com/',
        accept => 'text/html'
    ),
    'Query CAS server'
);
count(1);

expectPortalError( $res, 999, "Hook rejected the request" );

ok(
    $res = $issuer->_get(
        '/cas/login',
        cookie => "lemonldap=$idpId",
        query  => 'service=http://auth.sp.com/',
        accept => 'text/html'
    ),
    'Query CAS server'
);
count(1);
my ($query) =
  expectRedirection( $res, qr#^http://auth.sp.com/\?hooked=1&(ticket=[^&]+)$# );

ok(
    $res = $issuer->_get(
        '/cas/p3/serviceValidate',
        query  => 'service=http://auth.sp.com/&' . $query,
        accept => 'text/html'
    ),
    'Query CAS server'
);

expectOK($res);
count(1);

ok( $res->[2]->[0] =~ m#<cas:hooked>1</cas:hooked>#, "Found hook attribute" );
count(1);

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
                casAppMetaDataOptions => {
                    sp => {
                        casAppMetaDataOptionsService => 'http://auth.sp.com/',
                    },
                },
                casAppMetaDataExportedVars => {
                    sp => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    },
                },
                casAccessControlPolicy => 'error',
                multiValuesSeparator   => ';',
                customPlugins          => 't::CasHookPlugin',
            }
        }
    );
}
