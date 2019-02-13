use Test::More;
use strict;
use Data::Dumper;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
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

ok( $res = $client->_get( '/lmerror/403', accept => 'text/html' ),
    'lmerror 403 query' );
expectOK($res);
ok( $res->[2]->[0] =~ qq%<img src="/static/common/logos/logo_llng_400px.png"%,
    'Found custom Main Logo' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, 'Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

clean_sessions();

done_testing( count() );
