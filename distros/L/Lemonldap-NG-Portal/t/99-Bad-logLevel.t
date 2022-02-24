use Test::More;
use strict;
use Data::Dumper;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error ',
            useSafeJail    => 1,
            authentication => 'Null',
            userDB         => 'Same',
        }
    }
);

ok( $res = $client->_get('/'), 'Auth query' );
count(1);
expectOK($res);
my $id = expectCookie($res);
ok(
    $res = $client->_get(
        '/logout', accept => 'text/html'
    ),
    'Get logout page'
);
ok( $res->[2]->[0] =~ m%<span trmsg="47">%, ' PE_LOGOUT_OK' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

clean_sessions();

done_testing( count() );
