use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;
use LWP::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_PP_PASSWORD_TOO_SHORT PE_PP_INSUFFICIENT_PASSWORD_QUALITY
  PE_PP_NOT_ALLOWED_CHARACTER PE_PP_NOT_ALLOWED_CHARACTERS
);

require 't/test-lib.pm';

my ( $res, $json );

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            passwordDB                  => 'Demo',
            passwordPolicy              => 1,
            portalRequireOldPassword    => 0,
            passwordPolicyMinSize       => 6,
            passwordPolicyMinLower      => 0,
            passwordPolicyMinUpper      => 0,
            passwordPolicyMinDigit      => 0,
            passwordPolicyMinSpeChar    => 0,
            passwordPolicySpecialChar   => '[ }\ }',
            portalDisplayPasswordPolicy => 1,
            checkHIBP                   => 1,
            checkHIBPURL      => 'https://api.pwnedpasswords.com/range/',
            checkHIBPRequired => 1,
        }
    }
);

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

$res = $client->_get(
    '/',
    cookie => "lemonldap=$id",
    accept => "text/html",
);

ok( getHtmlElement( $res, '//li/i[@id="ppolicy-checkhibp-feedback"]' ),
    "Found HIBP ppolicy display (id)" );
ok( getHtmlElement( $res, '//li/span[@trspan="passwordCompromised"]' ),
    "Found HIBP ppolicy display (message)" );
count(2);

# <i id=ppolicy-checkhibp-feedback" class="fa fa-li">
# Test HIBP API
# -------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new(
'oldpassword=dwho&newpassword=400_BAD_REQ&confirmpassword=400_BAD_REQ'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Bad request'
);
expectBadRequest($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
    'Response is PE_PP_INSUFFICIENT_PASSWORD_QUALITY'
) or explain( $json, "error => 28" );

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
            'oldpassword=dwho&newpassword=secret&confirmpassword=secret'),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 58
    ),
    'Simple password found in HIBP database'
);
expectBadRequest($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok(
    $json->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
    'Response is PE_PP_INSUFFICIENT_PASSWORD_QUALITY'
) or explain( $json, "error => 28" );

ok(
    $res = $client->_post(
        '/',
        IO::String->new(
'oldpassword=dwho&newpassword=T ESTis0k\}&confirmpassword=T ESTis0k\}'
        ),
        cookie => "lemonldap=$id",
        accept => 'application/json',
        length => 68
    ),
    'Complex password not found in HIBP database'
);
count(7);
expectOK($res);

$client->logout($id);

clean_sessions();

done_testing( count() );

# Redefine LWP methods for tests
no warnings 'redefine';

sub LWP::UserAgent::request {
    my ( $self, $req ) = @_;
    my $httpResp;

    ok( $req->header('User-Agent') eq 'libwww-perl/6.05 (LemonLDAPNG)',
        'Host header found' )
      or explain( $req->headers(), 'libwww-perl/6.05 (LemonLDAPNG)' );
    ok(
        $req->as_string() =~ m#^GET https://api.pwnedpasswords.com/range/\w{5}#,
        'HIBP URL found'
      )
      or explain( $req->as_string(),
        'GET https://api.pwnedpasswords.com/range/XXXXX' );
    count(2);

    my @responses = ( '
e5e9fa146d6f8627b79a08a7169f37f6b2707e35:3
e5e9fa178c336965ade492d1339283a18130bfd8:1
e5e9fa19b0eec379cf37340f5f553fe1bed36409:7
e5e9fa1a88735bc307a2d5c6b844cc4c70be73d3:1
e5e9fa1ba31ecd1ae84f75caaa474f3a663f05f4:356668
', '
1c1affeb79e72418ec820f6c507fbbd10157b3ec:1
1c1affed3c02c28a3c9d1948b5c06a19798bd2dc:2
1c1affedaa98f73886cce16994f4e5c12ea7a4b1:1
1c1affeeb9a61c10ac3d507cc28b76dca24fd5d7:1
1c1afff936e01bd57498e3b049ae0e04ad6597e0:2
' );

    if ( $req->{_uri} =~ m#/range/e5e9f$# ) {
        $httpResp = HTTP::Response->new( 200, 'OK' );
        $httpResp->header( 'Content-Length', length( $responses[0] ) );
        $httpResp->header( 'Content-Type',   'application/json' );
        $httpResp->content( $responses[0] );
    }
    elsif ( $req->{_uri} =~ m#/range/1c1af$# ) {
        $httpResp = HTTP::Response->new( 200, 'OK' );
        $httpResp->header( 'Content-Length', length( $responses[1] ) );
        $httpResp->header( 'Content-Type',   'application/json' );
        $httpResp->content( $responses[1] );
    }
    else {
        $httpResp = HTTP::Response->new( 400, 'BAD REQUEST' );
        $httpResp->header( 'Content-Length', 0 );
    }
    return $httpResp;
}
