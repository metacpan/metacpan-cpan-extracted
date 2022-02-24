use Test::More;
use strict;

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new(
    { ini => { logLevel => 'error', useSafeJail => 1 } } );

# Test unauthenticated logout request with param
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        accept => 'text/html'
    ),
    'Get logout page'
);
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span trmsg="47">%, ' PE_LOGOUT_OK' )
  or print STDERR Dumper( $res->[2]->[0] );
expectCookie($res);
count(3);

# Test unauthenticated logout request access with route
ok(
    $res = $client->_get(
        '/logout', accept => 'text/html'
    ),
    'Get logout page'
);
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span trmsg="47">%, ' PE_LOGOUT_OK' )
  or print STDERR Dumper( $res->[2]->[0] );
expectCookie($res);
count(3);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );
