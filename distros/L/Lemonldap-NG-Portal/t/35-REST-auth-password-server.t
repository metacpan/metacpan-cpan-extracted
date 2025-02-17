use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use JSON;

require 't/test-lib.pm';

SKIP: {
    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found';
    }
    my $res;
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel           => 'error',
                useSafeJail        => 1,
                requireToken       => 1,
                restAuthServer     => 1,
                restPasswordServer => 1,
                authentication     => 'Combination',
                userDB             => 'Same',

                combination => '[K,Dm] or [Dm]',
                combModules => {
                    K => {
                        for  => 1,
                        type => 'Kerberos',
                    },
                    Dm => {
                        for  => 0,
                        type => 'Demo',
                    },
                },
                krbKeytab => '/etc/keytab',
                krbByJs   => 1,
            }
        }
    );

    # Test pwdConfirm endpoint
    $res = expectJSON(
        postJSON(
            $client,
            "/proxy/pwdConfirm",
            {
                user     => "dwho",
                password => "dwho",
            }
        )
    );

    is( $res->{result}, 1, "Correct password is accepted" );

    $res = expectJSON(
        postJSON(
            $client,
            "/proxy/pwdConfirm",
            {
                user     => "waldo",
                password => "dwho",
            }
        )
    );

    is( $res->{result}, 0, "Incorrect user is rejected" );

    $res = expectJSON(
        postJSON(
            $client,
            "/proxy/pwdConfirm",
            {
                user     => "dwho",
                password => "wrongpass",
            }
        )
    );

    is( $res->{result}, 0, "Incorrect password is rejected" );

    # Test getUser endpoint
    # Existing user
    $res = expectJSON(
        postJSON(
            $client,
            "/proxy/getUser",
            {
                user => "dwho",
            }
        )
    );
    is( $res->{result},               1,            "Correct result" );
    is( $res->{info}->{cn},           "Doctor Who", "Correct attributes" );
    is( $res->{info}->{_whatToTrace}, "dwho",       "Correct macro" );

    # Missing user
    $res = expectJSON(
        postJSON(
            $client,
            "/proxy/getUser",
            {
                user => "notfound",
            }
        )
    );
    is( $res->{result}, 0,     "Correct result" );
    is( $res->{info},   undef, "No attributes" );
}

clean_sessions();
done_testing();

sub postJSON {
    my ( $portal, $url, $payload ) = @_;
    my $string_payload = to_json($payload);
    return $portal->_post(
        $url,
        IO::String->new($string_payload),
        accept => 'application/json',
        type   => 'application/json',
        length => length($string_payload)
    );
}
