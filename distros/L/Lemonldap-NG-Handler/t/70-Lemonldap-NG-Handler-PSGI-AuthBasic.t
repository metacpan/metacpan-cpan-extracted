use Test::More;
use MIME::Base64;
use POSIX qw(strftime);
use URI::Escape;
use Lemonldap::NG::Common::Session;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-psgi-lib.pm';
}

# Mock LWP to intercept portal REST calls from AuthBasic handler
LWP::Protocol::PSGI->register(
    sub {
        my ($env) = @_;
        my $method = $env->{REQUEST_METHOD};
        my $path   = $env->{PATH_INFO};
        my $query  = $env->{QUERY_STRING} // '';

        # Only handle POST /sessions/global/<id>?auth
        return [ 404, [], [] ] unless $method eq 'POST';
        return [ 404, [], [] ] unless $path =~ m{^/sessions/global/([0-9a-f]+)$};
        my $id = $1;

        # Read body
        my $body = '';
        if ( my $input = $env->{'psgi.input'} ) {
            $input->read( $body, $env->{CONTENT_LENGTH} || 4096 );
        }

        # Decode application/x-www-form-urlencoded body
        my %params;
        for my $pair ( split /&/, $body ) {
            my ( $k, $v ) = split /=/, $pair, 2;
            $params{ URI::Escape::uri_unescape($k) } =
              URI::Escape::uri_unescape( $v // '' );
        }

        my $user = $params{user}     // '';
        my $pwd  = $params{password} // '';

        # Simple credential check (Demo backend: user eq password)
        unless ( $user ne '' && $user eq $pwd ) {
            return [ 401, [], [] ];
        }

        # Build session data matching Demo backend output
        my $now = time;
        my $ts = strftime( "%Y%m%d%H%M%S", localtime($now) );
        my $sessionData = {
            '_timezone'       => '1',
            'groups'          => 'users; timelords',
            'uid'             => $user,
            'cn'              => 'Doctor Who',
            '_lastAuthnUTime' => $now,
            '_whatToTrace'    => $user,
            '_issuerDB'       => 'Null',
            '_startTime'      => "$ts",
            '_user'           => $user,
            '_updateTime'     => "$ts",
            '_userDB'         => 'Demo',
            'ipAddr'          => '127.0.0.1',
            'mail'            => "$user\@badwolf.org",
            'authenticationLevel' => 2,
            '_utime'          => $now,
            '_passwordDB'     => 'Demo',
            '_auth'           => 'Demo',
        };

        my $session = Lemonldap::NG::Common::Session->new( {
                storageModule        => 'Apache::Session::File',
                storageModuleOptions => { Directory => 't/sessions' },
                id                   => $id,
                force                => 1,
                kind                 => 'SSO',
                info                 => $sessionData,
            }
        );

        return [ 200, [ 'Content-Type', 'text/plain' ], ['OK'] ];
    }
);

my $maintests = 5;

init(
    'Lemonldap::NG::Handler::Server',
    {
        authentication    => 'Demo',
        userDB            => 'Same',
        vhostOptions => {
            'test1.example.com' => {
                vhostHttps           => 0,
                vhostPort            => 80,
                vhostMaintenance     => 0,
                vhostServiceTokenTTL => -1,
            },
        },
        exportedHeaders => {
            'test1.example.com' => {
                'Auth-User' => '$uid',
            },
        }
    }
);

ok(
    $res = $client->_get(
        '/', undef, 'test1.example.com', undef, VHOSTTYPE => 'AuthBasic',
    ),
    'Query'
);
ok( $res->[0] == 401, 'Code is 401' ) or explain( $res->[0], 302 );

# Check headers
%h = @{ $res->[1] };
ok(
    $h{'WWW-Authenticate'} =~ m%^Basic realm="LemonLDAP::NG"$%,
    'Header WWW-Authenticate is set to Basic realm="LemonLDAP::NG"'
) or explain( \%h, 'WWW-Authenticate => realm' );

my $login = encode_base64("dwho:dwho");
ok(
    $res = $client->_get(
        '/', undef, 'test1.example.com', undef,
        VHOSTTYPE            => 'AuthBasic',
        HTTP_X_FORWARDED_FOR => '127.0.0.1',
        HTTP_AUTHORIZATION   => "Basic $login"
    ),
    'AuthBasic query'
);

# Check headers
%h = @{ $res->[1] };
ok( $h{'Auth-User'} eq 'dwho', 'Header Auth-User is set to "dwho"' )
  or explain( \%h, 'Auth-User => "dwho"' );

count($maintests);
done_testing( count() );
clean();
