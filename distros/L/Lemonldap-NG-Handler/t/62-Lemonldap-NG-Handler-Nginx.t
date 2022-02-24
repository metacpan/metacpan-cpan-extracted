use Test::More;
use JSON;
use MIME::Base64;
use Data::Dumper;
use URI::Escape;

BEGIN {
    require 't/test-psgi-lib.pm';
    require 't/custom.pm';
}

init('Lemonldap::NG::Handler::Server::Nginx');

my $res;

# Unauthentified query
ok( $res = $client->_get('/'), 'Unauthentified query' );
ok( ref($res) eq 'ARRAY', 'Response is an array' ) or explain( $res, 'array' );
ok( $res->[0] == 401,     'Code is 401' )          or explain( $res->[0], 401 );
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
ok(
    $res =
      $client->_get( '/', undef, 'test4.example.com', "lemonldap=$sessionId" ),
    'Authentified query'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

# Check headers
%h = @{ $res->[1] };
ok(
    $h{'Lm-Remote-Custom'} eq
'dwho@badwolf.org alias Doctor_Who:users; timelords by using Mozilla/5.0 (X11; VAX4000; rv:43.0) Gecko/20100101 Firefox/143.0 Iceweasel/143.0.1',
    'Lm-Remote-Custom is overwriten'
  )
  or explain(
    \%h,
'Lm-Remote-Custom => "dwho@badwolf.org alias Doctor_Who:users; timelords by using Mozilla/5.0 (X11; VAX4000; rv:43.0) Gecko/20100101 Firefox/143.0 Iceweasel/143.0.1"'
  );
count(1);

# Authorized query
ok( $res = $client->_get( '/', undef, undef, "lemonldap=$sessionId" ),
    'Authentified query' );
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

# Check headers
%h = @{ $res->[1] };
ok( $h{'Headername1'} eq 'Auth-User', 'Headername1 is set to "Auth-User"' )
  or explain( \%h, 'Headername1 => "Auth-User"' );
ok( $h{'Headervalue1'} eq 'dwho', 'Headervalue1 is set to "dwho"' )
  or explain( \%h, 'Headervalue1 => "dwho"' );
ok(
    $h{'Lm-Remote-Custom'} eq 'dwho@badwolf.org',
    'Lm-Remote-Custom is set "dwho@badwolf.org"'
) or explain( \%h, 'Lm-Remote-User => "dwho@badwolf.org"' );
count(3);

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
ok( $res->[0] == 403, 'Code is 403' ) or explain( $res->[0], 403 );
count(2);

# Required AuthnLevel = 1
ok( $res = $client->_get( '/AuthWeak', undef, undef, "lemonldap=$sessionId" ),
    'Weak Authentified query' );
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res, 200 );
count(2);

# Required AuthnLevel = 5
ok(
    $res = $client->_get( '/AuthStrong', undef, undef, "lemonldap=$sessionId" ),
    'Strong Authentified query'
);
ok( $res->[0] == 401, 'Code is 401' ) or explain( $res, 401 );
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
ok( $res->[0] == 401, 'Code is 401' ) or explain( $res->[0], 401 );
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
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res, 200 );
count(2);

# Required AuthnLevel = 5
ok(
    $res =
      $client->_get( '/', undef, 'test2.example.com', "lemonldap=$sessionId" ),
    'Default Authentified query'
);
ok( $res->[0] == 401, 'Code is 401' ) or explain( $res, 401 );
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

# Clean headers
ok(
    $res = $client->_get(
        '/skipif/zz', undef, 'test1.example.com', undef,
        HTTP_AUTH_USER => 'rtyler'
    ),
    'Test skip() with forged header'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res, 200 );
count(2);
%h = @{ $res->[1] };
my %delete;
foreach ( keys %h ) {
    /^Deleteheader\d$/ and $delete{ $h{$_} }++;
}
foreach (qw(Cookie HTTP_COOKIE Auth-User HTTP_AUTH_USER)) {
    ok( $delete{$_}, "Delete command for $_" )
      or explain( \%h, 'Delete* headers' );
    ok( !$h{$_}, "$_ is deleted" ) or explain( \%h, 'Delete* headers' );
    count(2);
}

done_testing( count() );

clean();
