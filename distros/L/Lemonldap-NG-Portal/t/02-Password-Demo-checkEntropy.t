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

SKIP: {
    eval "use Data::Password::zxcvbn;";
    if ($@) {
        skip 'Data::Password::zxcvbn not found';
    }

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
                checkHIBP                   => 0,
                checkHIBPRequired           => 0,
                checkEntropy                => 1,
                checkEntropyRequired        => 1,
                checkEntropyRequiredLevel => 2
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

    # Test password entropy
    # ---------------------
    ok(
        $res = $client->_post(
            '/',
            IO::String->new(
    'oldpassword=dwho&newpassword=secret1&confirmpassword=secret1'
            ),
            cookie => "lemonldap=$id",
            accept => 'application/json',
            length => 60
        ),
        'Too simple password'
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
    'oldpassword=dwho&newpassword=L3m0n1DaPl&confirmpassword=L3m0n1DaPl'),
            cookie => "lemonldap=$id",
            accept => 'application/json',
            length => 66
        ),
        'Password with force 3 accepted'
    );
    expectOK($res);

    $client->logout($id);
}

clean_sessions();

done_testing( );

