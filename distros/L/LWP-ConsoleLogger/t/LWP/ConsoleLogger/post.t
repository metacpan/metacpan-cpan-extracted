use strict;
use warnings;

use LWP::ConsoleLogger::Easy             qw( debug_ua );
use LWP::UserAgent                       ();
use Plack::Handler::HTTP::Server::Simple ();
use Plack::Test::Agent                   ();
use Test::More import => [qw( done_testing ok )];

# check POST body parsing
{
    my $app
        = sub { return [ 200, [ 'Content-Type' => 'text/html' ], ['boo'] ] };

    my $ua = LWP::UserAgent->new( cookie_jar => {} );
    debug_ua($ua);
    my $server_agent = Plack::Test::Agent->new(
        app    => $app,
        server => Plack::Handler::HTTP::Server::Simple::,
        ua     => $ua,
    );

    # mostly just do a visual check that POST params are parsed
    ok(
        $server_agent->post( '/', [ foo => 'bar', baz => 'qux' ] ),
        'POST param parsing'
    );
}

done_testing();
