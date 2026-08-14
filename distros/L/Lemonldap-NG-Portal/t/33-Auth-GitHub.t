use warnings;
use strict;
use utf8;
use Test::More;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use JSON qw(to_json);
use URI;

BEGIN {
    require 't/test-lib.pm';
}

my $clientID     = 'Iv1.0123456789abcdef';
my $clientSecret = 's3cr3t';
my $token        = 'gho_TOKEN';

my $ghUser = {
    login => 'dwho',
    id    => 42,
    name  => 'Doctor Who',
    email => 'dwho@badwolf.org',
};

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);

        # 1. Token endpoint
        if ( $req->path =~ m#/access_token$# ) {
            my $form = $req->body_parameters;
            is( $form->{client_id},     $clientID,     ' Good client_id' );
            is( $form->{client_secret}, $clientSecret, ' Good client_secret' );
            is( $form->{code},          'GHCODE',      ' Good code' );
            count(3);
            return [
                200,
                [ 'Content-Type' => 'application/json' ],
                [
                    to_json(
                        { access_token => $token, token_type => 'bearer' }
                    )
                ]
            ];
        }

        # 2. User endpoint
        elsif ( $req->path =~ m#/user$# ) {
            is( $req->header('Authorization'),
                "token $token", ' Good access token' );
            count(1);
            return [
                200,
                [ 'Content-Type' => 'application/json' ],
                [ to_json($ghUser) ]
            ];
        }

        fail( 'Unexpected GitHub request ' . $req->uri );
        count(1);
        return [ 500, [], [] ];
    }
);

# Read a state token from the global session storage
sub getStateSession {
    my $id = shift;
    $id = $ENV{LLNG_HASHED_SESSION_STORE} ? id2storage($id) : $id;
    return Lemonldap::NG::Common::Session->new( {
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => {
                Directory     => $main::tmpDir,
                LockDirectory => "$main::tmpDir/lock",
            },
            kind => 'TOKEN',
            id   => $id,
        }
    );
}

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel           => 'error',
            useSafeJail        => 1,
            authentication     => 'GitHub',
            userDB             => 'Null',
            restSessionServer  => 1,
            githubClientID     => $clientID,
            githubClientSecret => $clientSecret,
            githubUserField    => 'login',
        }
    }
);

my $res;

# 1. Unauthenticated user asking for an application is redirected to GitHub
ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
        accept => 'text/html'
    ),
    'Unauth request'
);
count(1);
my ($query) = expectRedirection( $res,
    qr#^https://github\.com/login/oauth/authorize\?(.*)$# );

my %params = URI->new("http://x/?$query")->query_form;
is( $params{client_id},     $clientID, ' Good client_id' );
is( $params{response_type}, 'code',    ' Good response_type' );
ok( $params{state}, ' State is set' );
count(3);
my $state = $params{state};

# The user may come back on any portal of the farm: the state must be stored
# in the global storage even though tokenUseGlobalStorage is not set, and as a
# token, so that it cannot be replayed as a SSO session
my $stateSession = getStateSession($state);
ok( !$stateSession->error, ' State stored in global storage as a token' )
  or explain( $stateSession->error );
is( $stateSession->data->{_type}, 'githubState', ' Good state type' );
count(2);

# 2. The state must not be usable as a session cookie
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$state",
        accept => 'text/html'
    ),
    'Try to replay state as a session cookie'
);
count(1);
ok(
    $res->[0] != 200 || $res->[2]->[0] !~ /appslist/,
    ' State is not accepted as a session'
) or explain( $res->[0], 'not an authenticated portal page' );
count(1);

# 3. A response without state must be rejected
ok(
    $res = $client->_get(
        '/',
        query  => 'code=GHCODE',
        accept => 'text/html'
    ),
    'GitHub response without state'
);
count(1);
expectPortalError( $res, 24 );

# 4. A response with an unknown state must be rejected
ok(
    $res = $client->_get(
        '/',
        query  => 'code=GHCODE&state=xxxxxxxx',
        accept => 'text/html'
    ),
    'GitHub response with bad state'
);
count(1);
expectPortalError( $res, 24 );

# 5. Nominal case
ok(
    $res = $client->_get(
        '/',
        query  => "code=GHCODE&state=$state",
        accept => 'text/html'
    ),
    'GitHub response'
);
count(1);

# The state must have restored the URL initially requested
expectRedirection( $res, 'http://test1.example.com/' );
my $id = expectCookie($res);
expectSessionAttributes(
    $client, $id,
    _user        => $ghUser->{login},
    github_login => $ghUser->{login},
    github_name  => $ghUser->{name},
    github_email => $ghUser->{email},
);

# 6. State is a one-shot token: replaying it must fail
ok(
    $res = $client->_get(
        '/',
        query  => "code=GHCODE&state=$state",
        accept => 'text/html'
    ),
    'Replayed GitHub response'
);
count(1);
expectPortalError( $res, 24 );

clean_sessions();

done_testing( count() );
