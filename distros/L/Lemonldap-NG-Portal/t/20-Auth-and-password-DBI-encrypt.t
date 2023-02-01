use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 3;

my $userdb = tempdb();

use DBI;
use Digest::SHA;

# Hook hash function into all new DBI connections
{
    my $old_connect = \&DBI::connect;
    *DBI::connect = sub {
        my $connection = $old_connect->(@_) or return;

        $connection->sqlite_create_function(
            'sha256', 1,
            sub {
                my $p = shift;
                return
                  unpack( 'H*',
                    Digest::SHA->new(256)->add( pack( 'H*', $p ) )->digest );
            }
        );
        $connection->sqlite_create_function(
            'sha512', 1,
            sub {
                my $p = shift;
                return
                  unpack( 'H*',
                    Digest::SHA->new(512)->add( pack( 'H*', $p ) )->digest );
            }
        );

        $connection->sqlite_create_function(
            'encrypt',
            -1,
            sub {
                my $p    = shift;
                my $hash = shift || '$1$12345';
                my $res  = crypt( $p, $hash );
                return $res;
            }
        );

        return $connection;
    }
}

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do(
"INSERT INTO users VALUES ('dwho','\$6\$Y8KTt/guov37XOCO\$DdI67zOAFX4RfqJthruv9g2IJ7xzo5AuMaBcETfV5cgncvSoDycdvmEwbsQykOCJ45mzH65Q1fM/4UDJ/6Y/J1','Doctor who')"
    );
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
                dbiAuthPasswordHash      => 'encrypt',
                dbiDynamicHashEnabled    => 0,
                passwordDB               => 'DBI',
                portalRequireOldPassword => 1,
            }
        }
    );

    # Try to authenticate
    # -------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    ok(
        $res = $client->_post(
            '/',
            IO::String->new(
                'oldpassword=dwho&newpassword=test&confirmpassword=test'),
            cookie => "lemonldap=$id",
            accept => 'application/json',
            length => 54
        ),
        'Change password'
    );
    expectOK($res);
    $client->logout($id);
    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=test'),
            cookie => "lemonldap=$id",
            length => 23
        ),
        'Auth query with new password'
    );
    expectOK($res);
    $id = expectCookie($res);

    $client->logout($id);
    clean_sessions();
}
count($maintests);
done_testing( count() );
