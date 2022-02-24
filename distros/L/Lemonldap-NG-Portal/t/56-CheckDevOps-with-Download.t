use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use JSON;

BEGIN {
    require 't/test-lib.pm';
}

my $res;
my $file = '{
  "rules": {
    "^/deny": "deny",
    "^/testno": "$uid ne qq#dwho#",
    "^/testyes": "$uid eq qq#dwho#",
    "default": "accept"
  },
  "headers": {
    "Auth-User": "$uid",
    "Mail": "$mail",
    "Name": "$cn",
    "UA": "$UA"
  }
}';
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                          => 'error',
            authentication                    => 'Demo',
            userDB                            => 'Same',
            requireToken                      => 0,
            checkDevOps                       => 1,
            checkDevOpsDownload               => 1,
            checkDevOpsCheckSessionAttributes => 0,
            hiddenAttributes                  => 'mail'
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );

$query = 'user=dwho&password=dwho';
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# CheckDevOps form
# ----------------
ok(
    $res = $client->_get(
        '/checkdevops',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckDevOps form',
);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkDevOps">%,
    'Found trspan="checkDevOps"' )
  or explain( $res->[2]->[0], 'trspan="checkDevOps"' );
count(2);

# POST file
# ---------
$query = "checkDevOpsFile=$file";
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html'
    ),
    'POST checkdevops with file'
);
ok(
    $res->[2]->[0] =~
m%<pre><textarea id="checkDevOpsFile" name="checkDevOpsFile" class="form-control rounded-1" rows="10" trplaceholder="pasteHere">%,
    'PRE not required'
) or explain( $res->[2]->[0], 'PRE not required' );

# Headers
ok( $res->[2]->[0] =~ m%<b><span trspan="headers">HEADERS</span></b>%,
    'HEADERS' )
  or explain( $res->[2]->[0], 'HEADERS' );
ok( $res->[2]->[0] =~ m%HTTP_NAME: Doctor Who<br/>%,
    'Normalized hearder Name found' )
  or explain( $res->[2]->[0], 'Hearder Name' );
ok(
    $res->[2]->[0] =~ m%HTTP_AUTH_USER: dwho<br/>%,
    'Normalized hearder Auth-User found'
) or explain( $res->[2]->[0], 'Hearder Auth-User' );

# Rules
ok( $res->[2]->[0] =~ m%<b><span trspan="rules">RULES</span></b>%, 'RULES' )
  or explain( $res->[2]->[0], 'RULES' );
ok( $res->[2]->[0] =~ m%\^/testno: <span trspan="forbidden">%, 'testno' )
  or explain( $res->[2]->[0], 'testno' );
ok( $res->[2]->[0] =~ m%default: <span trspan="allowed">%, 'default' )
  or explain( $res->[2]->[0], 'default' );
ok( $res->[2]->[0] =~ m%\^/testyes: <span trspan="allowed">%, 'testyes' )
  or explain( $res->[2]->[0], 'testyes' );
ok( $res->[2]->[0] =~ m%\^/deny: <span trspan="forbidden">%, 'deny' )
  or explain( $res->[2]->[0], 'deny' );
ok( $res->[2]->[0] =~ m%\$uid eq qq#dwho#"%, 'file' )
  or explain( $res->[2]->[0], 'file' );
ok( $res->[2]->[0] !~ m%Mail: dwho\@badwolf.org<br/>%,
    'Hearder Mail not found' )
  or explain( $res->[2]->[0], 'No hearder Mail' );
ok( $res->[2]->[0] =~ m%UA: <br/>%, 'Hearder UA found' )
  or explain( $res->[2]->[0], 'Hearder UA' );
count(13);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile' );

# Empty form
# ----------
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST empty checkdevops form'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{ALERTE} eq 'alert-danger', 'alert-danger found' )
  or print STDERR Dumper($res);
ok( $res->{MSG} eq 'PE79', 'PE79' )
  or print STDERR Dumper($res);
count(4);

# Fail to download file
# ---------------------
$query = 'url=http://testfail.example.com';
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkdevops with url'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{ALERTE} eq 'alert-danger', 'alert-danger found' )
  or print STDERR Dumper($res);
ok( $res->{MSG} eq 'PE105', 'PE105' )
  or print STDERR Dumper($res);
count(4);

# Bad URLs
# --------
$query = 'url=test3.example.com';
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkdevops with url'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'PE37', 'Bad URL' )
  or print STDERR Dumper($res);
count(3);

# --------
$query = 'url=http://test3.example.com#test';
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkdevops with wrong url'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{URL} eq 'http://test3.example.com/rules.json', 'Well formated URL' )
  or print STDERR Dumper($res);
count(3);

$client->logout($id);
clean_sessions();
done_testing();

# Redefine LWP methods for tests
no warnings 'redefine';

sub LWP::UserAgent::request {
    my ( $self, $req ) = @_;
    my $httpResp;
    my $s = '{
  "rules": {
    "^/deny": "deny",
    "^/testno": "$uid ne qq#dwho#",
    "^/testyes": "$uid eq qq#dwho#",
    "default": "accept"
  },
  "headers": {
    "User": "$uid",
    "Mail": "$mail",
    "Name": "$cn"
  }
}';

    if ( $req->{_uri} =~ /testfail\.example\.com/ ) {
        $httpResp = HTTP::Response->new( 404, 'NOT FOUND' );
        $httpResp->header( 'Content-Length', 0 );
    }
    else {
        $httpResp = HTTP::Response->new( 200, 'OK' );
        $httpResp->header( 'Content-Length', length($s) );
        $httpResp->header( 'Content-Type',   'application/json' );
        $httpResp->content($s);
    }
    return $httpResp;
}
