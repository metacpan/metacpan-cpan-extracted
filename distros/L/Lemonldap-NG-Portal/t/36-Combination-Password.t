use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 0;
my $client;

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }

    subtest "Combination as main backend" => sub {
        myTest(0);
    };
    subtest "Combination inside Choice" => sub {
        myTest(1);
    };

}
count($maintests);
clean_sessions();
done_testing();

sub myTest {
    my $use_choice = shift;
    $client = iniCmb($use_choice);

    # as dwho: login, change password, logout, login again
    my $id = expectCookie( try('jkirk') );
    expectPwChanged( pwchange( $id, "jkirk", "kobayashi" ) );
    expectReject( try('jkirk') );
    expectCookie( try( 'jkirk', 'kobayashi' ) );

    # as dvador: login, change password, logout, login again
    $id = expectCookie( try('dvador') );
    expectPwChanged( pwchange( $id, "dvador", "darkside" ) );
    expectReject( try('dvador') );
    expectCookie( try( 'dvador', 'darkside' ) );
}

sub expectPwChanged {
    my $res = shift;
    my $j   = expectJSON($res);
    is( $j->{error}, 35, "PE_PASSWORD_OK" );
    count(1);
}

sub try {
    my $user     = shift;
    my $password = shift || $user;
    my $s        = "user=$user&password=$password&test=cmb";
    my $res;
    ok(
        $res = $client->_post(
            '/', IO::String->new($s),
            length => length($s),
            custom => { HTTP_X => $user }
        ),
        " Try to connect with login $user"
    );
    count(1);
    return $res;
}

sub pwchange {
    my $id  = shift;
    my $old = shift;
    my $new = shift;
    my $s   = "oldpassword=$old&newpassword=$new&confirmpassword=$new";
    my $res;
    ok(
        $res = $client->_post(
            '/', IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$id",
        ),
        " Try to change password"
    );
    count(1);
    return $res;
}

sub iniCmb {
    my $use_choice = shift;
    my $userdb     = tempdb("userdb$use_choice.db");
    unlink($userdb);

    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do('CREATE TABLE wars (user text,password text,name text)');
    $dbh->do("INSERT INTO wars VALUES ('dvador','dvador','Anakin Skywalker')");
    $dbh->do('CREATE TABLE trek (user text,password text,name text)');
    $dbh->do("INSERT INTO trek VALUES ('jkirk','jkirk','James Tiberius Kirk')");

    my $auth_backend = $use_choice ? "Choice" : "Combination";

    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    if (
        my $res = LLNG::Manager::Test->new( {
                ini => {
                    logLevel          => 'error',
                    useSafeJail       => 1,
                    authentication    => $auth_backend,
                    passwordDB        => $auth_backend,
                    userDB            => 'Same',
                    restSessionServer => 1,

                    authChoiceParam   => 'test',
                    authChoiceModules => {
                        cmb => 'Combination;Combination;Combination',
                    },

                    combination => '[Wars] or [Trek]',
                    combModules => {
                        Wars => {
                            for  => 0,
                            type => 'DBI',
                            over => {
                                dbiAuthTable => 'wars',
                            }
                        },
                        Trek => {
                            for  => 0,
                            type => 'DBI',
                            over => {
                                dbiAuthTable => 'trek',
                            }
                        },
                    },

                    dbiAuthChain        => "dbi:SQLite:dbname=$userdb",
                    dbiAuthUser         => '',
                    dbiAuthPassword     => '',
                    dbiAuthLoginCol     => 'user',
                    dbiAuthPasswordCol  => 'password',
                    dbiAuthPasswordHash => '',
                    dbiExportedVars     => { dbi  => 'user' },
                    demoExportedVars    => { demo => 'uid' },
                }
            }
        )
      )
    {
        return $res;
    }
}
