use Test::More;

BEGIN {
    require 't/test-psgi-lib.pm';
}

my $maintests = 8;

SKIP: {
    eval { require Digest::HMAC_SHA1; };
    if ($@) {
        skip 'Digest::HMAC_SHA1 not found', $maintests;
    }
    init(
        'Lemonldap::NG::Handler::Server',
        {
            logLevel         => 'error',
            zimbraPreAuthKey => '1234567890',
            zimbraUrl        => '/service/preauthtest ',
            zimbraSsoUrl     => '^/testsso  ',             # Bad URLs
            vhostOptions     => {
                'test1.example.com' => {
                    vhostHttps           => 0,
                    vhostPort            => 80,
                    vhostMaintenance     => 0,
                    vhostServiceTokenTTL => -1,
                },
            },
            exportedHeaders => {
                'test1.example.com' => {
                    'Auth-User' => '$uid',
                },
            }
        }
    );

    # Request a non-Zimbra URL
    ok(
        $res = $client->_get(
            '/test',             undef,
            'test1.example.com', "lemonldap=$sessionId",
            VHOSTTYPE => 'ZimbraPreAuth',
        ),
        'Non-Zimbra URL Query'
    );
    ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );

    # Check headers
    %h = @{ $res->[1] };
    ok( !defined $h{'Location'}, 'Location is undefined' )
      or explain( \%h, 'Location => "URL"' );
    ok( $h{'Auth-User'} eq 'dwho', 'Header Auth-User is set to "dwho"' )
      or explain( \%h, 'Auth-User => "dwho"' );

    # Request Zimbra URL
    my $timestamp = time() * 1000;
    my $value =
      Digest::HMAC_SHA1::hmac_sha1_hex( "dwho|id|0|$timestamp", '1234567890' );
    ok(
        $res = $client->_get(
            '/testsso',          undef,
            'test1.example.com', "lemonldap=$sessionId",
            VHOSTTYPE => 'ZimbraPreAuth',
        ),
        'Zimbra URL Query'
    );
    ok( $res->[0] == 302, 'Code is 302' ) or explain( $res->[0], 302 );

    # Check headers
    %h = @{ $res->[1] };
    ok(
        $h{'Location'} =~
m%^/service/preauthtest\?account=dwho&by=id&timestamp=$timestamp&expires=0&preauth=$value$%,
        'Header Location is set to Zimbra URL'
    ) or explain( \%h, 'Location => "Zimbra URL"' );
    ok( $h{'Auth-User'} eq 'dwho', 'Header Auth-User is set to "dwho"' )
      or explain( \%h, 'Auth-User => "dwho"' );
}

count($maintests);
done_testing( count() );
clean();
