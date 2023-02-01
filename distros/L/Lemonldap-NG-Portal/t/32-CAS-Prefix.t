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

eval { require XML::Simple };
plan skip_all => "Missing dependencies: $@" if ($@);

# Login
ok( $issuer = issuer(), 'Issuer portal' );
count(1);
my $s  = "user=dwho&password=dwho";
my $id = expectCookie(
    $issuer->_post(
        '/',
        IO::String->new($s),
        accept => 'text/html',
        length => length($s),
    )
);

# Service 1, will be matched by URI
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/srv1/index.php',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Query CAS server'
);
count(1);
expectRedirection( $res,
    qr#^http://auth.sp.com/srv1/index.php\?(ticket=[^&]+)$# );

# Service 2, will be matched by hostname
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.other.com/srv2',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Query CAS server'
);
count(1);
expectRedirection( $res, qr#^http://auth.other.com/srv2\?(ticket=[^&]+)$# );

# Service defined with multiple URLs, will be matched by URI
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/srv4/index.php',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Query CAS server'
);
count(1);
expectRedirection( $res,
    qr#^http://auth.sp.com/srv4/index.php\?(ticket=[^&]+)$# );

# New test with StrictMatching
ok( $issuer = issuer(1), 'Issuer portal' );
count(1);

# Service 1, will be matched by URI
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/srv1/index.php',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Query CAS server'
);
count(1);
expectRedirection( $res,
    qr#^http://auth.sp.com/srv1/index.php\?(ticket=[^&]+)$# );

# Service 2, will now fail
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.other.com/srv2',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Query CAS server'
);
count(1);
expectPortalError( $res, 107 );

# Service defined with multiple URLs, will be matched by URI
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/srv4/index.php',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'Query CAS server'
);
count(1);
expectRedirection( $res,
    qr#^http://auth.sp.com/srv4/index.php\?(ticket=[^&]+)$# );

clean_sessions();
done_testing( count() );

sub issuer {
    my ($strict) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'idp.com',
                portal                => 'http://auth.idp.com',
                authentication        => 'Demo',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casStrictMatching     => $strict,
                casAppMetaDataOptions => {
                    sp1 => {
                        casAppMetaDataOptionsService =>
                          'https://auth.other.com/xxxyz',
                        casAppMetaDataOptionsRule => "1",
                    },
                    sp2 => {
                        casAppMetaDataOptionsService => 'http://auth.sp.com/',
                        casAppMetaDataOptionsRule    => "0",
                    },
                    sp3 => {
                        casAppMetaDataOptionsService =>
                          'http://auth.sp.com/srv1/',
                        casAppMetaDataOptionsRule => "1",
                    },
                    sp4 => {
                        casAppMetaDataOptionsService =>
                          'http://auth.sp.com/srv2/',
                        casAppMetaDataOptionsRule => "0",
                    },
                    sp5 => {
                        casAppMetaDataOptionsService =>
'http://auth.sp.com/srv3/ http://auth.sp.com/srv4/ http://auth.sp.com/srv5/',
                        casAppMetaDataOptionsRule => "1",
                    },
                },
                casAccessControlPolicy => 'error',
                multiValuesSeparator   => ';',
            }
        }
    );
}
