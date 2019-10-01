use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
    eval "use GSSAPI";
}

my $res;
my $maintests = 2;
my $client;

SKIP: {
    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found', $maintests;
    }
    my $client = LLNG::Manager::Test->new( {
            ini => {
                logLevel       => 'error',
                useSafeJail    => 1,
                authentication => 'Combination',
                userDB         => 'Same',

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
                demoExportedVars => {},
                krbKeytab        => '/etc/keytab',
                krbByJs          => 1,
            }
        }
    );
    ok( $res = $client->_get( '/', accept => 'text/html' ), 'Simple access' );
    ok( $res->[2]->[0] =~ /script.*kerberos\.js/s, 'Found Kerberos JS' )
      or explain( $res->[2]->[0], 'script.*kerberos.js' );
    my ( $host, $url, $query ) = expectForm( $res, '#' );

    # TODO
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

