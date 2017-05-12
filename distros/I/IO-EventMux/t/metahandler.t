use strict;
use warnings;

use Test::More tests => 1;
use IO::EventMux;
use IO::Socket::INET;
use IO::Select;
use Socket;

# FIXME: Make into test

pass("Skipped for now");

exit;

my $mux = IO::EventMux->new();

my $listen = $mux->listen("udp://127.0.0.1:11048",
    MetaHandler => sub {
        my($fh, $data, $sender) = @_;
        return $fh.$sender;
    },
);

my $sock1 = $mux->connect("udp://127.0.0.1:11048");
my $sock2 = $mux->connect("udp://127.0.0.1:11048");

$mux->send($sock1, "Sock1-A");
$mux->send($sock1, "Sock1-B");
$mux->send($sock2, "Sock2-A");
$mux->send($sock2, "Sock2-B");

my $count = 4;
while(my $event = $mux->mux(5)) {

    die "Got timeout: $count" if $event->{type} eq 'timeout';

    next if $event->{type} ne 'read';

    my $session = $mux->meta($event->{id});

    if($session) {
        print Dumper($session);
    } else {
        print "setting new information\n";
        $mux->meta($event->{id}, { data => $event->{data} })
    }
    
    use Data::Dumper; print Dumper($event);
    
    exit if !--$count;
}

