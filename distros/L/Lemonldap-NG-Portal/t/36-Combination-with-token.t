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

    $client = iniCmb('[Dm] and [DB]');
    $client->logout( expectCookie( try('rtyler') ) );
    expectReject( try('dwho'), 401, 5 );

    $client = iniCmb('if($env->{HTTP_X} eq "dwho") then [Dm] else [DB]');
    $client->logout( expectCookie( try('dwho') ) );
    $client->logout( expectCookie( try('dvador') ) );

    $client = iniCmb(
'if($env->{HTTP_X} eq "rtyler") then [Dm] and [DB] else if($env->{HTTP_X} eq "dvador") then [DB] else [DB]'
    );
    $client->logout( expectCookie( try('rtyler') ) );
    $client->logout( expectCookie( try('dvador') ) );
    expectReject( try('dwho'), 401, 5 );
}
count($maintests);
clean_sessions();
done_testing( count() );

sub try {
    my $user = shift;
    my $res;

    # Get token
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Unauth request' );
    count(1);
    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    $query .= "&user=$user&password=$user";
    ok(
        $res = $client->_post(
            '/', IO::String->new($query),
            length => length($query),
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
                    requireToken   => '$env->{ipAddr} !~ /127\.0\.[1-3]\.1/',
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

                    dbiAuthChain        => "dbi:SQLite:dbname=$userdb",
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
