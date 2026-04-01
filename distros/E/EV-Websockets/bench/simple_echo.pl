use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';
use EV;
use EV::Websockets;
use Time::HiRes qw(time);

my $ctx = EV::Websockets::Context->new();
my %srv_conns;
my $port = $ctx->listen(
    port => 0,
    on_message => sub { $_[0]->send($_[1]) },
    on_connect => sub { $srv_conns{$_[0]} = $_[0] },
    on_close => sub { delete $srv_conns{$_[0]} },
);

my $start;
my $count = 0;

print "Connecting to port $port...\n";

$ctx->connect(
    url => "ws://127.0.0.1:$port",
    on_connect => sub {
        $start = time;
        $_[0]->send("ping");
    },
    on_message => sub {
        $count++;
        if (time - $start < 5) {
            $_[0]->send("ping");
        } else {
            $_[0]->close;
        }
    },
    on_close => sub {
        EV::break;
    }
);

EV::run;
my $elapsed = time - $start;
printf "Throughput: %.2f msg/sec (%d messages in %.2f seconds)\n", 
    $count / $elapsed, $count, $elapsed;
