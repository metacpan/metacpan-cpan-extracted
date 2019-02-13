use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 0;
my $client;

eval { unlink 't/userdb.db' };

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/userdb.db");
    $dbh->do('CREATE TABLE users (user text,password text,name text)');
    $dbh->do("INSERT INTO users VALUES ('dvador','dvador','Test user 1')");
    $dbh->do("INSERT INTO users VALUES ('rtyler','rtyler','Test user 1')");

    $client = iniCmb('[Dm] or [DB]');
    expectCookie( try('dwho') );
    expectCookie( try('dvador') );

    $client = iniCmb('[Dm] and [DB]');
    expectCookie( try('rtyler') );
    expectReject( try('dwho') );

    $client = iniCmb('if($env->{HTTP_X} eq "dwho") then [Dm] else [DB]');
    expectCookie( try('dwho') );
    expectCookie( try('dvador') );

    $client = iniCmb(
'if($env->{HTTP_X} eq "rtyler") then [Dm] and [DB] else if($env->{HTTP_X} eq "dvador") then [DB] else [DB]'
    );
    expectCookie( try('rtyler') );
    expectCookie( try('dvador') );
    expectReject( try('dwho') );
}
count($maintests);
clean_sessions();
eval { unlink 't/userdb.db' };
done_testing( count() );

sub try {
    my $user = shift;
    my $s    = "user=$user&password=$user";
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
                        DB => {
                            for  => 0,
                            type => 'DBI',
                        },
                        Dm => {
                            for  => 0,
                            type => 'Demo',
                        },
                    },

                    dbiAuthChain        => 'dbi:SQLite:dbname=t/userdb.db',
                    dbiAuthUser         => '',
                    dbiAuthPassword     => '',
                    dbiAuthTable        => 'users',
                    dbiAuthLoginCol     => 'user',
                    dbiAuthPasswordCol  => 'password',
                    dbiAuthPasswordHash => '',
                    dbiExportedVars     => {},
                    demoExportedVars    => {},
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
