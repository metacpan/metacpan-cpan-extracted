use warnings;
use Test::More;
use strict;

require 't/test-lib.pm';

sub checkUrlAllowed {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $client, $url, $is_allowed ) = @_;
    my $title =
      ( "Test if $url is " . ( $is_allowed ? "" : "not " ) . "allowed" );
    subtest $title => sub {
        ok(
            my $res = $client->_get(
                '/',
                query => {
                    logout => 1,
                    url    => encodeUrl($url),
                },
                accept => 'text/html'
            ),
            'Get logout page'
        );
        expectCookie($res);
        if ($is_allowed) {
            expectRedirection( $res, $url );
        }
        else {
            expectPortalError( $res, 109 );
        }
    };
}

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            trustedDomains => 'example3.com *.example2.com'
        }
    }
);

# Test unauthenticated logout request with param
ok(
    $res = $client->_get(
        '/',
        query  => 'logout',
        accept => 'text/html'
    ),
    'Get logout page'
);
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span trmsg="47">%, ' PE_LOGOUT_OK' )
  or print STDERR Dumper( $res->[2]->[0] );
expectCookie($res);

# Test unauthenticated logout request access with route
ok(
    $res = $client->_get(
        '/logout', accept => 'text/html'
    ),
    'Get logout page'
);
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span trmsg="47">%, ' PE_LOGOUT_OK' )
  or print STDERR Dumper( $res->[2]->[0] );
expectCookie($res);

checkUrlAllowed( $client, "http://test1.example.com/",      1 );
checkUrlAllowed( $client, "http://example3.com/",           1 );
checkUrlAllowed( $client, "http://test.example2.com/",      1 );
checkUrlAllowed( $client, "http://test.test.example2.com/", 1 );
checkUrlAllowed( $client, "http://test.example3.com/",      0 );
checkUrlAllowed( $client, "http://invalid/",                0 );

clean_sessions();

done_testing();
