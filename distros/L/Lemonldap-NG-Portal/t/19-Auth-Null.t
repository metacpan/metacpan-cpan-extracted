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
            scrollTop      => 100,
            locationRules  => {
                'test1.example.com' => {
                    default => 'deny',
                },
                'test2.example.com' => {
                    default => 'deny',
                }
            }
        }
    }
);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Auth query' );
ok( $res->[2]->[0] =~ m%"scrollTop":100%, 'scrollTop param found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%id="btn-back-to-top"%, 'scrollTop button found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<div id="appslist">%, 'appsList found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span trspan="noAppAllowed">%,
    'noAppAllowed message found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(5);
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
