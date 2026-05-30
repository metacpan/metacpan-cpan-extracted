use warnings;
use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 0;
my $client;

my $userdb_scifi = "$main::tmpDir/scifi.sql";
my $userdb_hero  = "$main::tmpDir/hero.sql";

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb_scifi");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do("INSERT INTO users VALUES ('dvador','dvador','Test user 1')");

    $dbh = DBI->connect("dbi:SQLite:dbname=$userdb_hero");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do("INSERT INTO users VALUES ('superman','superman','Test user 1')");

    $client = iniCmb('[Dm] or [Ch]');

    $client->logout( expectCookie( try( 'superman', 'dbi' ) ) );
    expectPortalError( try( 'dvador', 'dbi' ), 5 );

    $client->logout( expectCookie( try( 'dwho',   'cmb' ) ) );
    $client->logout( expectCookie( try( 'dvador', 'cmb' ) ) );
    expectPortalError( try( 'superman', 'cmb' ), 5 );

}

count($maintests);
clean_sessions();
done_testing();

sub try {
    ok( my $res = $client->_get( "/", accept => "text/html" ),
        "Get login form" );
    expectXpath(
        $res,
        '//div[@id="id_cmb"]//input[@id="userfield"]',
        "Found login form for cmb choice"
    );
    my $user = shift;
    my $s    = "user=$user&password=$user";
    $s .= "&test=$_[0]" if (@_);
    ok(
        $res = $client->_post(
            '/', IO::String->new($s),
            accept => "text/html",
            length => length($s),
            custom => { HTTP_X => $user }
        ),
        " Try to connect with login $user"
    );
    count(1);
    return $res;
}

sub iniCmb {
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    if (
        my $res = LLNG::Manager::Test->new( {
                ini => {
                    logLevel       => 'error',
                    useSafeJail    => 1,
                    authentication => 'Choice',
                    userDB         => 'Same',

                    combination => '[Dm] or [Dbi]',
                    combModules => {
                        Dm => {
                            for  => 0,
                            type => 'Demo',
                        },
                        Dbi => {
                            for  => 0,
                            type => 'DBI',
                        },
                    },

                    dbiAuthChain        => "dbi:SQLite:dbname=$userdb_scifi",
                    dbiAuthUser         => '',
                    dbiAuthPassword     => '',
                    dbiAuthTable        => 'users',
                    dbiAuthLoginCol     => 'user',
                    dbiAuthPasswordCol  => 'password',
                    dbiAuthPasswordHash => '',
                    dbiExportedVars     => {},
                    demoExportedVars    => {},

                    authChoiceParam   => 'test',
                    authChoiceModules => {
                        cmb => 'Combination;Combination;Combination',
                        dbi =>
                          'DBI;DBI;Null;;;{"dbiAuthChain": "dbi:SQLite:dbname='
                          . $userdb_hero . '"}',
                    },
                    slaveUserHeader   => 'My-Test',
                    slaveExportedVars => {
                        name => 'Name',
                    }
                }
            }
        )
      )
    {
        count(1);
        return $res;
    }
}
