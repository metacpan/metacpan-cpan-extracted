use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants 'PE_CAPTCHAEMPTY';

require 't/test-lib.pm';

my $res;

my $maintests = 0;
SKIP: {
    eval 'use GD::SecurityImage; use Image::Magick;';
    if ($@) {
        skip 'Image::Magick not found', $maintests;
    }

    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                portalMainLogo => 'common/logos/logo_llng_old.png',
                customPlugins  => 't::CaptchaOldApi',
            }
        }
    );
    my ( $data, $json );

    # check setCaptcha
    $data = '';
    $json = expectJSON(
        $client->_post(
            '/setCaptcha',
            IO::String->new($data),
            length => length($data),
        )
    );
    like( $json->{token},  qr/.+/ );
    like( $json->{img},    qr#^data:image/png;base64,.{10}# );
    like( $json->{answer}, qr#^\d{6}$# );
    count(3);

    # check getCaptcha
    $data = '';
    $json = expectJSON(
        $client->_post(
            '/getCaptcha',
            IO::String->new($data),
            length => length($data),
        )
    );
    like( $json->{token},  qr/.+/ );
    like( $json->{img},    qr#^data:image/png;base64,.{10}# );
    like( $json->{answer}, qr#^\d{6}$# );
    count(3);

    my $token  = $json->{token};
    my $answer = $json->{answer};

    # validate: wrong token
    $data = buildForm( { token => 111, answer => $answer } );
    $json = expectJSON(
        $client->_post(
            '/validateCaptcha', IO::String->new($data),
            length => length($data),
        )
    );
    is( $json->{result}, 0, 'Wrong token failed' );
    count(1);

    # validate: wrong answer
    $data = buildForm( { token => $token, answer => 999 } );
    $json = expectJSON(
        $client->_post(
            '/validateCaptcha', IO::String->new($data),
            length => length($data),
        )
    );
    is( $json->{result}, 0, 'Wrong captcha failed' );
    count(1);

    # Get Fresh token/answer pair
    $data = '';
    $json = expectJSON(
        $client->_post(
            '/getCaptcha',
            IO::String->new($data),
            length => length($data),
        )
    );
    like( $json->{token},  qr/.+/ );
    like( $json->{img},    qr#^data:image/png;base64,.{10}# );
    like( $json->{answer}, qr#^\d{6}$# );
    count(3);

    $token  = $json->{token};
    $answer = $json->{answer};

    # validate: correct values
    $data = buildForm( { token => $token, answer => $answer } );
    $json = expectJSON(
        $client->_post(
            '/validateCaptcha', IO::String->new($data),
            length => length($data),
        )
    );
    is( $json->{result}, 1, 'Captcha successfully verified' );
    count(1);

}
count($maintests);

clean_sessions();

done_testing( count() );
