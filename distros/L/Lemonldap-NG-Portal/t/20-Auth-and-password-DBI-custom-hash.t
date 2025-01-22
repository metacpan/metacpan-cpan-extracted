use warnings;
use MIME::Base64;

use Test::More;
use strict;
use IO::String;
use Digest::SHA;

require 't/test-lib.pm';

# Hook SHA function into all new DBI connections
sub hook {
    my $old_connect = \&DBI::connect;
    no warnings 'redefine';
    *DBI::connect = sub {
        my $connection = $old_connect->(@_) or return;

        $connection->sqlite_create_function(
            'sha512', 1,
            sub {
                my $p = shift;
                return
                  unpack( 'H*',
                    Digest::SHA->new(512)->add( pack( 'H*', $p ) )->digest );
            }
        );
        return $connection;
    }
}

my $res;

my $userdb = tempdb();

sub fails {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $client, $user, $password, $desc ) = @_;
    ok(
        my $res = $client->_post(
            '/',
            {
                user => $user,
                ( defined($password) ? ( password => $password ) : () )
            },
        ),
        $desc
    );
    expectReject( $res, 401, 5 );
}

sub works {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $client, $user, $password, $desc ) = @_;
    ok(
        my $res = $client->_post(
            '/',
            { user => $user, ( $password ? ( password => $password ) : () ) },
        ),
        $desc
    );
    expectOK($res);
    return expectCookie($res);
}

SKIP: {
    eval
'require DBD::SQLite; use Digest::SHA; use Lemonldap::NG::Portal::Lib::DBI';
    if ($@) {
        skip "DBI/DBD::SQLite not found: $@";
    }
    hook();

    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");

    $dbh->do('CREATE TABLE users (user text,password text,name text)');

    # custom hashed password (bar)
    $dbh->do( "INSERT INTO users VALUES (?,?,?)",
        undef, "foo", '@@@BAR', 'Doctor Who' );

    # Invalid password (null)
    $dbh->do( "INSERT INTO users VALUES (?,?,?)",
        undef, "invalid1", undef, 'Doctor Who' );

    # Invalid password (empty)
    $dbh->do( "INSERT INTO users VALUES (?,?,?)",
        undef, "invalid2", "", 'Doctor Who' );

    # Invalid password (unknown hash)
    $dbh->do( "INSERT INTO users VALUES (?,?,?)",
        undef, "invalid3", 'unknownhash', 'Doctor Who' );

    # dynamic hashed password (secret3)
    $dbh->do(
        "INSERT INTO users VALUES (?,?,?)",
        undef,
        'rtyler',
'{ssha512}wr0zU/I6f7U4bVoeOlJnNFbhF0a9np59LUeNnhokohVI/wiNzt8Y4JujfOfNQiGuiVgY+xrYggfmgpke6KdjxKS7W0GR1ZCe',
        'Rose Tyler'
    );

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                         => 'error',
                useSafeJail                      => 1,
                authentication                   => 'DBI',
                userDB                           => 'Same',
                dbiAuthChain                     => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser                      => '',
                dbiAuthPassword                  => '',
                dbiAuthTable                     => 'users',
                dbiAuthLoginCol                  => 'user',
                dbiAuthPasswordCol               => 'password',
                dbiAuthPasswordHash              => '',
                dbiDynamicHashEnabled            => 1,
                dbiDynamicHashValidSchemes       => '',
                dbiDynamicHashValidSaltedSchemes => 'ssha512',
                dbiDynamicHashNewPasswordScheme  => 'mycustom',
                passwordDB                       => 'DBI',
                portalRequireOldPassword         => 1,
                customPlugins                    => "t::DbiCustomHash",
            }
        }
    );

    # Standard scheme bad password
    fails( $client, "rtyler", "rtyler", 'Authentication with wrong password' );

    # Standard scheme good password
    works( $client, "rtyler", "secret3", 'Authentication with good password' );

    # Custom scheme bad password
    fails( $client, "foo", "bor", 'Authentication with wrong password' );

    my $id =
      works( $client, "foo", "bar", 'Authentication with correct password' );

    # Try to modify password
    ok(
        $res = $client->_post(
            '/',
            {
                oldpassword     => 'bar',
                newpassword     => 'qwerty1234',
                confirmpassword => 'qwerty1234',
            },
            cookie => "lemonldap=$id",
            accept => 'application/json',
        ),
        'Change password'
    );
    expectOK($res);
    $client->logout($id);

    # Check new password value
    # custom hashed password (bar)
    is(
        $dbh->selectrow_array(
            "SELECT password FROM users WHERE user=?",
            undef, "foo"
        ),
        '@@@QWERTY1234',
        'Expected hash'
    );

    # Try to authenticate against new salted password
    works( $client, "foo", "qwerty1234", 'Authentication with new password' );

    fails( $client, "invalid1", "badpassword" );
    fails( $client, "invalid2", "badpassword" );
    fails( $client, "invalid3", "badpassword" );

    clean_sessions();
}
done_testing();
