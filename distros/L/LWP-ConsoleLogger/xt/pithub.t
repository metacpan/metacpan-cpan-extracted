## no critic (Modules::RequireExplicitPackage,Modules::RequireEndWithOne)
use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use Test::More;
use Test::Needs qw( Pithub );
use Test::RequiresInternet ( 'api.github.com' => 443 );
use WWW::Mechanize ();

local $ENV{LWPCL_REDACT_HEADERS} = 'Authorization';

foreach my $class ( 'LWP::UserAgent', 'WWW::Mechanize' ) {
    my $ua = $class->new;
    debug_ua($ua);

    my $p = Pithub->new(
        ua => $ua,
        $ENV{GITHUB_READ_TOKEN} ? ( token => $ENV{GITHUB_READ_TOKEN} ) : (),
    );
    my $result = $p->repos->get( user => 'plu', repo => 'Pithub' );

    ok( $result->content, "content can be decoded for $class" );
}

done_testing();
