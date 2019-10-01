use Test::More;
use JSON;
use MIME::Base64;
use LWP::UserAgent;
use Data::Dumper;

BEGIN {
    require 't/test-psgi-lib.pm';
}

init('Lemonldap::NG::Handler::Server');

my $res;

# Authorized queries
ok(
    $res = $client->_get(
        '/',                 undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps'
    ),
    'Authorized query'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

ok(
    $res = $client->_get(
        '/testyes',          undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps'
    ),
    'Authorized query'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

# Denied queries
ok(
    $res = $client->_get(
        '/deny',             undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps'
    ),
    'Denied query'
);
ok( $res->[0] == 403, 'Code is 403' ) or explain( $res->[0], 403 );
count(2);

ok(
    $res = $client->_get(
        '/testno',           undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps'
    ),
    'Denied query'
);
ok( $res->[0] == 403, 'Code is 403' ) or explain( $res->[0], 403 );
count(2);

done_testing( count() );

clean();

# Redefine LWP methods for tests
no warnings 'redefine';

sub LWP::UserAgent::request {
    my ( $self, $req ) = @_;
    my $httpResp;
    my $s = '{
  "rules": {
    "^/deny": "deny",
    "^/testno": "$uid ne qq{dwho}",
    "^/testyes": "$uid eq qq{dwho}",
    "default": "accept"
  },
  "headers": {
    "User": "$uid"
  }
}';
    $httpResp = HTTP::Response->new( 200, 'OK' );
    $httpResp->header( 'Content-Type',   'application/json' );
    $httpResp->header( 'Content-Length', length($s) );
    $httpResp->content($s);
    return $httpResp;
}
