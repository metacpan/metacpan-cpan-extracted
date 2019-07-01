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
my ( $issuer, $sp, $res );
my %handlerOR = ( issuer => [], sp => [] );

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

ok( $issuer = issuer(), 'Issuer portal' );
$handlerOR{issuer} = \@Lemonldap::NG::Handler::Main::_onReload;
count(1);
switch ('sp');
&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );

ok( $sp = sp(), 'SP portal' );
count(1);
$handlerOR{sp} = \@Lemonldap::NG::Handler::Main::_onReload;

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
switch ('issuer');
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/&gateway=true',
        accept => 'text/html'
    ),
    'Query CAS server'
);
count(1);
my ($query) = expectRedirection( $res, qr#^http://auth.sp.com/# );

# Back to SP
switch ('sp');
ok(
    $res = $sp->_get(
        '/',
        query  => $query,
        accept => 'text/html',
        cookie => "llngcasserver=idp",
    ),
    'Query SP with ticket'
);
count(1);

clean_sessions();
done_testing( count() );

sub switch {
    my $type = shift;
    @Lemonldap::NG::Handler::Main::_onReload = @{
        $handlerOR{$type};
    };
}

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBCASActivation  => 1,
                casAttr                => 'uid',
                casAttributes          => { cn => 'cn', uid => 'uid', },
                casAccessControlPolicy => 'none',
                multiValuesSeparator   => ';',
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'sp.com',
                portal                     => 'http://auth.sp.com',
                authentication             => 'CAS',
                userDB                     => 'CAS',
                restSessionServer          => 1,
                issuerDBCASActivation      => 0,
                multiValuesSeparator       => ';',
                casSrvMetaDataExportedVars => {
                    idp => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
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
