use Test::More;

BEGIN {
    require 't/test-psgi-lib.pm';
}

my $maintests = 12;

SKIP: {
    eval { require Cache::Memcached; };
    if ($@) {
        skip 'Cache::Memcached not found', $maintests;
    }
    my $testmemd = new Cache::Memcached { 'servers' => ["127.0.0.1:11211"] };
    unless ( $testmemd->stats->{hosts} ) {
        skip 'Memcached not started', $maintests;
    }

    eval { require Apache::Session::Generate::MD5; };
    if ($@) {
        skip 'Apache::Session::Generate::MD5 not found', $maintests;
    }
    init(
        'Lemonldap::NG::Handler::Server',
        {
            logLevel          => 'error',
            secureTokenUrls   => [ '^/secured$', '/test$' ],
            secureTokenHeader => 'AuthToken',
            vhostOptions      => {
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

    ## Request secured URLs
    # First URL
    ok(
        $res = $client->_get(
            '/secured',          undef,
            'test1.example.com', "lemonldap=$sessionId",
            VHOSTTYPE => 'SecureToken',
        ),
        'Auth secured URL query 1'
    );
    ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );

    # Check headers
    %h = @{ $res->[1] };
    ok( $h{'AuthToken'} =~ m%[0-9a-f]{32}%, 'Header "AuthToken" found' )
      or explain( \%h, 'AuthToken => "md5 value"' );
    ok( $h{'Auth-User'} eq 'dwho', 'Header Auth-User is set to "dwho"' )
      or explain( \%h, 'Auth-User => "dwho"' );

    # Second URL
    ok(
        $res = $client->_get(
            '/try/test',         undef,
            'test1.example.com', "lemonldap=$sessionId",
            VHOSTTYPE => 'SecureToken',
        ),
        'Auth secured URL query 2'
    );
    ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );

    # Check headers
    %h = @{ $res->[1] };
    ok( $h{'AuthToken'} =~ m%[0-9a-f]{32}%, 'Header "AuthToken" found' )
      or explain( \%h, 'AuthToken => "md5 value"' );
    ok( $h{'Auth-User'} eq 'dwho', 'Header Auth-User is set to "dwho"' )
      or explain( \%h, 'Auth-User => "dwho"' );

    ## Request an unsecured URL
    ok(
        $res = $client->_get(
            '/try',              undef,
            'test1.example.com', "lemonldap=$sessionId",
            VHOSTTYPE => 'SecureToken',
        ),
        'Auth unsecured URL query'
    );
    ok( $res->[0] == 200, 'Code is 200' ) or explain( $res->[0], 200 );

    # Check headers
    %h = @{ $res->[1] };
    ok( !defined $h{'AuthToken'}, 'Header "AuthToken" not found' )
      or explain( \%h, 'AuthToken => "md5 value"' );
    ok( $h{'Auth-User'} eq 'dwho', 'Header Auth-User is set to "dwho"' )
      or explain( \%h, 'Auth-User => "dwho"' );

}

count($maintests);
done_testing( count() );
clean();
