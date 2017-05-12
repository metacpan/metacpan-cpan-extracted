use strict;
use warnings;

use Test::More tests => 1;
use Socket;
use IO::EventMux;
use Carp;

socketpair(my $reader, my $writer, AF_UNIX, SOCK_STREAM, PF_UNSPEC);

my $pid = fork;
if($pid == 0) {
    close $writer;
    sleep 10;
    exit;
}
close $reader;
        
my $mux = new IO::EventMux();

eval { $mux->send($writer, "Hello2"); };
ok($@ =~ /send\(\) on filehandle not handled by IO::Eventmux/,
    "Fail on sending to filehandle before we add it");

$mux->nonblock($writer);

# Fill up buffer
my $rv = syswrite($writer, "x" x (1024 * 1024));
eval {
    syswrite($writer, "x" x (1024 * 1024));
    croak $!;
};

print "errorstate:$rv, $!, $@\n";

kill 1, $pid;
waitpid($pid, 0);
exit;


while(my $event = $mux->mux(1)) {
    print "$event->{type}\n";
    if($event->{type} eq 'ready') {
        $mux->send($writer, "x" x 80000);
    }
    $mux->send($writer, "x" x (1024 * 1024));
}
