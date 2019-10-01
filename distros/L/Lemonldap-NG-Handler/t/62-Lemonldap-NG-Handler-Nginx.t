use Test::More;
use JSON;
use MIME::Base64;
use Data::Dumper;

require 't/test-psgi-lib.pm';

init('Lemonldap::NG::Handler::Server::Nginx');

my $res;

# Unauthentified query
ok( $res = $client->_get('/'), 'Unauthentified query' );
ok( ref($res) eq 'ARRAY', 'Response is an array' ) or explain( $res, 'array' );
ok( $res->[0] == 401, 'Code is 401' ) or explain( $res->[0], 401 );
my %h = @{ $res->[1] };
ok(
    $h{Location} eq 'http://auth.example.com/?url='
      . encode_base64( 'http://test1.example.com/', '' ),
    'Redirection points to portal'
  )
  or explain(
    \%h,
    'Location => http://auth.example.com/?url='
      . encode_base64( 'http://test1.example.com/', '' )
  );

count(4);

# Authentified queries
# --------------------

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
count(2);

# Denied query
ok( $res = $client->_get( '/deny', undef, undef, "lemonldap=$sessionId" ),
    'Denied query' );
ok( $res->[0] == 403, 'Code is 403' ) or explain( $res->[0], 403 );

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
ok( $res->[0] == 401, 'Code is 401' ) or explain( $res->[0], 401 );
unlink(
't/sessions/lock/Apache-Session-e5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545.lock'
);

count(2);

done_testing( count() );

clean();
