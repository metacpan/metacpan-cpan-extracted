use Test::More;
use strict;
use JSON;
use Lemonldap::NG::Portal::Main::Constants qw(PE_FIRSTACCESS);

require 't/test-lib.pm';

my $res;
my $json;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            useSafeJail       => 1,
            authentication    => 'Choice',
            userDB            => 'Same',
            passwordDB        => 'Choice',
            authChoiceModules => {
                '1_Demo'  => 'Demo;Demo;Null',
                '2_Slave' => 'Slave;Demo;Null',
            },
            slaveUserHeader   => 'My-Test',
            slaveExportedVars => {
                name => 'Name',
            }
        }
    }
);

# Good credentials with bad module
ok(
    $res = $client->_get(
        '/',
        query  => 'lmAuth=1_Slave',
        ip     => '127.0.0.1',
        custom => {
            HTTP_MY_TEST => 'dwho',
            HTTP_NAME    => 'Dr Who',
        }

    ),
    'Auth query'
);
ok( $res->[0] == 401, 'Get 401' ) or explain( $res->[0], 401 );
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == PE_FIRSTACCESS, 'Response is PE_FIRSTACCESS' )
  or explain( $json, "error => 9" );
count(4);

# Good credentials with right module
ok(
    $res = $client->_get(
        '/',
        query  => 'lmAuth=2_Slave',
        ip     => '127.0.0.2',
        custom => {
            HTTP_MY_TEST => 'dwho',
            HTTP_NAME    => 'Dr Who',
        }

    ),
    'Auth query'
);
count(1);

expectOK($res);
expectCookie($res);

clean_sessions();
done_testing( count() );
