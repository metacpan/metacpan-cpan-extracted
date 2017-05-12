# Objective:
# ----------
#
# This script will trigger the destructor of still 
# pending events and they should indeed be deleted and
# cleaned up.

use strict;
use warnings;

use IO::Socket;
use Event::Lib;
use Test;

BEGIN {
    plan tests => 6;
}

my $PATH = "t/sock-$$";

my $pid = fork;
die "couldn't fork: $!" unless defined $pid;

$SIG{PIPE} = 'IGNORE';

select STDERR;

unless ($pid) {
    # CHILD
    sleep 1;
    for my $try (1..2) {
	my $real_client = IO::Socket::UNIX->new(Peer => $PATH, Blocking  => 0)
            or die "child: Can't open $PATH: $@";
	$real_client->autoflush(1);
	
        for (1..3) {
            $real_client->syswrite("foobar");
            my $read = $real_client->sysread(my $buf, 1024);
        }
        $real_client->close;
        select undef, undef, undef, 0.5;
    }
    exit;
}
else {
    # PARENT
    my $sock = IO::Socket::UNIX->new(
                    Blocking  => 0,
		    Local     => $PATH,
                    Listen    => 1,
                ) or die "parent: Can't open $PATH: $@";

    $sock->listen() or die $!;

    my $ctx = { sock => $sock };

    my $e = event_new($sock, EV_READ|EV_PERSIST, \&handle_incoming, $ctx);
    $ctx->{incoming_event} = $e;
    $e->add;
    event_mainloop();
    wait;
}

sub handle_incoming {
    my ($e, $e_type, $ctx) = @_;

    $ctx->{fh}->close if exists $ctx->{fh};
    
    $ctx->{fh} = $ctx->{sock}->accept() or die $!;

    $ctx->{read_event}  = event_new($ctx->{fh}, EV_READ,  \&do_read,  $ctx);
    $ctx->{write_event} = event_new($ctx->{fh}, EV_WRITE, \&do_write, $ctx);

    $ctx->{read_event}->add;
}

my $ok = 0;
sub do_read {
    my ($e, $e_type, $ctx) = @_;
    my $read = sysread($ctx->{fh}, my $buf, 1024);
    if (defined $read) {
        if ($read) {
            $ok++;
            ok($buf, "foobar");
            $ctx->{write_event}->add;
            exit if $ok == 6;
        }
        else {
            return;
        }
    }
    else {
        return;
    }
}

sub do_write {
    my ($e, $e_type, $ctx) = @_;
    my $sent = syswrite($ctx->{fh}, "ok", 2, 0);
    unless (defined $sent) {
        return;
    }
    $ctx->{read_event}->add;
}

END {
    unlink $PATH;
}
