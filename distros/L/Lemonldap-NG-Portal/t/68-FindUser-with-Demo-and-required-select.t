use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $maintests = 25;

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
            findUserControl             => '^[\w*\s]+$',
            findUserWildcard            => '*',
            findUserSearchingAttributes => {
                uid           => 'Name',
                guy           => 'Kind',
                'type#Type#1' => 'mutant; mutant; character',
                'cn#Name#0' => 'Bad Guy; Not a good person; The Daleks; daleks'
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

my $request = '';
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
m%<input id="spoofIdfield" name="spoofId" type="text" class="form-control" value="" autocomplete="off"%,
    'value=""'
) or explain( $res->[2]->[0], 'value=""' );

$request = 'uid=davros&cn=Bad Guy';
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
m%<input id="findUser_guy" name="guy" type="text" autocomplete="off" class="form-control" placeholder="Kind" />%,
    'id="findUser_guy"'
) or explain( $res->[2]->[0], 'id="findUser_guy"' );
ok(
    $res->[2]->[0] =~
m%<input id="findUser_uid" name="uid" type="text" autocomplete="off" class="form-control" placeholder="Name" />%,
    'id="findUser_uid"'
) or explain( $res->[2]->[0], 'id="findUser_uid"' );
ok(
    $res->[2]->[0] =~
      m%<select class="form-control" id="findUser_cn" name="cn">%,
    'id="findUser_cn"'
) or explain( $res->[2]->[0], 'id="findUser_cn"' );
ok( $res->[2]->[0] !~ m%id="findUser_type"%, 'id="findUser_type" not found' )
  or explain( $res->[2]->[0], 'id="findUser_cn" not found' );
ok( $res->[2]->[0] =~ m%<label for="cn">Name</label>%, 'label for="cn"' )
  or explain( $res->[2]->[0], 'label for="cn"' );
ok( $res->[2]->[0] !~ m%<option value=""></option>%, 'Empty option not found' )
  or explain( $res->[2]->[0], 'Empty option not found' );
ok( $res->[2]->[0] =~ m%<option value="The Daleks">daleks</option>%,
    'The Daleks' )
  or explain( $res->[2]->[0], 'The Daleks option' );
ok( $res->[2]->[0] =~ m%<option value="Bad Guy">Not a good person</option>%,
    'Bad Guy option' )
  or explain( $res->[2]->[0], 'Bad Guy' );

$request = 'cn=Bad Guy';
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
ok( $json->{user} eq 'davros', ' Good user' )
  or explain( $json, 'user => davros' );

$request = 'cn=The Daleks';
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
ok( $json->{result} == 0, ' Good result' )
  or explain( $json, 'result => 0' );
ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
  or explain( $json, 'error => 4' );

$request = 'uid=davros';
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
ok( $json->{result} == 1, ' Good result' )
  or explain( $json, 'result => 1' );
ok( $json->{user} eq '', ' No user' )
  or explain( $json, 'user => ?' );

count($maintests);
done_testing( count() );
