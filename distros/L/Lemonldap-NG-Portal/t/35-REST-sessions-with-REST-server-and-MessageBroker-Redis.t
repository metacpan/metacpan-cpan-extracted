use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Time::Fake;

BEGIN {
    require 't/test-lib.pm';
}

my ( $issuer, $sp, $res, $spId );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok(
            $req->uri =~ m#http://auth.idp.com(.*?)(?:\?(.*))?$#,
            ' @ REST request ('
              . $req->method . " $1"
              . ( $2 ? "?$2" : '' ) . ")"
        );
        my $url   = $1;
        my $query = $2;
        my $res;
        if ( $req->method =~ /^(post|put)$/i ) {
            my $mth = '_' . lc($1);
            my $s   = $req->content;
            ok(
                $res = $issuer->$mth(
                    $url,
                    IO::String->new($s),
                    query  => $query,
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                ' Post request'
            );
            expectOK($res);
        }
        elsif ( $req->method =~ /^(get|delete)$/i ) {
            my $mth = '_' . lc($1);
            ok(
                $res = $issuer->$mth(
                    $url,
                    accept => $req->header('Accept'),
                    cookie => $req->header('Cookie'),
                    query  => $query,
                ),
                ' Execute request'
            );
            ok( ( $res->[0] == 200 or $res->[0] == 400 ),
                ' Response is 200 or 400' )
              or explain( $res->[0], '200 or 400' );
        }
        pass(' @ END OF REST REQUEST');
        return $res;
    }
);

SKIP: {
    skip( "LLNGTESTREDIS isn't set", 1 ) unless $ENV{LLNGTESTREDIS};
    require 't/redis/redis.pm';
    skip( 'Redis is missing',        1 ) if $main::noRedis;
    &startRedis;

    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

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
            '/', IO::String->new('user=french&password=french'),
            length => 27,
            accept => 'text/html'
        ),
        'Post user/password'
    );
    expectRedirection( $res, 'http://auth.sp.com/' );
    $spId = expectCookie($res);

    # Test auth
    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Auth test' );
    expectOK($res);

    # Logout
    ok(
        $res = $issuer->_get(
            '/',
            query  => 'logout',
            accept => 'text/html',
            cookie => "lemonldap=$spId"
        ),
        'Ask for logout'
    );
    expectOK($res);
    Time::Fake->offset('+6s');

    # Test if user is reject on IdP
    ok(
        $res = $sp->_get(
            '/', cookie => "lemonldap=$spId",
        ),
        'Test if user is reject on IdP'
    );
    expectReject($res);

    # Test if user is reject on SP
    ok(
        $res = $sp->_get(
            '/', cookie => "lemonldap=$spId",
        ),
        'Test if user is reject on SP'
    );
    expectReject($res);
    eval { &stopRedis };

}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                domain            => 'idp.com',
                portal            => 'http://auth.idp.com/',
                authentication    => 'Demo',
                userDB            => 'Same',
                restSessionServer => 1,
                messageBroker        => '::Redis',
                messageBrokerOptions => {
                    server => &REDISSERVER,
                },
                localSessionStorageOptions => {
                    namespace   => 'lemonldap-ng-session',
                    cache_root  => "$main::tmpDir/idp",
                    cache_depth => 0,
                    allow_cache_for_root => 1,
                },
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                domain         => 'sp.com',
                portal         => 'http://auth.sp.com/',
                authentication => 'Demo',
                userDB         => 'Same',
                globalStorage => 'Lemonldap::NG::Common::Apache::Session::REST',
                globalStorageOptions => {
                    baseUrl => 'http://auth.idp.com/sessions/global/'
                },
                persistentStorage =>
                  'Lemonldap::NG::Common::Apache::Session::REST',
                persistentStorageOptions => {
                    baseUrl => 'http://auth.idp.com/sessions/persistent/'
                },
                messageBroker        => '::Redis',
                messageBrokerOptions => {
                    server => &REDISSERVER,
                },
                localSessionStorageOptions => {
                    namespace   => 'lemonldap-ng-session',
                    cache_root  => "$main::tmpDir/sp",
                    cache_depth => 0,
                    allow_cache_for_root => 1,
                },
            },
        }
    );
}
