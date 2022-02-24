use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $maintests = 3;
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
    expectCookie( try('dvador') );

    $client = iniCmb('[Dm] and [DB]');
    $client->logout( expectCookie( try('rtyler') ) );
    expectReject( try('dwho') );

    $client = iniCmb('if($env->{HTTP_X} eq "dwho") then [Dm] else [DB]');
    $client->logout( expectCookie( try('dwho') ) );
    $client->logout( expectCookie( try('dvador') ) );

    $client = iniCmb(
'if($env->{HTTP_X} eq "rtyler") then [Dm] and [DB] else if($env->{HTTP_X} eq "dvador") then [DB] else [DB]'
    );
    my $id = expectCookie( try('rtyler') );
    my $res;
    ok( $res = $client->_get("/sessions/global/$id"), 'Get session content' );
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok(
        ( $res->{demo} eq 'rtyler' and $res->{dbi} eq 'rtyler' ),
        ' Demo and DBI exported variables exist in session'
    );
    expectCookie( try('dvador') );
    expectReject( try('dwho') );
    $client = iniCmb(
        'if($env->{REMOTE_ADDR} =~ /^(127\.)/) then [Dm] or [DB] else [DB]');
    expectCookie( try('rtyler') );
    expectCookie( try('dwho') );
    $client = iniCmb(
'if($env->{REMOTE_ADDR} =~ /^(128\.)/) then [Dm,Dm] or [DB,DB] else [DB,DB]'
    );
    expectCookie( try('rtyler') );
    expectReject( try('dwho') );
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
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    if (
        my $res = LLNG::Manager::Test->new( {
                ini => {
                    logLevel          => 'error',
                    useSafeJail       => 1,
                    authentication    => 'Combination',
                    userDB            => 'Same',
                    restSessionServer => 1,

                    combination => $expr,
                    combModules => {
                        DB => {
                            for  => 0,
                            type => 'Custom',
                            over => {
                                customAuth   => "::Auth::DBI",
                                customUserDB => "::UserDB::DBI",
                            },
                        },
                        Dm => {
                            for  => 0,
                            type => 'Custom',
                            over => {
                                customAuth   => "::Auth::Demo",
                                customUserDB => "::UserDB::Demo",
                            },
                        },
                    },

                    dbiAuthChain        => "dbi:SQLite:dbname=$userdb",
                    dbiAuthUser         => '',
                    dbiAuthPassword     => '',
                    dbiAuthTable        => 'users',
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
        pass(qq'Expression loaded: "$expr"');
        count(1);
        return $res;
    }
}
