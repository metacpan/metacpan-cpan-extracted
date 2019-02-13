use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            useSafeJail       => 1,
            authentication    => 'Slave',
            userDB            => 'Same',
            slaveUserHeader   => 'My-Test',
            slaveExportedVars => {
                name => 'Name',
            }
        }
    }
);

ok(
    $res = $client->_get(
        '/', custom => { HTTP_MY_TEST => 'dwho', HTTP_NAME => 'Dr Who' }
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);
clean_sessions();

done_testing( count() );
