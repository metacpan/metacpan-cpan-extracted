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
    if (
        my $res = LLNG::Manager::Test->new(
            {
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
                            over => {
                                dbiAuthChain => 'dbi:SQLite:dbname=t/userdb.db',
                                dbiAuthUser  => '',
                                dbiAuthPassword     => '',
                                dbiAuthTable        => 'users',
                                dbiAuthLoginCol     => 'user',
                                dbiAuthPasswordCol  => 'password',
                                dbiAuthPasswordHash => '',
                                dbiExportedVars     => {},
                            }
                        },
                        Dm => {
                            for  => 0,
                            type => 'Demo',
                        },
                    },

                    demoExportedVars => {},
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
