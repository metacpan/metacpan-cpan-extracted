use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

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
        count(1);
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
            count(1);
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
            count(2);
        }
        pass(' @ END OF REST REQUEST');
        count(1);
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
count(2);
expectRedirection( $res, 'http://auth.sp.com/' );
$spId = expectCookie($res);

# Test auth
ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Auth test' );
count(1);
expectOK($res);

# Test other REST queries

# Session content
$res = getSession($spId)->data;
ok(
    $res->{_session_id} eq
      ( $ENV{LLNG_HASHED_SESSION_STORE} ? id2storage($spId) : $spId ),
    ' Good ID'
) or explain( $res, "_session_id => $spId" );
ok( $res->{array} =~ /;/, 'Mulivalued attribute found' )
  or explain( $res, "Multivalued attribute" );
count(2);

# Session key
$res = getSession($spId)->data;
ok(
    $res->{_session_id} eq
      ( $ENV{LLNG_HASHED_SESSION_STORE} ? id2storage($spId) : $spId ),
    ' Good ID'
) or explain( $res, "_session_id => $spId" );
ok( $res->{uid} eq 'french', ' Uid is french' )
  or explain( $res, 'uid => french' );

#ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
#  or explain( $res->{cn}, 'Frédéric Accents' );
count(2);

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

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                domain            => 'idp.com',
                portal            => 'http://auth.idp.com/',
                authentication    => 'Demo',
                userDB            => 'Same',
                restSessionServer => 1,
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
            },
        }
    );
}
