use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $maintests = 6;

my $res;
my $json;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            authentication              => 'Demo',
            userDB                      => 'Same',
            useSafeJail                 => 1,
            requireToken                => 0,
            findUser                    => 1,
            impersonationRule           => 1,
            findUserExcludingAttributes =>
              { type => 'mutant', uid => 'rtyler' },
        }
    }
);

## Simple access
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );
ok(
    $res->[2]->[0] !~
      m%<span trspan="searchAccount">Search for an account</span>%,
    'Search an account not found'
) or explain( $res->[2]->[0], 'Found search for an account' );
my $request = 'uid=dwho';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} eq '', ' No user' )
  or explain( $json, 'user => \'\'' );
ok( $json->{result} == 1, ' result => 1' )
  or explain( $json, 'result => 1' );

count($maintests);
done_testing( count() );
