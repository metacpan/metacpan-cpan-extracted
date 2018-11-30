use Test::More;
use strict;
use IO::String;

BEGIN {
    eval {
        unlink 't/userdb.db';
        require 't/test-lib.pm';
        require 't/smtp.pm';
    };
}

my ( $res, $user, $pwd );
my $maintests = 17;
my $mailSend  = 0;

my $mail2 = 0;

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
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/userdb.db");
    $dbh->do(
        'CREATE TABLE users (user text,password text,name text, mail text)');
    $dbh->do(
"INSERT INTO users VALUES ('dwho','dwho','Doctor who','dwho\@badwolf.org')"
    );

    my $client = LLNG::Manager::Test->new(
        {
            ini => {
                logLevel                    => 'error',
                useSafeJail                 => 1,
                portalDisplayRegister       => 1,
                authentication              => 'DBI',
                userDB                      => 'Same',
                passwordDB                  => 'DBI',
                captcha_mail_enabled        => 0,
                portalDisplayResetPassword  => 1,
                dbiAuthChain                => 'dbi:SQLite:dbname=t/userdb.db',
                dbiAuthUser                 => '',
                dbiAuthPassword             => '',
                dbiAuthTable                => 'users',
                dbiAuthLoginCol             => 'user',
                dbiAuthPasswordCol          => 'password',
                dbiAuthPasswordHash         => '',
                dbiDynamicHashEnabled       => 0,
                dbiMailCol                  => 'mail',
                passwordResetAllowedRetries => 4,
            }
        }
    );

    # Test form
    # ------------------------
    ok( $res = $client->_get( '/resetpwd', accept => 'text/html' ),
        'Reset form', );
    my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'mail' );

    $query = 'mail=dwho%40badwolf.org';

    # Post email
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post mail'
    );

    ok( mail() =~ m#a href="http://auth.example.com/resetpwd\?(.*?)"#,
        'Found link in mail' );
    $query = $1;

    ok(
        $res = $client->_get(
            '/resetpwd',
            query  => $query,
            accept => 'text/html'
        ),
        'Post mail token received by mail'
    );

    # Post mismatched passwords
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password #1' );

    $query .= '&newpassword=zz&confirmpassword=z';
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post mismatched passwords'
    );
    ok( $res->[2]->[0] =~ m%<span trmsg="34"></span>%, 'PE_34 found' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Post empty password 1
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password #2' );

    $query .= '&newpassword=&confirmpassword=zz';
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post empty newpassword'
    );
    ok( $res->[2]->[0] =~ m%<span trmsg="67"></span>%, 'PE_67 found' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Post empty password 2
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password #3' );

    $query .= '&newpassword=zz&confirmpassword=';
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post empty confirmpassword'
    );
    ok( $res->[2]->[0] =~ m%<span trmsg="67"></span>%, 'PE_67 found' )
      or print STDERR Dumper( $res->[2]->[0] );

    # Post new password
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'token' );
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password #4' );

    $query .= '&newpassword=zz&confirmpassword=zz';
    ok(
        $res = $client->_post(
            '/resetpwd', IO::String->new($query),
            length => length($query),
            accept => 'text/html'
        ),
        'Post new password'
    );

    ok( mail() =~ /Your password was changed/, 'Password was changed' );

    ok(
        $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=zz'),
            length => 21
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    $client->logout($id);

    #print STDERR Dumper($query);
}

eval { unlink 't/userdb.db' };
count($maintests);
clean_sessions();
done_testing( count() );
