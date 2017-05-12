use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use Test::More;
use Test::Needs qw( Pithub );
use Test::RequiresInternet ( 'api.github.com' => 443 );
use WWW::Mechanize ();

foreach my $class ( 'LWP::UserAgent', 'WWW::Mechanize' ) {
    my $ua = $class->new;
    debug_ua($ua);

    my $p = Pithub->new( ua => $ua );
    my $result = $p->repos->get( user => 'plu', repo => 'Pithub' );

    ok( $result->content, "content can be decoded for $class" );
}

done_testing();
