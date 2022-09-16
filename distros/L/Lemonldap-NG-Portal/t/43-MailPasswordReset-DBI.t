use Test::More;
use strict;
use IO::String;

my $userdb;

BEGIN {
    eval {
        require 't/test-lib.pm';
        require 't/smtp.pm';
        $userdb = tempdb();
    };
}

my ( $res, $user, $pwd );
my $maintests = 22;
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
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do(
        'CREATE TABLE users (user text,password text,name text, mail text)');
    $dbh->do(
"INSERT INTO users VALUES ('dwho','dwho','Doctor who','dwho\@badwolf.org')"
    );

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel                    => 'error',
                useSafeJail                 => 1,
                portalDisplayRegister       => 1,
                authentication              => 'DBI',
                userDB                      => 'Same',
                passwordDB                  => 'DBI',
                captcha_mail_enabled        => 0,
                portalDisplayResetPassword  => 1,
                dbiAuthChain                => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser                 => '',
                dbiAuthPassword             => '',
                dbiAuthTable                => 'users',
                dbiAuthLoginCol             => 'user',
                dbiAuthPasswordCol          => 'password',
                dbiAuthPasswordHash         => '',
                dbiDynamicHashEnabled       => 0,
                dbiMailCol                  => 'mail',
                portalEnablePasswordDisplay => 1,
                portalDisplayPasswordPolicy => 1,
                passwordPolicyActivation    => 0,
                passwordResetAllowedRetries => 4,
                passwordPolicyMinDigit      => 2,
                passwordPolicyMinSpeChar    => 1,
                passwordPolicySpecialChar   => '__ALL__'
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
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password #1' )
      or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
m%<i id="toggle_newpassword" class="fa fa-eye-slash toggle-password">%,
        ' toggle newpassword icon found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
m%<i id="toggle_confirmpassword" class="fa fa-eye-slash toggle-password">%,
        ' toggle confirmpassword icon found'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok(
        $res->[2]->[0] =~
m%<input id="newpassword" name="newpassword" type="password" class="form-control"%,
        ' input type password found'
    ) or print STDERR Dumper( $res->[2]->[0] );

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
    ok( $res->[2]->[0] =~ /newpassword/s, ' Ask for a new password #3' )
      or print STDERR Dumper( $res->[2]->[0] );

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
    ok(
        $res->[2]->[0] !~ /passwordPolicySpecialChar/,
        ' Password special char list not found'
    );
    ok(
        $res->[2]->[0] =~
/<span trspan="passwordPolicyMinDigit">Minimal digit characters:<\/span> 2/,
        ' Found password policy min digit == 2'
    );
    $query .= '&newpassword=zz11#&confirmpassword=zz11#';
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
            IO::String->new('user=dwho&password=zz11#'),
            length => 24
        ),
        'Auth query'
    );
    expectOK($res);
    my $id = expectCookie($res);

    $client->logout($id);

    #print STDERR Dumper($query);
}

count($maintests);
clean_sessions();
done_testing( count() );
