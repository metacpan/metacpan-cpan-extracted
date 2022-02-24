use Test::More;
use JSON;
use MIME::Base64;

BEGIN {
    require 't/test-psgi-lib.pm';
    require 't/custom.pm';
}

init('Lemonldap::NG::Handler::PSGI');

my $res;

# Unauthentified query
ok( $res = $client->_get( '/', undef, 'test.example.org' ),
    'Unauthentified query' );
ok( ref($res) eq 'ARRAY', 'Response is an array' ) or explain( $res, 'array' );
ok( $res->[0] == 302,     'Code is 302' )          or explain( $res->[0], 302 );
my %h = @{ $res->[1] };
ok(
    $h{Location} eq 'http://auth.example.com/?url='
      . encode_base64( 'http://test.example.org/', '' ),
    'Redirection points to portal'
  )
  or explain(
    \%h,
    'Location => http://auth.example.com/?url='
      . encode_base64( 'http://test.example.org/', '' )
  );

count(4);

# Authentified queries
# --------------------

# Authorized query
ok(
    $res =
      $client->_get( '/', undef, 'test.example.org', "lemonldap=$sessionId" ),
    'Authentified query'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res, 200 );
count(2);

# Denied query
ok(
    $res = $client->_get(
        '/orgdeny', undef, 'test.example.org', "lemonldap=$sessionId"
    ),
    'Denied query'
);
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
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
unlink(
't/sessions/lock/Apache-Session-e5eec18ebb9bc96352595e2d8ce962e8ecf7af7c9a98cb9a43f9cd181cf4b545.lock'
);
count(2);

done_testing( count() );
clean();

sub Lemonldap::NG::Handler::PSGI::handler {
    my ( $self, $req ) = @_;
    ok( $req->env->{HTTP_AUTH_USER} eq 'dwho', 'Header is given to app' )
      or explain( $req->env->{HTTP_AUTH_USER}, 'dwho' );
    count(1);
    return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
}
