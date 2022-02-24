use Test::More;
use strict;
use IO::String;
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
    "User": "$uid",
    "Mail": "$mail",
    "Name": "$cn",
    "LDAP_Var": "$ldapExpVar",
    "Groups_SSO": "$groups",
    "UA": "$UA ? $UA : qq#FF#"
  }
}';
my $bad_file = '{
  "rules": {
    "^/testno": "$uid ne qq#dwho#"
    "default": "accept"
  },
  "headers": {
    "User": "$uid",
  }
}';
my $bad_file2 = qq%{
  "rules": {
    "default": "accept"
  },
  "headers": {
    "User": "'user",
    "Mail": "'mail'"
  }
}%;
my $bad_file3 = q%{
  "rule": {
    "default": "accept"
  },
  "headers": {
    "User": "'user",
    "Mail": "'mail'"
  }
}%;
my $bad_file4 = q%{
  "rules": {
    "default": "accept"
  },
  "headers": {
    "test": "$none",
    "bad": "$test ? $other : $dalek"
  }
}%;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                            => 'error',
            authentication                      => 'Demo',
            userDB                              => 'Same',
            requireToken                        => 1,
            checkDevOps                         => 1,
            checkDevOpsDownload                 => 0,
            checkDevOpsDisplayNormalizedHeaders => 0,
            hiddenAttributes                    => 'mail,   UA',
            ldapExportedVars                    => { ldapExpVar => '' }
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
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
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );
ok( $res->[2]->[0] =~ m%<span trspan="checkDevOps">%,
    'Found trspan="checkDevOps"' )
  or explain( $res->[2]->[0], 'trspan="checkDevOps"' );
count(2);

# POST without token
# ------------------
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new(''),
        cookie => "lemonldap=$id",
        length => 0,
        accept => 'text/html'
    ),
    'POST checkdevops without token'
);
ok( $res->[2]->[0] =~ m%<span trspan="PE81"></span%, 'Found PE_NOTOKEN' )
  or explain( $res->[2]->[0], 'trspan="PE81"' );
count(2);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );

# POST bad file
# -------------
$query .= "&checkDevOpsFile=$bad_file";
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html'
    ),
    'POST checkdevops with bad file'
);
ok( $res->[2]->[0] =~ m%<span trspan="PE104"></span>%,
    'Found PE_BAD_DEVOPS_FILE' )
  or explain( $res->[2]->[0], 'trspan="PE104"' );
count(2);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );

# POST bad file2
# --------------
$query .= "&checkDevOpsFile=$bad_file2";
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html'
    ),
    'POST checkdevops with bad file2'
);
ok( $res->[2]->[0] =~ m%<span trspan="PE104"></span>%,
    'Found PE_BAD_DEVOPS_FILE' )
  or explain( $res->[2]->[0], 'trspan="PE104"' );
count(2);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );

# POST bad file3
# --------------
$query .= "&checkDevOpsFile=$bad_file3";
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html'
    ),
    'POST checkdevops with bad file3'
);
ok( $res->[2]->[0] =~ m%<span trspan="PE104"></span>%,
    'Found PE_BAD_DEVOPS_FILE' )
  or explain( $res->[2]->[0], 'trspan="PE104"' );
count(2);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );

# POST bad file4
# --------------
$query .= "&checkDevOpsFile=$bad_file4";
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html'
    ),
    'POST checkdevops with bad file4'
);
ok( $res->[2]->[0] =~ m%<span trspan="PE104"></span>%,
    'Found PE_BAD_DEVOPS_FILE' )
  or explain( $res->[2]->[0], 'trspan="PE104"' );
ok( $res->[2]->[0] =~ m%<span trspan="unknownAttributes">%,
    'Found unknownAttributes' )
  or explain( $res->[2]->[0], 'trspan="unknownAttributes"' );
ok( $res->[2]->[0] =~ m%dalek; none; other; test%,
    'Found 4 unknown attributes' )
  or explain( $res->[2]->[0], 'Unknown attributes' );
count(4);

( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );

# POST file
# ---------
$query .= "&checkDevOpsFile=$file";
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
m%<pre><textarea id="checkDevOpsFile" name="checkDevOpsFile" class="form-control rounded-1" rows="10" trplaceholder="pasteHere" required>%,
    'PRE required'
) or explain( $res->[2]->[0], 'PRE required' );

# Headers
ok( $res->[2]->[0] =~ m%<b><span trspan="headers">HEADERS</span></b>%,
    'HEADERS' )
  or explain( $res->[2]->[0], 'HEADERS' );
ok( $res->[2]->[0] =~ m%Name: Doctor Who<br/>%, 'Hearder Name found' )
  or explain( $res->[2]->[0], 'Hearder Name' );
ok( $res->[2]->[0] =~ m%User: dwho<br/>%, 'Hearder User found' )
  or explain( $res->[2]->[0], 'Hearder User' );
ok( $res->[2]->[0] =~ m%LDAP_Var: <br/>%, 'Hearder LDAP_Var found' )
  or explain( $res->[2]->[0], 'Hearder LDAP_Var' );
ok( $res->[2]->[0] =~ m%Groups_SSO: (.+?)<br/>%, 'Hearder Groups_SSO found' )
  or explain( $res->[2]->[0], 'Hearder Groups_SSO' );
my @groups = split '; ', $1;
ok( scalar @groups == 3, '3 SSO groups found' )
  or explain( $res->[2]->[0], 'SSO groups' );
ok( $res->[2]->[0] !~ m%Mail: dwho\@badwolf.org<br/>%,
    'Hearder Mail not found' )
  or explain( $res->[2]->[0], 'No hearder Mail' );
ok( $res->[2]->[0] !~ m%UA: <br/>%, 'Hearder UA not found' )
  or explain( $res->[2]->[0], 'No hearder UA' );

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
count(13);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );

# POST file (json)
# ----------------
$query .= "&checkDevOpsFile=$file";
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkdevops with file'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{ALERTE} eq 'alert-info', 'alert-info found' )
  or print STDERR Dumper($res);
ok( $res->{FILE} =~ /headers/, 'headers found' )
  or print STDERR Dumper($res);
ok( $res->{FILE} =~ /rules/, 'rules found' )
  or print STDERR Dumper($res);
ok( $res->{FILE} =~ /"\$uid ne qq#dwho#"/, 'rule found' )
  or print STDERR Dumper($res);
count(6);

# POST bad file (json)
# --------------------
ok(
    $res = $client->_get(
        '/checkdevops',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckDevOps form',
);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkdevops', 'checkDevOpsFile', 'token' );

$query .= "&checkDevOpsFile=$bad_file";
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkdevops with file'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{ALERTE} eq 'alert-danger', 'alert-danger found' )
  or print STDERR Dumper($res);
ok( $res->{FILE} eq '', 'No file found' )
  or print STDERR Dumper($res);
ok( $res->{MSG} eq 'PE104', 'PE104 found' )
  or print STDERR Dumper($res);
ok( $res->{TOKEN} =~ /^\d{10}_\d+$/, 'Token found' )
  or print STDERR Dumper($res);
count(7);

# POST with an expired token (json)
# ---------------------------------
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkdevops without token'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{ALERTE} eq 'alert-warning', 'alert-warning found' )
  or print STDERR Dumper($res);
ok( $res->{TOKEN} =~ /^\d{10}_\d+$/, 'Token found' )
  or print STDERR Dumper($res);
ok( $res->{FILE} eq '', 'No file found' )
  or print STDERR Dumper($res);
ok( $res->{MSG} eq 'PE82', 'PE82 found' )
  or print STDERR Dumper($res);
count(6);

# POST without token (json)
# -------------------------
ok(
    $res = $client->_post(
        '/checkdevops',
        IO::String->new(''),
        cookie => "lemonldap=$id",
        length => 0,
    ),
    'POST checkdevops without token'
);
ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{ALERTE} eq 'alert-warning', 'alert-warning found' )
  or print STDERR Dumper($res);
ok( $res->{TOKEN} =~ /^\d{10}_\d+$/, 'Token found' )
  or print STDERR Dumper($res);
ok( $res->{MSG} eq 'PE81', 'PE81 found' )
  or print STDERR Dumper($res);
count(5);

$client->logout($id);
clean_sessions();
done_testing();
