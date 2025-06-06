use warnings;
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
my ( $issuer, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:id|s)p).com([^\?]*)(?:\?(.*))?$#,
            'SOAP request' );
        my $host  = $1;
        my $url   = $2;
        my $query = $3;
        my $res;
        my $client = ( $host eq 'idp' ? $issuer : $sp );
        if ( $req->method eq 'POST' ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    query  => $query,
                    type   => 'application/xml',
                ),
                "Execute POST request to $url"
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    type  => 'application/xml',
                    query => $query,
                ),
                "Execute request to $url"
            );
        }
        expectOK($res);
        ok( getHeader( $res, 'Content-Type' ) =~ m#xml#, 'Content is XML' )
          or explain( $res->[1], 'Content-Type => application/xml' );
        count(3);
        return $res;
    }
);

$issuer = register( 'issuer', \&issuer );
$sp     = register( 'sp',     \&sp );

# Simple SP access
ok(
    $res = $sp->_get(
        '/', accept => 'text/html',
    ),
    'Unauth SP request'
);
count(1);
ok( expectCookie( $res, 'llngcasserver' ) eq 'idp', 'Get CAS server cookie' );
count(1);
expectRedirection( $res,
    'http://auth.idp.com/cas/login?service=http%3A%2F%2Fauth.sp.com%2F' );

# Query IdP
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/',
        accept => 'text/html'
    ),
    'Query CAS server'
);
count(1);
expectOK($res);
my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

# Try to authenticate to IdP
my $body = $res->[2]->[0];
$body =~ s/^.*?<form.*?>//s;
$body =~ s#</form>.*$##s;
my %fields =
  ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
$fields{user} = $fields{password} = 'french';
use URI::Escape;
my $s = join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
ok(
    $res = $issuer->_post(
        '/cas/login',
        IO::String->new($s),
        cookie => $pdata,
        accept => 'text/html',
        length => length($s),
    ),
    'Post authentication'
);
count(1);
my $idpId = expectCookie($res);

# Expect pdata to be cleared
$pdata = expectCookie( $res, 'lemonldappdata' );
ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );
count(1);

my ($query) =
  expectRedirection( $res, qr#^http://auth.sp.com/\?(ticket=[^&]+)$# );

# Back to SP
ok(
    $res = $sp->_get(
        '/',
        query  => $query,
        accept => 'text/html',
        cookie => 'llngcasserver=idp',
    ),
    'Query SP with ticket'
);
count(1);
my $spId = expectCookie($res);

# Start reauth
ok(
    $res = $sp->_get(
        "/upgradesession",
        accept => 'text/html',
        cookie => "lemonldap=$spId",
    ),
    'Post SAML request to IdP'
);
count(1);

( my $host, my $tmp, $query ) =
  expectForm( $res, undef, '/upgradesession', 'confirm' );
ok( $res->[2]->[0] =~ /trspan="askToUpgrade"/, 'Propose to upgrade session' );
count(1);
ok(
    $res = $sp->_post(
        '/upgradesession',
        $query,
        accept => 'text/html',
        cookie => "lemonldap=$spId",
    ),
    'Ask to renew'
);
count(1);

($query) =
  expectRedirection( $res, qr#^http://auth.idp.com/cas/login\?(service=.*)# );

# Query IdP
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => $query,
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    'Query CAS server'
);
count(1);

($query) =
  expectRedirection( $res, qr#^http://auth.sp.com/upgradesession\?(.*)$# );

# Back to SP
ok(
    $res = $sp->_get(
        '/upgradesession',
        query  => $query,
        accept => 'text/html',
        cookie => "llngcasserver=idp;lemonldap=$spId",
    ),
    'Query SP with ticket'
);
count(1);

my $newspId = expectCookie($res);
isnt( $spId, $newspId, "New session ID" );
count(1);

clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'idp.com',
                portal                => 'http://auth.idp.com/',
                authentication        => 'Demo',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casAttributes => { cn => 'cn', uid => 'uid', multi => 'multi' },
                casAccessControlPolicy => 'none',
                multiValuesSeparator   => ';',
                macros                 =>
                  { multi => '"value1;value2"', _whatToTrace => '$uid' },
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'sp.com',
                portal                     => 'http://auth.sp.com/',
                authentication             => 'Choice',
                userDB                     => 'Choice',
                authChoiceModules          => { '1_cas' => 'CAS;CAS;Null' },
                authChoiceSelectOnly       => 1,
                restSessionServer          => 1,
                issuerDBCASActivation      => 0,
                multiValuesSeparator       => ';',
                casSrvMetaDataExportedVars => {
                    idp => {
                        cn    => 'cn',
                        mail  => 'mail',
                        uid   => 'uid',
                        multi => 'multi',
                    }
                },
                casSrvMetaDataOptions => {
                    idp => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    }
                },
            },
        }
    );
}
