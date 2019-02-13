use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            authentication => 'Apache',
            userDB         => 'Null',
        }
    }
);

ok( $res = $client->_get( '/', remote_user => 'dwho' ), 'Auth query' );
count(1);
expectOK($res);
my $id = expectCookie($res);
clean_sessions();

done_testing( count() );
