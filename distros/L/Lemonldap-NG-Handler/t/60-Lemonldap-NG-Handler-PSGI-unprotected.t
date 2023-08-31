use Test::More;
use JSON;
use MIME::Base64;
use Data::Dumper;
use URI::Escape;

require 't/test-psgi-lib.pm';

init( 'Lemonldap::NG::Handler::PSGI', { protection => 'none' } );

my $res;
my $SKIPUSER = 0;

# Unauthentified query
# --------------------
ok( $res = $client->_get('/'), 'Unauthentified query' );
is( $res->[0],      200,     "Unprotected request succeeds" );
is( $res->[2]->[0], "Hello", "Expected content" );
count(3);
done_testing( count() );

clean();

sub Lemonldap::NG::Handler::PSGI::handler {
    my ( $self, $req ) = @_;
    ok( !$req->env->{HTTP_AUTH_USER}, 'No HTTP_AUTH_USER' )
      or explain( $req->env->{HTTP_AUTH_USER}, '<empty>' );
    count(1);
    return [ 200, [ 'Content-Type', 'text/plain' ], ['Hello'] ];
}
