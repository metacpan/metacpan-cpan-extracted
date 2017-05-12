# Objective:
# ----------
#
# Simply run and don't segfault.
# Previously events hidden in objects
# passed as additional arguments caused
# event-suicide.

use strict;
use warnings;

use IO::Socket;
use Event::Lib;
use Test;

BEGIN {
    plan tests => 8;
}

my $PATH = "t/sock-$$";

my $pid = fork;
die "couldn't fork: $!" unless defined $pid;

select STDERR;

unless ($pid) {
    # CHILD
    sleep 1;
    for my $try (1..2) {
	my $real_client = IO::Socket::UNIX->new(Peer => $PATH) or die $@;
	$real_client->autoflush(1);
	
        for (1..2) {
            $real_client->syswrite("foobar");
            my $read = $real_client->sysread(my $buf, 1024);
            select undef, undef, undef, 0.5;
        }
        $real_client->syswrite("done", 4, 0);
	select undef, undef, undef, 0.5;
    }
    exit;
}
else {
    # PARENT
    my $sock = IO::Socket::UNIX->new(
		    Local     => $PATH,
                    Listen    => 1,
                ) or die "$!";

    $sock->listen() or die $!;

    my $ctx = { sock => $sock };

    my $e = event_new($sock, EV_READ|EV_PERSIST, \&handle_incoming, $ctx);
    $ctx->{incoming_event} = $e;
    $e->add;
    event_register_except_handler(\&event_exception_handler);
    event_mainloop();
    wait;
}

sub handle_incoming {
    my ($e, $e_type, $ctx) = @_;

    $ctx->{fh} = $ctx->{sock}->accept() or die $!;
    $ctx->{read_event}  = event_new($ctx->{fh}, EV_READ,  \&do_read,  $ctx);
    $ctx->{write_event} = event_new($ctx->{fh}, EV_WRITE, \&do_write, $ctx);

    $ctx->{read_event}->add;
}

sub do_read {
    my ($e, $e_type, $ctx) = @_;
    my $read = sysread($ctx->{fh}, my $buf, 1024);
    if ($buf eq 'done') {
	ok(1);
        die "please no more!";
    }
    else {
	ok($buf, "foobar");
        $ctx->{write_event}->add;
    }
}

sub do_write {
    my ($e, $e_type, $ctx) = @_;
    my $sent = syswrite($ctx->{fh}, "ok", 2, 0);
    $ctx->{read_event}->add;
}

my $cnt = 0;
sub event_exception_handler {
    my ($e, $err, $e_type, $ctx) = @_;
    $cnt++;
    ok($err =~ /please no more! at/);
    if ($cnt == 2) {
	unlink $PATH or die $!;
	exit;
    }
}
