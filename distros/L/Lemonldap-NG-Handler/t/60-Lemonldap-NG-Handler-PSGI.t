use Test::More;
use JSON;
use MIME::Base64;
use Data::Dumper;
use URI::Escape;

require 't/test-psgi-lib.pm';

init('Lemonldap::NG::Handler::PSGI');

my $res;
my $SKIPUSER = 0;

# Unauthentified query
# --------------------
ok( $res = $client->_get('/'), 'Unauthentified query' );
ok( ref($res) eq 'ARRAY', 'Response is an array' ) or explain( $res, 'array' );
ok( $res->[0] == 302,     ' Code is 302' )         or explain( $res->[0], 302 );
my %h = @{ $res->[1] };
ok(
    $h{Location} eq 'http://auth.example.com/?url='
      . uri_escape( encode_base64( 'http://test1.example.com/', '' ) ),
    'Redirection points to portal'
  )
  or explain(
    \%h,
    'Location => http://auth.example.com/?url='
      . uri_escape( encode_base64( 'http://test1.example.com/', '' ) )
  );
count(4);

# Authentified queries
# --------------------
# Authorized query
ok( $res = $client->_get( '/', undef, undef, "lemonldap=$sessionId" ),
    'Authentified query' );
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

# Request an URI protected by custom function -> allowed
ok(
    $res =
      $client->_get( '/test-uri1/dwho', undef, undef, "lemonldap=$sessionId" ),
    'Authentified query'
);
ok( $res->[0] == 200, '/test-uri1 -> Code is 200' ) or explain( $res, 200 );
count(2);

# Request an URI protected by custom function -> allowed
ok(
    $res = $client->_get(
        '/test-uri2/dwho/dummy', undef, undef, "lemonldap=$sessionId"
    ),
    'Authentified query'
);
ok( $res->[0] == 200, '/test-uri2 -> Code is 200' ) or explain( $res, 200 );
count(2);

# Request an URI protected by custom function -> denied
ok(
    $res =
      $client->_get( '/test-uri1/dwho/', undef, undef, "lemonldap=$sessionId" ),
    'Denied query'
);
ok( $res->[0] == 403, '/test-uri1 -> Code is 403' )
  or explain( $res->[0], 403 );
count(2);

# Request an URI protected by custom function -> denied
ok(
    $res =
      $client->_get( '/test-uri1/dwh', undef, undef, "lemonldap=$sessionId" ),
    'Denied query'
);
ok( $res->[0] == 403, '/test-uri1 -> Code is 403' )
  or explain( $res->[0], 403 );
count(2);

# Denied query
ok( $res = $client->_get( '/deny', undef, undef, "lemonldap=$sessionId" ),
    'Denied query' );
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res->[0], 403 );
count(2);

# Required "timelords" group
ok(
    $res =
      $client->_get( '/fortimelords', undef, undef, "lemonldap=$sessionId" ),
    'Require Timelords group'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

# Required "dalek" group
ok(
    $res = $client->_get( '/fordaleks', undef, undef, "lemonldap=$sessionId" ),
    'Require Dalek group'
);
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res, 403 );
count(2);

# Required AuthnLevel = 1
ok( $res = $client->_get( '/AuthWeak', undef, undef, "lemonldap=$sessionId" ),
    'Weak Authentified query' );
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

# Required AuthnLevel = 5
ok(
    $res = $client->_get( '/AuthStrong', undef, undef, "lemonldap=$sessionId" ),
    'Strong Authentified query'
);
ok( $res->[0] == 302, ' Code is 302' ) or explain( $res, 302 );
%h = @{ $res->[1] };
ok(
    $h{Location} eq 'http://auth.example.com//upgradesession?url='
      . uri_escape(
        encode_base64( 'http://test1.example.com/AuthStrong', '' ) ),
    'Redirection points to http://test1.example.com/AuthStrong'
  )
  or explain(
    \%h,
    'http://auth.example.com//upgradesession?url='
      . uri_escape( encode_base64( 'http://test1.example.com/AuthStrong', '' ) )
  );
count(3);

# Bad cookie name
ok( $res = $client->_get( '/', undef, undef, "fakelemonldap=$sessionId" ),
    'Bad cookie name' );
ok( $res->[0] == 302, ' Code is 302 (name)' ) or explain( $res, 302 );
count(2);

# Bad cookie name
ok( $res = $client->_get( '/', undef, undef, "fake-lemonldap=$sessionId" ),
    'Bad cookie name (-)' );
ok( $res->[0] == 302, ' Code is 302 (-)' ) or explain( $res, 302 );
count(2);

# Bad cookie name
ok( $res = $client->_get( '/', undef, undef, "fake.lemonldap=$sessionId" ),
    'Bad cookie name (.)' );
ok( $res->[0] == 302, ' Code is 302 (.)' ) or explain( $res, 302 );
count(2);

# Bad cookie name
ok( $res = $client->_get( '/', undef, undef, "fake_lemonldap=$sessionId" ),
    'Bad cookie name (_)' );
ok( $res->[0] == 302, ' Code is 302 (_)' ) or explain( $res, 302 );
count(2);

# Bad cookie name
ok( $res = $client->_get( '/', undef, undef, "fake~lemonldap=$sessionId" ),
    'Bad cookie name (~)' );
ok( $res->[0] == 302, ' Code is 302 (~)' ) or explain( $res, 302 );
count(2);

# Bad cookie
ok(
    $res = $client->_get(
        '/deny',
        undef,
        'manager.example.com',
'lemonldap=e5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545'
    ),
    'Bad cookie'
);
ok( $res->[0] == 302, ' Code is 302' ) or explain( $res->[0], 302 );
unlink(
't/sessions/lock/Apache-Session-e5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545.lock'
);
count(2);

# Required AuthnLevel = 1
ok(
    $res = $client->_get(
        '/AuthWeak', undef, 'test2.example.com', "lemonldap=$sessionId"
    ),
    'Weak Authentified query'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

# Required AuthnLevel = 5
ok(
    $res =
      $client->_get( '/', undef, 'test2.example.com', "lemonldap=$sessionId" ),
    'Default Authentified query'
);
ok( $res->[0] == 302, ' Code is 302' ) or explain( $res, 302 );
%h = @{ $res->[1] };
ok(
    $h{Location} eq 'http://auth.example.com//upgradesession?url='
      . uri_escape( encode_base64( 'http://test2.example.com/', '' ) ),
    'Redirection points to http://test2.example.com/'
  )
  or explain(
    \%h,
    'http://auth.example.com//upgradesession?url='
      . uri_escape( encode_base64( 'http://test2.example.com/', '' ) )
  );
count(3);

ok( $res = $client->_get( '/skipif/za', undef, 'test1.example.com' ),
    'Test skip() rule 1' );
ok( $res->[0] == 302, ' Code is 302' ) or explain( $res, 302 );
count(2);

# Wildcards
ok(
    $res =
      $client->_get( '/', undef, 'foo.example.org', "lemonldap=$sessionId" ),
    'Accept "*.example.org"'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

# SKIP TESTS
$SKIPUSER = 1;

ok( $res = $client->_get( '/skipif/zz', undef, 'test1.example.com' ),
    'Test skip() rule 2' );
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

# Forged headers
ok(
    $res = $client->_get(
        '/skipif/zz', undef, 'test1.example.com', undef,
        HTTP_AUTH_USER => 'rtyler'
    ),
    'Test skip() with forged header'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

ok(
    $res =
      $client->_get( '/', undef, 'foo.example.fr', "lemonldap=$sessionId" ),
    'Reject "foo.example.fr"'
);
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res, 403 );
count(2);

ok(
    $res = $client->_get(
        '/orgdeny', undef, 'foo.example.org', "lemonldap=$sessionId"
    ),
    'Reject "foo.example.org/orgdeny"'
);
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res, 403 );
count(2);

ok(
    $res = $client->_get(
        '/orgdeny', undef, 'afoo.example.org', "lemonldap=$sessionId"
    ),
    'Accept "afoo.example.org/orgdeny"'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

ok(
    $res = $client->_get(
        '/orgdeny', undef, 'abfoo.example.org', "lemonldap=$sessionId"
    ),
    'Reject "abfoo.example.org/orgdeny"'
);
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res, 403 );
count(2);

ok(
    $res = $client->_get(
        '/', undef, 'abfoo.a.example.org', "lemonldap=$sessionId"
    ),
    'Accept "abfoo.a.example.org/"'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

ok(
    $res = $client->_get(
        '/orgdeny', undef, 'abfoo.a.example.org', "lemonldap=$sessionId"
    ),
    'Accept "abfoo.a.example.org/orgdeny"'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

ok(
    $res =
      $client->_get( '/', undef, 'abfoo.example.org', "lemonldap=$sessionId" ),
    'Reject "abfoo.example.org/"'
);
ok( $res->[0] == 403, ' Code is 403' ) or explain( $res, 403 );
count(2);

ok(
    $res = $client->_get(
        '/', undef, 'test-foo.example.fr', "lemonldap=$sessionId"
    ),
    'Accept "test*.example.fr"'
);
ok( $res->[0] == 200, ' Code is 200' ) or explain( $res, 200 );
count(2);

done_testing( count() );

clean();

sub Lemonldap::NG::Handler::PSGI::handler {
    my ( $self, $req ) = @_;
    if ($SKIPUSER) {
        ok( !$req->env->{HTTP_AUTH_USER}, 'No HTTP_AUTH_USER' )
          or explain( $req->env->{HTTP_AUTH_USER}, '<empty>' );
    }
    else {
        ok( $req->env->{HTTP_AUTH_USER} eq 'dwho', 'Header is given to app' )
          or explain( $req->env->{HTTP_AUTH_USER}, 'dwho' );
    }
    count(1);
    return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
}
