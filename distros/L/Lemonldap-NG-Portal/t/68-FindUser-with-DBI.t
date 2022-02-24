use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $maintests = 54;
my $userdb    = tempdb();

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $res;
    my $json;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do(
'CREATE TABLE users (uid text,password text,cn text,type text,guy text, room text)'
    );
    $dbh->do(
"INSERT INTO users VALUES ('dwho','dwho','Doctor who', 'character','good','0')"
    );
    $dbh->do(
"INSERT INTO users VALUES ('rtyler','rtyler','Rose Tyler','character','good','0')"
    );
    $dbh->do(
"INSERT INTO users VALUES ('davros','davros','Bad Guy','character','bad','0')"
    );
    $dbh->do(
"INSERT INTO users VALUES ('msmith','msmith','Mr Smith','character','good','0')"
    );
    $dbh->do(
"INSERT INTO users VALUES ('davrosjr','davrosjr','Davros Junior','character','bad','0')"
    );
    $dbh->do(
"INSERT INTO users VALUES ('dalek','dalek', 'The Daleks','mutant','bad','1')"
    );
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                    => 'error',
                authentication              => 'DBI',
                userDB                      => 'Same',
                dbiAuthChain                => "dbi:SQLite:dbname=$userdb",
                multiValuesSeparator        => ' # ',
                dbiAuthUser                 => '',
                dbiAuthPassword             => '',
                dbiAuthTable                => 'users',
                dbiAuthLoginCol             => 'uid',
                dbiAuthPasswordCol          => 'password',
                dbiAuthPasswordHash         => '',
                dbiDynamicHashEnabled       => 0,
                useSafeJail                 => 1,
                requireToken                => 0,
                findUser                    => 1,
                findUserControl             => '^[\w#%\s]+$',
                findUserWildcard            => '#',
                impersonationRule           => 1,
                findUserSearchingAttributes => {
                    'uid##1'    => 'Login',
                    '1_guy##1'  => 'Kind',
                    '2_cn##1'   => 'Name',
                    '3_room##1' => 'Room'
                },
                findUserExcludingAttributes =>
                  { type => 'mutant', uid => 'rtyler # davrosjr # ' },
            }
        }
    );
    use Lemonldap::NG::Portal::Main::Constants 'PE_USERNOTFOUND';

    ## Simple access
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'uid', 'guy', 'cn', 'room' );
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
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'uid', 'guy', 'cn', 'room' );
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
    ok( $res->[2]->[0] =~ m%value="dwho"%, 'value="dwho"' )
      or explain( $res->[2]->[0], 'value="dwho"' );
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
m%<input id="findUser_uid" name="uid" type="text" autocomplete="off" class="form-control" aria-label="Login" placeholder="Login" />%,
        'id="findUser_uid"'
    ) or explain( $res->[2]->[0], 'id="findUser_uid"' );
    ok(
        $res->[2]->[0] =~
m%<input id="findUser_cn" name="cn" type="text" autocomplete="off" class="form-control" aria-label="Name" placeholder="Name" />%,
        'id="findUser_cn"'
    ) or explain( $res->[2]->[0], 'id="findUser_cn"' );
    ok(
        $res->[2]->[0] =~
m%<input id="findUser_room" name="room" type="text" autocomplete="off" class="form-control" aria-label="Room" placeholder="Room" />%,
        'id="findUser_room"'
    ) or explain( $res->[2]->[0], 'id="findUser_room"' );

    my @c = ( $res->[2]->[0] =~ m%<input id="findUser_(\w+)"%gs );
    ok( @c == 4, ' -> Four entries found' )
      or explain( $res->[2]->[0], '4, found ' . scalar @c );
    ok( $c[0] eq 'guy',  '  1st -> guy' );
    ok( $c[1] eq 'cn',   '  2nd -> cn' );
    ok( $c[2] eq 'room', '  3rd -> room' );
    ok( $c[3] eq 'uid',  '  4th -> uid' );
    count(5);

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
        'Post FindUser request no result'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{user} eq '', ' No user' )
      or explain( $json, "user => ''" );

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

    $request = 'room=0';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'application/json',
            length => length($request)
        ),
        'Post FindUser request 0 with multi results'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 1, ' Good result' )
      or explain( $json, 'result => 1' );
    ok( $json->{user} =~ /^(dwho|msmith|davros)$/, " Good user ($1)" )
      or explain( $json, "user => ?" );

    $request = 'uid=d%';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'application/json',
            length => length($request)
        ),
        'Post FindUser request with bad wildcard'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 0, ' Good result' )
      or explain( $json, 'result => 0' );
    ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
      or explain( $json, 'error => 4' );

    $request = 'uid=d#';
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
}
count($maintests);
done_testing( count() );
