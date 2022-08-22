use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use LWP::UserAgent           ();
use Path::Tiny               qw( path );
use Test::Warnings;
use Test::More import => [qw( done_testing is )];

my $mech = LWP::UserAgent->new;
debug_ua($mech);

my $res
    = $mech->get( 'file:///' . path('t/test-data/unicode.html')->absolute );
is( $res->code, 200, 'got unicode file' );

done_testing();
