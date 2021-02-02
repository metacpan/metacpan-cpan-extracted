use Test::More;
use strict;
use IO::String;
use MIME::Base64;

require 't/test-lib.pm';

my $res;
my $maintests = 5;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            authentication => 'Choice',
            userDB         => 'Same',
            passwordDB     => 'Choice',

            authChoiceParam   => 'test',
            authChoiceModules => {
                Demo => 'Demo;Demo;Demo',
            },
            notifyOther => 1,
        }
    }
);

my $postString = buildForm( {
        user     => 'dwho',
        password => 'dwho',
        test     => 'Demo',
        url      => encode_base64( "http://test1.example.com/?param=1", '' ),
    }
);

# Create a session
ok(
    $res = $client->_post(
        '/', IO::String->new($postString),
        length => length($postString),
        accept => 'text/html',
    ),
    'Auth query'
);
my $id = expectCookie($res);

# Login with existing session
ok(
    $res = $client->_post(
        '/', IO::String->new($postString),
        length => length($postString),
        accept => 'text/html',
    ),
    'Auth query'
);
$id = expectCookie($res);

my ( $host, $uri, $params, $method ) = expectForm($res);

is( $host,   "test1.example.com", "Correct host" );
is( $params, "param=1",           "Correct params" );
is( $method, "get",               "Correct method" );

clean_sessions();

count($maintests);
clean_sessions();
done_testing( count() );
