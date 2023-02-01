use Test::More;
use strict;
use IO::String;
use MIME::Base64;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new(
    { ini => { logLevel => 'error', useSafeJail => 1 } } );

ok(
    $res = $client->_get(
        '/',
        query => 'url='
          . encode_base64( 'http://bad.com#test.example.llng', '' )
    ),
    'Try http://bad.com#test.example.llng'
);
expectReject($res);
ok( $res->[2]->[0] =~ /109/, 'Rejected with PE_UNPROTECTEDURL' )
  or print STDERR Dumper( $res->[2]->[0] );

count(2);

clean_sessions();

done_testing( count() );
