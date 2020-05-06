use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 0;
my $client;

my $userdb = tempdb();

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do("INSERT INTO users VALUES ('dvador','dvador','Test user 1')");
    $dbh->do("INSERT INTO users VALUES ('rtyler','rtyler','Test user 1')");

    $client = iniCmb('[Dm] or [Ch]');
    $client->logout( expectCookie( try('dwho') ) );
    $client->logout( expectCookie( try( 'dvador', 'sql' ) ) );

    $client = iniCmb('[Dm] and [Ch]');
    $client->logout( expectCookie( try( 'rtyler', 'sql' ) ) );
    $client->logout( expectCookie( try( 'dwho',   'demo' ) ) );
    expectReject( try( 'dwho', 'sql' ) );

    $client = iniCmb('if($env->{HTTP_X} eq "dwho") then [Dm] else [Ch]');
    $client->logout( expectCookie( try('dwho') ) );
    $client->logout( expectCookie( try( 'dvador', 'sql' ) ) );

    $client = iniCmb(
'if($env->{HTTP_X} eq "rtyler") then [Dm] and [Ch] else if($env->{HTTP_X} eq "dvador") then [Ch] else [Ch]'
    );
    $client->logout( expectCookie( try( 'rtyler', 'sql' ) ) );
    $client->logout( expectCookie( try( 'dvador', 'sql' ) ) );
    $client->logout( expectCookie( try( 'dwho',   'demo' ) ) );
    expectReject( try( 'dwho', 'sql' ) );
}
count($maintests);
clean_sessions();
done_testing( count() );

sub try {
    my $user = shift;
    my $s    = "user=$user&password=$user";
    $s .= "&test=$_[0]" if (@_);
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

sub iniCmb {
    my $expr = shift;
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    if (
        my $res = LLNG::Manager::Test->new( {
                ini => {
                    logLevel       => 'error',
                    useSafeJail    => 1,
                    authentication => 'Combination',
                    userDB         => 'Same',

                    combination => $expr,
                    combModules => {
                        Dm => {
                            for  => 0,
                            type => 'Demo',
                        },
                        Ch => {
                            for  => 0,
                            type => 'Choice',
                        },
                    },

                    dbiAuthChain        => "dbi:SQLite:dbname=$userdb",
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
                        sql   => 'DBI;DBI;DBI',
                        slave => 'Slave;DBI;DBI',
                        demo  => 'Demo;Demo;Demo',
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
        pass(qq'Expression loaded: "$expr"');
        count(1);
        return $res;
    }
}
