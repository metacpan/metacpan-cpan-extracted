use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $res;
my $json;
my $maintests = 24;

SKIP: {
    skip 'LLNGTESTLDAP is not set', $maintests unless ( $ENV{LLNGTESTLDAP} );
    require 't/test-ldap.pm';
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel        => 'error',
                useSafeJail     => 1,
                authentication  => 'Combination',
                userDB          => 'Same',
                passwordDB      => 'LDAP',
                ldapServer      => $main::slapd_url,
                ldapBase        => 'ou=users,dc=example,dc=com',
                managerDn       => 'cn=admin,dc=example,dc=com',
                managerPassword => 'admin',
                combModules     => {
                    'LDAP' => { 'for' => 0, 'type' => 'LDAP' },
                    'Demo' => { 'for' => 0, 'type' => 'Demo' }
                },
                combination                 => '[Demo, Demo] or [LDAP, LDAP]',
                findUser                    => 1,
                impersonationRule           => 1,
                findUserSearchingAttributes =>
                  { 'uid##1' => 'Login', 'cn##1' => 'Name' },
                findUserExcludingAttributes => { uid => 'rtyler' },
            }
        }
    );
    use Lemonldap::NG::Portal::Main::Constants 'PE_USERNOTFOUND';

    ## Simple access
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
    my ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

    my $request = '';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'text/html',
            length => length($request)
        ),
        'Post empty FindUser request'
    );
    ( $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );
    ( $host, $url, $query ) = expectForm( $res, '#', undef, 'uid', 'cn' );
    ok(
        $res->[2]->[0] =~
m%<input name="spoofId" type="text" class="form-control" value="" autocomplete="off" trplaceholder="spoofId" aria-required="false"%,
        'value=""'
    ) or explain( $res->[2]->[0], 'value=""' );

    $request = 'uid=dwho';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'text/html',
            length => length($request)
        ),
        'Post FindUser request'
    );
    ok( $res->[2]->[0] =~ m%value="dwho"%, 'value="dwho"' )
      or explain( $res->[2]->[0], 'value="dwho"' );
    ok( $res->[2]->[0] =~ m%autocomplete="off"%, 'autocomplete="off"' )
      or explain( $res->[2]->[0], 'autocomplete="off"' );
    ok(
        $res->[2]->[0] =~
          m%<span trspan="searchAccount">Search for an account</span>%,
        'Search an account'
    ) or explain( $res->[2]->[0], 'Search for an account' );
    ok(
        $res->[2]->[0] =~
m%<input id="findUser_uid" name="uid" type="text" autocomplete="off" class="form-control" aria-label="Login" placeholder="Login" />%,
        'id="findUser_uid"'
    ) or explain( $res->[2]->[0], 'id="findUser_uid"' );
    ok(
        $res->[2]->[0] =~
m%<input id="findUser_cn" name="cn" type="text" autocomplete="off" class="form-control" aria-label="Name" placeholder="Name" />%,
        'id="findUser_cn"'
    ) or explain( $res->[2]->[0], 'id="findUser_cn"' );

    $request = 'uid=dwho';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'application/json',
            length => length($request)
        ),
        'Post FindUser request'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{user} eq 'dwho', ' Good user' )
      or explain( $json, 'user => dwho' );

    $request = 'uid=ohwd';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'application/json',
            length => length($request)
        ),
        'Post FindUser request with bad user'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 0, ' Good result' )
      or explain( $json, 'result => 0' );
    ok( $json->{error} == PE_USERNOTFOUND, ' No user found' )
      or explain( $json, 'error => 4' );

    $request = 'cn=Rose Tyler';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'application/json',
            length => length($request)
        ),
        'Post FindUser request with excluding result'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 1, ' Good result' )
      or explain( $json, 'result => 1' );
    ok( $json->{user} eq '', ' No user' )
      or explain( $json, "user => ?" );

    $request = 'uid=reset';
    ok(
        $res = $client->_post(
            '/finduser', IO::String->new($request),
            accept => 'application/json',
            length => length($request)
        ),
        'Post FindUser request with excluding result'
    );
    ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
      or print STDERR "$@\n" . Dumper($res);
    ok( $json->{result} == 1, ' Good result' )
      or explain( $json, 'result => 1' );
    ok( $json->{user} eq 'reset', ' Good user' )
      or explain( $json, "user => reset" );

}
count($maintests);
stopLdapServer() if $ENV{LLNGTESTLDAP};
clean_sessions();
done_testing( count() );

