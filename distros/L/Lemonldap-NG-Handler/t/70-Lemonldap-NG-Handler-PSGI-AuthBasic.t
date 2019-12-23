use Test::More;
use MIME::Base64;

BEGIN {
    require 't/test-psgi-lib.pm';
}

my $maintests = 3;

init(
    'Lemonldap::NG::Handler::Server',
    {
        # authentication    => 'Demo',
        # userDB            => 'Same',
        # restSessionServer => 1,
        logLevel     => 'error',
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

# my $login = encode_base64("dwho:dwho");
# ok(
#     $res = $client->_get(
#         '/', undef, 'test1.example.com', undef,
#         VHOSTTYPE            => 'AuthBasic',
#         HTTP_X_FORWARDED_FOR => '127.0.0.1',
#         HTTP_AUTHORIZATION   => "Basic $login"
#     ),
#     'AuthBasic query'
# );
#
# print STDERR Data::Dumper::Dumper($res);
#
# # Check headers
# %h = @{ $res->[1] };
# ok( $h{'Auth-User'} eq 'dwho', 'Header Auth-User is set to "dwho"' )
#   or explain( \%h, 'Auth-User => "dwho"' );

count($maintests);
done_testing( count() );
clean();
