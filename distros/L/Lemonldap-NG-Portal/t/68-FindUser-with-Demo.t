use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $maintests = 53;

my $res;
my $json;
my $request;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            authentication              => 'Demo',
            userDB                      => 'Same',
            useSafeJail                 => 1,
            requireToken                => 0,
            findUser                    => 1,
            impersonationRule           => 1,
            findUserControl             => '^[\w*\s]+$',
            findUserWildcard            => '*',
            findUserSearchingAttributes => {
                'uid#fdgd#1' => undef,
                '1_guy##1'   => 'Kind',
                'cn#Name#1'  => 'Bad Guy; Not a good person; 2_BB; Bad Boy'
            },
            findUserExcludingAttributes =>
              { type => 'mutant', uid => 'rtyler' },
        }
    }
);
use Lemonldap::NG::Portal::Main::Constants 'PE_USERNOTFOUND';

## Simple access
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$request = '';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'text/html',
        length => length($request)
    ),
    'Post empty FindUser request'
);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );
( $host, $url, $query ) = expectForm( $res, '#', undef, 'uid', 'guy' );
ok(
    $res->[2]->[0] =~
m%<input name="spoofId" type="text" class="form-control" value="" autocomplete="off"%,
    'value=""'
) or explain( $res->[2]->[0], 'value=""' );

$request = 'uid=dwho';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'text/html',
        length => length($request)
    ),
    'Post FindUser request'
);
ok( $res->[2]->[0] =~ m%autocomplete="off"%, 'autocomplete="off"' )
  or explain( $res->[2]->[0], 'autocomplete="off"' );
ok(
    $res->[2]->[0] =~
      m%<span trspan="searchAccount">Search for an account</span>%,
    'Search an account'
) or explain( $res->[2]->[0], 'Search for an account' );
ok(
    $res->[2]->[0] =~
m%<input id="findUser_guy" name="guy" type="text" autocomplete="off" class="form-control" aria-label="Kind" placeholder="Kind" />%,
    'id="findUser_guy"'
) or explain( $res->[2]->[0], 'id="findUser_guy"' );
ok(
    $res->[2]->[0] =~
m%<input id="findUser_uid" name="uid" type="text" autocomplete="off" class="form-control" aria-label="uid" placeholder="uid" />%,
    'id="findUser_uid"'
) or explain( $res->[2]->[0], 'id="findUser_uid"' );
ok(
    $res->[2]->[0] =~
      m%<select class="custom-select" id="findUser_cn" name="cn">%,
    'id="findUser_cn"'
) or explain( $res->[2]->[0], 'id="findUser_cn"' );
ok( $res->[2]->[0] =~ m%<option selected>Name...</option>%, 'Name...' )
  or explain( $res->[2]->[0], 'Name...' );
ok( $res->[2]->[0] =~ m%<option value=""></option>%, 'Empty option' )
  or explain( $res->[2]->[0], 'Empty option' );
ok( $res->[2]->[0] =~ m%<option value="BB">Bad Boy</option>%, 'BB option' )
  or explain( $res->[2]->[0], 'BB option' );
ok( $res->[2]->[0] =~ m%<option value="Bad Guy">Not a good person</option>%,
    'Bad Guy option' )
  or explain( $res->[2]->[0], 'Bad Guy' );

$request = 'uid=dwho';
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
ok( $json->{user} eq 'dwho', ' Good user' )
  or explain( $json, 'user => dwho' );

$request = 'uid=ohwd';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with bad user'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 0, ' Good result' )
  or explain( $json, 'result => 0' );
ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
  or explain( $json, 'error => 4' );

$request = 'cn=Bad Guy';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request one result'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} eq 'davros', ' Good user' )
  or explain( $json, "user => 'davros'" );

$request = 'cn=Good Guy';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with a not allowed select value'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 1, ' Good result' )
  or explain( $json, 'result => 1' );
ok( $json->{user} eq '', ' No user' )
  or explain( $json, 'user => ?' );

$request = 'guy=good';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request multi results'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} =~ /^(dwho|msmith)$/, " Good user ($1)" )
  or explain( $json, "user => ?" );

$request = 'arg=good';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with bad arg'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 1, ' Good result' )
  or explain( $json, 'result => 1' );
ok( $json->{user} eq '', ' No user' )
  or explain( $json, 'user => ?' );

$request = 'guy=good&uid=msmith';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with two args'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} eq 'msmith', ' Good user' )
  or explain( $json, 'user => msmith' );

$request = 'guy=bad&uid=msmith';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with wrong args'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 0, ' Good result' )
  or explain( $json, 'result => 0' );
ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
  or explain( $json, 'error => 4' );

$request = 'uid=dalek';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with excluding result'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 0, ' Good result' )
  or explain( $json, 'result => 0' );
ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
  or explain( $json, 'error => 4' );

$request = 'uid=rtyler';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with excluding result'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 0, ' Good result' )
  or explain( $json, 'result => 0' );
ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
  or explain( $json, 'error => 4' );

$request = 'uid=d*';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($request),
        accept => 'application/json',
        length => length($request)
    ),
    'Post FindUser request with wildcard'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 1, ' Good result' )
  or explain( $json, 'result => 1' );
ok( $json->{user} =~ /^(dwho|davros)$/, " Good user ($1)" )
  or explain( $json, "user => ?" );

count($maintests);
done_testing( count() );
