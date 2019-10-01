use Test::More;
use strict;
use JSON;
use Lemonldap::NG::Portal::Main::Constants qw(PE_FORBIDDENIP PE_USERNOTFOUND);

require 't/test-lib.pm';

my $res;
my $json;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel           => 'error',
            useSafeJail        => 1,
            securedCookie      => 3,
            authentication     => 'Slave',
            userDB             => 'Same',
            slaveUserHeader    => 'My-Test',
            slaveHeaderName    => 'Check-Slave',
            slaveHeaderContent => 'Password',
            slaveMasterIP      => '127.0.0.1',
            slaveExportedVars  => {
                name => 'Name',
            }
        }
    }
);

# Bad password
ok(
    $res = $client->_get(
        '/',
        ip     => '127.0.0.1',
        custom => {
            HTTP_MY_TEST     => 'dwho',
            HTTP_NAME        => 'Dr Who',
            HTTP_CHECK_SLAVE => 'Passwor',
        }

    ),
    'Auth query'
);
ok( $res->[0] == 401, 'Get 401' ) or explain( $res->[0], 401 );
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_FORBIDDENIP, 'Response is PE_FORBIDDENIP' )
  or explain( $json, "error => 75" );
count(4);

# Good credentials with forbidden IP
ok(
    $res = $client->_get(
        '/',
        ip     => '127.0.0.2',
        custom => {
            HTTP_MY_TEST     => 'dwho',
            HTTP_NAME        => 'Dr Who',
            HTTP_CHECK_SLAVE => 'Password',
        }

    ),
    'Auth query'
);
ok( $res->[0] == 401, 'Get 401' ) or explain( $res->[0], 401 );
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_FORBIDDENIP, 'Response is PE_FORBIDDENIP' )
  or explain( $json, "error => 75" );
count(4);

# Good credentials without slaveUserHeader
ok(
    $res = $client->_get(
        '/',
        ip     => '127.0.0.1',
        custom => {
            HTTP_MY_TES      => 'dwho',
            HTTP_NAME        => 'Dr Who',
            HTTP_CHECK_SLAVE => 'Password',
        }

    ),
    'Auth query'
);
ok( $res->[0] == 401, 'Get 401' ) or explain( $res->[0], 401 );
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_USERNOTFOUND, 'Response is PE_USERNOTFOUND' )
  or explain( $json, "error => 4" );
count(4);

# Good credentials with acredited IP
ok(
    $res = $client->_get(
        '/',
        ip     => '127.0.0.1',
        custom => {
            HTTP_MY_TEST     => 'dwho',
            HTTP_NAME        => 'Dr Who',
            HTTP_CHECK_SLAVE => 'Password',
        }

    ),
    'Auth query'
);
count(1);
expectOK($res);

my $id      = expectCookie($res);
my $id_http = expectCookie( $res, 'lemonldaphttp' );
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{id} eq "$id", 'Session id found' )
  or explain( $json, "id => session_id" );
ok( $json->{id_http} eq "$id_http", 'httpSession id found' )
  or explain( $json, "id_http => http_session_id" );
count(3);

clean_sessions();

done_testing( count() );
