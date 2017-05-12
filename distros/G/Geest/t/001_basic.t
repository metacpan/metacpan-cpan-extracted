use strict;
use Test::More;
use Test::TCP;
use LWP::UserAgent;
use Plack::Runner;
use Plack::Test;

use_ok "Geest";

my $content = join ".", time(), {}, rand(), $$;
my $server1 = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(
            "--port" => $port,
            "--no-default-middleware",
            "--server" => "HTTP::Server::PSGI"
        );
        $runner->run(sub {
            pass("There was an access to server1");
            return [ 200, [ "Content-Type" => "text/plain" ], [ "server1:" . $content ] ];
        });
    }
);

my $server2 = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(
            "--port" => $port,
            "--no-default-middleware",
            "--server" => "HTTP::Server::PSGI"
        );
        $runner->run(sub {
            pass("There was an access to server2");
            return [ 200, [ "Content-Type" => "text/plain" ], [ "server2:" . $content ] ];
        });
    }
);

my $geest = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $geest = Geest->new;
        $geest->add_master(server1 => (
            host => "127.0.0.1",
            port => $server1->port
        ));
        $geest->add_backend(server2 => (
            host => "127.0.0.1",
            port => $server2->port
        ));
        $geest->on(backend_finished => sub {
            my ($responses) = @_;
        });
        my $runner = Plack::Runner->new;
        $runner->parse_options(
            "--port" => $port,
            "--no-default-middleware",
            "--server" => "Twiggy"
        );
        $runner->run($geest->psgi_app);
    }
);

my $geest_port = $geest->port;
my $ua = LWP::UserAgent->new();
for (1..10) {
    my $res = $ua->get("http://127.0.0.1:$geest_port");
    is $res->decoded_content, "server1:$content", "received content from server1, not server2";
}


done_testing;