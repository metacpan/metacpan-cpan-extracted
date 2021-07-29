use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my ( $res, $user, $pwd, $client );

SKIP: {
    eval
'require Email::Sender::Simple;use GD::SecurityImage;use Image::Magick; require DBI; require DBD::SQLite;';
    if ($@) {
        skip 'Missing dependencies', 0;
    }

    $client = iniCmb();

    # As dvador
    # Check first password
    expectCookie( try( 'dvador', 'dvador' ) );

    # Get mail reset code
    my $query = getMailQuery('dvador@wars.star');

    # Set new password
    expectPortalError( updatePassword( $query, "skywalker" ),
        46, "Password update successful" );

    # Check that new password works
    expectCookie( try( 'dvador', 'skywalker' ) );

    # As jkirk
    # Check first password
    expectCookie( try( 'jkirk', 'jkirk' ) );

    # Get mail reset code
    $query = getMailQuery('jkirk@trek.star');

    # Set new password
    expectPortalError( updatePassword( $query, "kobayashi" ),
        46, "Password update successful" );

    # Check that new password works
    expectCookie( try( 'jkirk', 'kobayashi' ) );

}
count(0);

clean_sessions();

done_testing( count() );

sub updatePassword {
    my $query       = shift;
    my $newpassword = shift;
    my $res;

    ok(
        $res = $client->_get(
            '/resetpwd',
            query  => $query,
            accept => 'text/html'
        ),
        'Post mail token received by mail'
    );
    count(1);
    ( my $host, my $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password' );
    count(1);

    $query .= "&newpassword=$newpassword&confirmpassword=$newpassword";

    # Post new password
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post new password'
    );
    count(1);
    return $res;
}

sub getMailQuery {
    my $mail  = shift;
    my $query = buildForm( { mail => $mail } );
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => 'llnglanguage=fr',
        ),
        'Post mail'
    );
    count(1);
    ok( mail() =~ m#a href="http://auth.example.com/resetpwd\?(.*?)"#,
        'Found link in mail' );
    count(1);
    return $1;
}

sub iniCmb {
    my $userdb = tempdb();
    my $dbh    = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do(
        'CREATE TABLE wars (user text,password text,email text, name text)');
    $dbh->do(
"INSERT INTO wars VALUES ('dvador','dvador','dvador\@wars.star', 'Anakin Skywalker')"
    );
    $dbh->do(
        'CREATE TABLE trek (user text,password text,email text, name text)');
    $dbh->do(
"INSERT INTO trek VALUES ('jkirk','jkirk','jkirk\@trek.star', 'James Tiberius Kirk')"
    );

    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    if (
        my $res = LLNG::Manager::Test->new( {
                ini => {
                    logLevel                   => 'error',
                    useSafeJail                => 1,
                    authentication             => 'Combination',
                    userDB                     => 'Same',
                    passwordDB                 => 'Combination',
                    restSessionServer          => 1,
                    portalDisplayResetPassword => 1,
                    requireToken               => 0,

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

                    dbiAuthChain         => "dbi:SQLite:dbname=$userdb",
                    dbiAuthUser          => '',
                    dbiAuthPassword      => '',
                    dbiAuthLoginCol      => 'user',
                    dbiAuthPasswordCol   => 'password',
                    dbiMailCol           => 'email',
                    dbiAuthPasswordHash  => '',
                    dbiExportedVars      => { cn => 'name', mail => 'email' },
                    captcha_mail_enabled => 0,
                }
            }
        )
      )
    {
        return $res;
    }
}

sub try {
    my $user     = shift;
    my $password = shift || $user;
    my $s        = "user=$user&password=$password";
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
