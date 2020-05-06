use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my ( $res, $user, $pwd );
my $maintests = 17;
my $mailSend  = 0;

my $mail2  = 0;
my $userdb = tempdb();

SKIP: {
    eval
      'require Email::Sender::Simple;use GD::SecurityImage;use Image::Magick;';
    if ($@) {
        skip 'Missing dependencies', $maintests;
    }
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do(
        'CREATE TABLE users (user text,password text,name text, mail text)');
    $dbh->do(
        "INSERT INTO users VALUES ('yadd','yadd','Yadd','yadd\@badwolf.org')");

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel              => 'error',
                useSafeJail           => 1,
                portalDisplayRegister => 1,
                authentication        => 'Choice',
                authChoiceParam       => 'test',
                authChoiceModules     => {
                    demo => 'Demo;Demo;Demo',
                    sql  => 'DBI;DBI;DBI',
                },
                userDB                     => 'Same',
                passwordDB                 => 'Choice',
                captcha_mail_enabled       => 0,
                portalDisplayResetPassword => 1,
                dbiAuthChain               => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser                => '',
                dbiAuthPassword            => '',
                dbiAuthTable               => 'users',
                dbiAuthLoginCol            => 'user',
                dbiAuthPasswordCol         => 'password',
                dbiAuthPasswordHash        => '',
                dbiDynamicHashEnabled      => 0,
                dbiMailCol                 => 'mail',
            }
        }
    );

    ok(
        $res = $client->_post(
            '/', IO::String->new('user=yadd&password=yadd&test=sql'),
            length => 32
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    $client->logout($id);

    foreach my $sameBrowser ( 0 .. 1 ) {

        # Test form
        # ------------------------
        ok( $res = $client->_get( '/resetpwd', accept => 'text/html' ),
            'Reset form', );
        my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'mail' );

        $query = 'mail=yadd%40badwolf.org';

        # Post email
        ok(
            $res = $client->_post(
                '/resetpwd', IO::String->new($query),
                query  => 'test=sql',
                length => length($query),
                accept => 'text/html'
            ),
            'Post mail'
        );
        my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

        ok( mail() =~ m#a href="http://auth.example.com/resetpwd\?(.*?)"#,
            'Found link in mail' );
        $query = $1;

        ok(
            $res = $client->_get(
                '/resetpwd',
                query  => $query,
                accept => 'text/html',
                ( $sameBrowser ? ( cookie => $pdata ) : () ),
            ),
            'Post mail token received by mail with '
              . ( $sameBrowser ? 'the same browser' : 'another browser' )
        );
        ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
        ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password' );

        $query .= '&newpassword=zz&confirmpassword=zz';
        $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

        # Post new password
        ok(
            $res = $client->_post(
                '/resetpwd', IO::String->new($query),
                length => length($query),
                accept => 'text/html',
                cookie => $pdata,
            ),
            'Post new password'
        );

        ok( mail() =~ /Your password was changed/, 'Password was changed' );

        #print STDERR Dumper($query);

        ok(
            $res = $client->_post(
                '/',
                IO::String->new('user=yadd&password=zz&test=sql'),
                length => 30
            ),
            'Auth query'
        );
        expectOK($res);
        $id = expectCookie($res);

        $client->logout($id);
        $dbh->do("UPDATE users SET password='dwho' WHERE user='yadd'");
    }

}

count($maintests);
clean_sessions();
done_testing( count() );
