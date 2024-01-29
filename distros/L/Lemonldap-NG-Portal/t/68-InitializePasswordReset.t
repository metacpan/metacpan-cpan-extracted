use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;
use LWP::UserAgent;

require 't/test-lib.pm';

my $res;
my $maintests = 11;

no warnings 'once';

my $client = LLNG::Manager::Test->new(
    {
        ini => {
            portal                        => 'http://auth.example.com/',
            mailUrl                       => 'http://auth.example.com/resetpwd',
            authentication                => 'Demo',
            userDB                        => 'Same',
            passwordDB                    => 'Demo',
            logLevel                      => 'error',
            portalDisplayResetPassword    => 1,
            initializePasswordReset       => 1,
            initializePasswordResetSecret => 'UoIpS0aKXuSE7SQT',
        }
    }
);


# Try yo authenticate
# -------------------
ok(
    $res = $client->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query'
);
expectOK($res);
my $id = expectCookie($res);

my $request = '{"mail":"rtyler@badwolf.org","secret":"UoIpS0aKXuSE7SQT"}';
ok(
    $res = $client->_post(
        '/initializepasswordreset',
        IO::String->new($request),
        type => 'application/json',
        length => length($request)
    ),
    'Force reinitialization for rtyler@badwolf.org'
);
expectOK($res);
my $json = expectJSON($res);

ok(
    $json->{mail_token},
    'mail_token found'
);

ok(
    $json->{url} =~ /^http:\/\/auth\.example\.com\/resetpwd\?mail_token=[a-z0-9]+$/,
    'reset url found and have a correct format'
);

$request = '{"mail":"rtyler@badwolf.org","secret":"dummy"}';
ok(
    $res = $client->_post(
        '/initializepasswordreset',
        IO::String->new($request),
        type => 'application/json',
        length => length($request)
    ),
    'Force reinitialization for rtyler@badwolf.org - bad secret'
);
expectForbidden($res);
eval { $json = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is valid JSON' );
ok(
    $json->{msg} =~ /^InitializePasswordReset: authentication error$/,
    'authentication error'
);

$request = '{"mail":"unknown@badwolf.org","secret":"UoIpS0aKXuSE7SQT"}';
ok(
    $res = $client->_post(
        '/initializepasswordreset',
        IO::String->new($request),
        type => 'application/json',
        length => length($request)
    ),
    'Force reinitialization for rtyler@badwolf.org - user not found'
);
ok( $res->[0] == 404, ' HTTP code is 404' ) or explain( $res, 404 );
eval { $json = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is valid JSON' );
ok(
    $json->{msg} =~ /^InitializePasswordReset: user unknown\@badwolf\.org not found$/,
    'user not found'
);

count($maintests);
clean_sessions();
done_testing( count() );
