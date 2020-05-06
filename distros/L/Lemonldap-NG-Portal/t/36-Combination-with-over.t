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

    $client = iniCmb('[Dm] or [DB]');
    $client->logout( expectCookie( try('dwho') ) );
    $client->logout( expectCookie( try('dvador') ) );
}
count($maintests);
clean_sessions();
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
    count(1);
    if (
        my $client = LLNG::Manager::Test->new( {
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
                                dbiAuthChain    => "dbi:SQLite:dbname=$userdb",
                                dbiAuthUser     => '',
                                dbiAuthPassword => '',
                                dbiAuthTable    => 'users',
                                dbiAuthLoginCol => 'user',
                                dbiAuthPasswordCol  => 'password',
                                dbiAuthPasswordHash => '',
                                dbiExportedVars     => '{"user":"user"}',
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
        ok(
            $client->{p}->{loadedModules}->{'Lemonldap::NG::Portal::Auth::DBI'}
              ->{conf}->{dbiExportedVars}->{user} eq 'user',
            'JSON is parsed'
        );
        count(1);
        return $client;
    }
    else {
        fail "Unable to build object";
    }
}
