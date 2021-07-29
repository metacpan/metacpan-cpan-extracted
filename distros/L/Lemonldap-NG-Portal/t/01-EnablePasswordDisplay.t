use Test::More;
use strict;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                      => 'error',
            'portalEnablePasswordDisplay' => 1,
            'browsersDontStorePassword'   => 1
        }
    }
);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Display portal' );
ok( $res->[2]->[0] =~ m%<i class="fa fa-eye-slash toggle-password">%,
    ' toggle password icon found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

clean_sessions();

done_testing( count() );
