use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');
count(1);

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            upgradeSession    => 0,
            authentication    => 'Choice',
            apacheAuthnLevel  => 5,
            userDB            => 'Same',
            authChoiceModules => {
                'strong' => 'Apache;Demo;Null;;;{}',
                'weak'   => 'Demo;Demo;Null;;;{}'
            },
            vhostOptions => {
                'test1.example.com' => {
                    'vhostAuthnLevel' => 3
                }
            },
            locationRules => {
                "test1.example.com" => {
                    'default'                      => 'accept',
                    '^/AuthWeak(?#AuthnLevel=2)'   => 'deny',
                    '^/AuthStrong(?#AuthnLevel=5)' => 'deny'
                }
            }
        }
    }
);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho&lmAuth=weak'),
        length => 35,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);
my $id = expectCookie($res);

ok(
    $res = $client->_get(
        '/AuthWeak',
        accept => 'text/html',
        cookie => "lemonldap=$id",
        host   => 'test1.example.com',
    ),
    'GET http://test1.example.com/AuthWeak'
);
count(1);

ok(
    $res = $client->_get(
        '/AuthStrong',
        accept => 'text/html',
        cookie => "lemonldap=$id",
        host   => 'test1.example.com',
    ),
    'GET http://test1.example.com/AuthStrong'
);
count(1);
expectForbidden($res);

$client->logout($id);
clean_sessions();
done_testing( count() );

