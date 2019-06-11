use strict;
use warnings;

use LWP::ConsoleLogger::Easy qw( debug_ua );
use LWP::UserAgent     ();
use Plack::Test::Agent ();
use Test::More;

# test pretty printing disabled
# check POST body parsing of JSON
{
    my $app = sub {
        return [
            200, [ 'Content-Type' => 'application/json' ],
            ['{"foo":"bar"}']
        ];
    };

    my $ua             = LWP::UserAgent->new( cookie_jar => {} );
    my $console_logger = debug_ua($ua);
    $console_logger->pretty(0);

    my $server_agent = Plack::Test::Agent->new(
        app    => $app,
        server => 'HTTP::Server::Simple',
        ua     => $ua,
    );

    # mostly just do a visual check that POST params are parsed
    ok( $server_agent->get('/'), 'POST param parsing' );
}

done_testing();
