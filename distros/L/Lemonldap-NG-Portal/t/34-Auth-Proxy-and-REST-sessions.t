use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $sp, $res, $spId, $idpId );
my %handlerOR = ( issuer => [], sp => [] );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.idp.com([^\?]*?)(?:\?(.*))?$#,
            ' @ REST request (' . $req->method . " $1)" );
        count(1);
        my $url   = $1;
        my $query = $2;
        my $res;
        my $s = $req->content;
        if ( $req->method =~ /^(post|put)$/i ) {
            my $mth = '_' . lc($1);
            my $s   = $req->content;
            ok(
                $res = $issuer->$mth(
                    $url,
                    IO::String->new($s),
                    ( $query ? ( query => $query ) : () ),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                ' Post request'
            );
            count(1);
        }
        elsif ( $req->method =~ /^(get|delete)$/i ) {
            my $mth = '_' . lc($1);
            ok(
                $res = $issuer->$mth(
                    $url,
                    ( $query ? ( query => $query ) : () ),
                    accept => $req->header('Accept'),
                    cookie => $req->header('Cookie')
                ),
                ' Execute request'
            );
            count(1);
        }
        return $res;
    }
);

ok( $issuer = issuer(), 'Issuer portal' );
$handlerOR{issuer} = \@Lemonldap::NG::Handler::Main::_onReload;
switch ('sp');
&Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );

ok( $sp = sp(), 'SP portal' );
$handlerOR{sp} = \@Lemonldap::NG::Handler::Main::_onReload;
count(2);

# Simple SP access
ok(
    $res = $sp->_get(
        '/', accept => 'text/html',
    ),
    'Unauth SP request'
);
expectOK($res);

# Try to auth
ok(
    $res = $sp->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html'
    ),
    'Post user/password'
);
count(2);
expectRedirection( $res, 'http://auth.sp.com' );
$spId = expectCookie($res);

# Logout
ok(
    $res = $sp->_get(
        '/',
        query  => 'logout',
        accept => 'text/html',
        cookie => "lemonldap=$spId"
    ),
    'Ask for logout'
);
count(1);
expectOK($res);

# Test if user is reject on IdP
ok(
    $res = $sp->_get(
        '/', cookie => "lemonldap=$spId",
    ),
    'Test if user is reject on IdP'
);
count(1);
expectReject($res);

clean_sessions();
done_testing( count() );

# Redefine LWP methods for tests
no warnings 'redefine';

sub switch {
    my $type = shift;
    @Lemonldap::NG::Handler::Main::_onReload = @{
        $handlerOR{$type};
    };
}

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'idp.com',
                portal            => 'http://auth.idp.com',
                authentication    => 'Demo',
                secret            => 'abc',
                userDB            => 'Same',
                restSessionServer => 1,
                restConfigServer  => 1,
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel         => $debug,
                domain           => 'sp.com',
                portal           => 'http://auth.sp.com',
                authentication   => 'Proxy',
                userDB           => 'Same',
                secret           => 'abc',
                proxyAuthService => 'http://auth.idp.com',
                proxyUseSoap     => 0,
                whatToTrace      => '_whatToTrace',
                globalStorage => 'Lemonldap::NG::Common::Apache::Session::REST',
                globalStorageOptions => {
                    'baseUrl' => 'http://auth.idp.com/sessions/global',
                }
            },
        }
    );
}
