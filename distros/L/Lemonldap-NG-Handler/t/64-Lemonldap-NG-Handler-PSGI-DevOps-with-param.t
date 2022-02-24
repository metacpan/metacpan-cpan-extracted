use Test::More;
use JSON;
use MIME::Base64;
use LWP::UserAgent;

BEGIN {
    require 't/test-psgi-lib.pm';
}

### vhostOptions are overridden by fastcgi_param
init(
    'Lemonldap::NG::Handler::Server',
    {
        #logLevel     => 'debug',
        vhostOptions => {
            'test3.example.com' => {
                vhostHttps          => 0,
                vhostPort           => 80,
                vhostDevOpsRulesUrl =>
                  'http://donotuse.example.com/myfile.json',
            },
        },
    }
);

my $res;

# Unauthorized queries
ok(
    $res = $client->_get(
        '/',                 undef,
        'test3.example.com', undef,
        VHOSTTYPE => 'DevOps',
        RULES_URL => 'http://devops.example.com/file.json'
    ),
    'Unauthorized query'
);
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
${ $res->[1] }[1] =~ m#http://auth\.example\.com/\?url=(.+?)%#;
ok( decode_base64 $1 eq 'http://test3.example.com/', 'Redirect URL found' )
  or explain( decode_base64 $1, 'http://test3.example.com/' );
count(3);

Time::Fake->offset("+700s");

ok(
    $res = $client->_get(
        '/',                 undef,
        'test3.example.com', undef,
        HTTPS_REDIRECT => 'on',
        PORT_REDIRECT  => 8443,
        VHOSTTYPE      => 'DevOps',
        RULES_URL      => 'http://devops.example.com/file.json'
    ),
    'Unauthorized query 2'
);
ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );
${ $res->[1] }[1] =~ m#http://auth\.example\.com/\?url=(.+?)%#;
ok( decode_base64 $1 eq 'https://test3.example.com:8443/',
    'Redirect URL found' )
  or explain( decode_base64 $1, 'https://test3.example.com:8443/' );
count(3);

# Authorized queries
ok(
    $res = $client->_get(
        '/',                 undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps',
        RULES_URL => 'http://devops.example.com/file.json'
    ),
    'Authorized query'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
my %headers = @{ $res->[1] };
ok( $headers{User} eq 'dwho', "'User' => 'dwho'" )
  or explain( \%headers, 'dwho' );
ok( $headers{Name} eq '', "'Name' => ''" ) or explain( \%headers, 'No Name' );
ok( $headers{Mail} eq '', "'Mail' => ''" ) or explain( \%headers, 'No Mail' );
ok( keys %headers == 7,   "Seven headers sent" )
  or explain( \%headers, 'Seven headers' );
count(6);

ok(
    $res = $client->_get(
        '/testyes',          undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps',
        RULES_URL => 'http://devops.example.com/file.json'
    ),
    'Authorized query'
);
ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );
count(2);

Time::Fake->offset("+100s");

# Denied queries
ok(
    $res = $client->_get(
        '/deny',             undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps',
        RULES_URL => 'http://devops.example.com/file.json'
    ),
    'Denied query'
);
ok( $res->[0] == 403, 'Code is 403' ) or explain( $res->[0], 403 );
count(2);

Time::Fake->offset("+600s");

ok(
    $res = $client->_get(
        '/testno',           undef,
        'test3.example.com', "lemonldap=$sessionId",
        VHOSTTYPE => 'DevOps',
        RULES_URL => 'http://devops.example.com/file.json'
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
    ok( $req->header('host') eq 'devops.example.com', 'Host header found' )
      or explain( $req->headers(), 'devops.example.com' );
    ok( $req->as_string() =~ m#http://devops.example.com/file.json#,
        'Rules file URL found' )
      or
      explain( $req->as_string(), 'GET http://devops.example.com/file.json' );
    count(2);
    my $httpResp;
    my $s = '{
  "rules": {
    "^/deny": "deny",
    "^/testno": "$uid ne qq{dwho}",
    "^/testyes": "$uid eq qq{dwho}",
    "default": "accept"
  },
  "headers": {
    "User": "$uid",
    "Mail": "$mail",
    "Name": "$cn"
  }
}';
    $httpResp = HTTP::Response->new( 200, 'OK' );
    $httpResp->header( 'Content-Type',   'application/json' );
    $httpResp->header( 'Content-Length', length($s) );
    $httpResp->content($s);
    return $httpResp;
}
