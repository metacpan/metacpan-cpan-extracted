use Test::More;
use strict;

BEGIN {
    require 't/test-lib.pm';
    eval "use GSSAPI";
}

my $maintests = 9;
my $debug     = 'error';

SKIP: {
    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found', $maintests;
    }
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => $debug,
                useSafeJail    => 1,
                authentication => 'Kerberos',
                userDB         => 'Null',
                krbKeytab      => '/etc/keytab',
            }
        }
    );
    my $res;
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Simple access' );
    ok( $res->[0] == 401, 'Get 401' ) or explain( $res->[0], 401 );
    ok( getHeader( $res, 'WWW-Authenticate' ) eq 'Negotiate',
        'Get negotiate header' )
      or explain( $res->[1], 'WWW-Authenticate => Negotiate' );
    &Lemonldap::NG::Handler::Main::cfgNum( 0, 0 );
    $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => $debug,
                useSafeJail    => 1,
                authentication => 'Kerberos',
                userDB         => 'Null',
                krbKeytab      => '/etc/keytab',
                krbByJs        => 1,
                krbAuthnLevel  => 4,
            }
        }
    );
    ok( $res = $client->_get( '/', accept => 'text/html' ),
        'First access with JS' );

    expectForm( $res, '#', undef, 'kerberos' );
    ok(
        $res->[2]->[0] =~ m%<input type="hidden" name="kerberos" value="0" />%,
        'Found hidden attribut "kerberos" with value="0"'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ /kerberos\.(?:min\.)?js/, 'Get Kerberos javascript' );
    ok(
        $res = $client->_get(
            '/',
            query  => 'kerberos=1',
            accept => 'application/json'
        ),
        'Ajax access'
    );
    ok( $res->[0] == 401, 'Get 401' ) or explain( $res->[0], 401 );

    ok(
        $res = $client->_get(
            '/',
            query  => 'kerberos=1',
            accept => 'application/json',
            custom => { HTTP_AUTHORIZATION => 'Negotiate c29tZXRoaW5n' }
        ),
        'Push fake kerberos'
    );
    expectCookie($res);

    #print STDERR Dumper($res);
}

count($maintests);
clean_sessions();
done_testing( count() );

# Redefine GSSAPI method for test
no warnings 'redefine';

sub GSSAPI::Context::accept ($$$$$$$$$$) {
    my $a = \@_;
    $a->[4] = bless {}, 'LLNG::GSSR';
    return 1;
}

package LLNG::GSSR;

sub display {
    my $a = \@_;
    $a->[1] = 'dwho';
    return 1;
}
