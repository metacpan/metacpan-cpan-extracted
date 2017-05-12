BEGIN {
    unless ($ENV{RELEASE_TESTING} || $ENV{THREAD_TESTS}) {
        require Test::More;
        Test::More::plan(skip_all=>'these online tests require env variable ONLINE_TESTS be set to run');
    }
}

use strict;
use warnings;

use Test::More 'no_plan';

use LWPx::ParanoidAgent;
use IO::Socket;
use Data::Dumper;

use constant TIMEOUT    => 3;
use constant WAIT       => 4;

my ($server, $host, $port) = make_stuck_http_server();

my $start = time;
my $ua = LWPx::ParanoidAgent->new(timeout => TIMEOUT, whitelisted_hosts => [$host]);

print $ua->get("http://$host:$port/")->status_line(), "\n";
my $elapsed = time - $start;

ok(($elapsed) <= TIMEOUT(), 'testing timeout...');
warn "TOTAL ELAPSED: ", $elapsed, "\n";

$server->kill(15);

sub make_stuck_http_server {
    use threads;

    my $serv = IO::Socket::INET->new(Listen => 3)
        or die $@;

    my $thread = threads->create(sub {
        $SIG{TERM} = sub { threads->exit() };

        while (1) {
            my $client = $serv->accept()
                or next;

            my $buf;
            while (1) {
                $client->sysread($buf, 1024, length $buf)
                    or last;
                if (rindex($buf, "\015\012\015\012") != -1) {
                    last;
                }
            }

            $client->syswrite(
                join(
                    "\015\012",
                    "HTTP/1.1 200 OK",
                    "Connection: close",
                    "Content-Type: text/html",
                    "\015\012"
                )
            );

            for (1 .. WAIT()) {
                $client->syswrite(rand);
                select undef, undef, undef, 1;
            }

            $client->close();
        }

    });
    $thread->detach();

    return ($thread, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}