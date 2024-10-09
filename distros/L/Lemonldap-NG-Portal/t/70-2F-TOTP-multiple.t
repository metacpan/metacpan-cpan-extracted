use warnings;
use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';

SKIP: {
    eval { require Convert::Base32 };
    if ($@) {
        skip 'Convert::Base32 is missing';
    }
    require Lemonldap::NG::Common::TOTP;

    my $client = LLNG::Manager::Test->new( {
            ini => {
                totp2fActivation => 1,
            }
        }
    );
    my $res;

    my $key1 = "UUUU" x 8;
    my $key2 = "RRRR" x 8;
    my $key3 = "SSSS" x 8;

    # Inject TOTP devices
    $client->p->getPersistentSession(
        "dwho",
        {
            '_2fDevices' => to_json( [ {
                        epoch   => "11111",
                        type    => "TOTP",
                        _secret => $key1,
                        name    => "MyTOTP1",
                    },
                    {
                        epoch   => "22222",
                        type    => "TOTP",
                        _secret => $key2,
                        name    => "MyTOTP2",
                    }
                ]
            ),
        }
    );

    sub authenticate {
        my ( $client, $key, $should_succeed ) = @_;
        ok(
            $res = $client->_post(
                '/',
                IO::String->new('user=dwho&password=dwho'),
                length => 23,
                accept => 'text/html',
            ),
            'Auth query'
        );
        my ( $host, $url, $query ) =
          expectForm( $res, undef, '/totp2fcheck', 'token' );
        ok(
            my $code = Lemonldap::NG::Common::TOTP::_code(
                undef, Convert::Base32::decode_base32($key),
                0,     30, 6
            ),
            'Code'
        );
        $query =~ s/code=/code=$code/;
        ok(
            $res = $client->_post(
                '/totp2fcheck', IO::String->new($query),
                length => length($query),
                accept => "text/html",
            ),
            'Post code'
        );
        if ($should_succeed) {
            my $id = expectCookie($res);
        }
        else {
            expectPortalError( $res, 96 );
        }

    }

    subtest "Authenticate with first device" => sub {
        authenticate( $client, $key1, 1 );
    };
    subtest "Authenticate with second device" => sub {
        authenticate( $client, $key2, 1 );
    };

    subtest "Authenticate with unknown device" => sub {
        authenticate( $client, $key3, 0 );
    };
}

clean_sessions();

done_testing();

