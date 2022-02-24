use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 7;

my $userdb = tempdb();

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do('CREATE TABLE users (user text,password text,cn text)');
    $dbh->do("INSERT INTO users VALUES ('french','french','Frédéric Accents')");
    $dbh->do("INSERT INTO users VALUES ('russian','russian','Русский')");
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => 'error',
                useSafeJail              => 1,
                authentication           => 'DBI',
                userDB                   => 'Same',
                dbiAuthChain             => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser              => '',
                dbiAuthPassword          => '',
                dbiAuthTable             => 'users',
                dbiAuthLoginCol          => 'user',
                dbiAuthPasswordCol       => 'password',
                dbiAuthPasswordHash      => '',
                passwordDB               => 'DBI',
                portalRequireOldPassword => 1,
                restSessionServer        => 1,
                dbiExportedVars          => {
                    cn => 'cn',
                },
            }
        }
    );

    # Try yo authenticate
    # -------------------

    # 1- Characters available in ISO and UTF-8
    ok(
        $res = $client->_post(
            '/', IO::String->new('user=french&password=french'),
            length => 27
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    ok( $res = $client->_get("/sessions/global/$id"), 'Get UTF-8' );
    expectOK($res);
    $res = expectJSON($res);
    ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
      or explain( $res, 'cn => Frédéric Accents' );

    # 2- Characters UTF-8 only
    ok(
        $res = $client->_post(
            '/', IO::String->new('user=russian&password=russian'),
            length => 29
        ),
        'Auth query'
    );
    expectOK($res);
    $id = expectCookie($res);

    ok( $res = $client->_get("/sessions/global/$id"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok( $res->{cn} eq 'Русский', 'UTF-8 values' )
      or explain( $res, 'cn => Русский' );

    clean_sessions();
}
count($maintests);
done_testing( count() );
