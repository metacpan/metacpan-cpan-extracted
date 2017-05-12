# Check that undeffing a pending event wont remove it from the event queue. It
# should remain scheduled. But then also check that this 'dangling' event 
# is properly cleaned up.

package MyEvent;
use Event::Lib;
use base qw/Event::Lib::event/;

our @DESTROYS;

sub new {
    my $class = shift;
    bless event_new(@_) => $class;
}

{
    my $count = 0;
    sub DESTROY {
	my $self = shift;
	push @DESTROYS, ++$count;
	no warnings 'misc';
	$self->SUPER::DESTROY;
    }
}

package MyTimer;
use Event::Lib;
use base qw/Event::Lib::timer/;

our @DESTROYS;

sub new {
    my $class = shift;
    bless timer_new(@_) => $class;
}

{
    my $count = 0;
    sub DESTROY {
	my $self = shift;
	push @DESTROYS, ++$count;
	no warnings 'misc';
	$self->SUPER::DESTROY;
    }
}
    
package MySignal;
use Event::Lib;
use base qw/Event::Lib::signal/;

our @DESTROYS;

sub new {
    my $class = shift;
    bless signal_new(@_) => $class;
}

{
    my $count = 0;
    sub DESTROY {
	my $self = shift;
	push @DESTROYS, ++$count;
	no warnings 'misc';
	$self->SUPER::DESTROY;
    }
}

package main;

use IO::Socket::UNIX;
use Event::Lib;
use Test;
use POSIX qw/SIGHUP/;

BEGIN { plan tests => 4 + 3 + 3};

{   # fh-event
    my $PATH = "t/sock-$$";
    if (fork) {
	# PARENT
	my $sock = IO::Socket::UNIX->new(
	    Local => $PATH,
	    Listen => 1,
	) or die "$@";
	$sock->listen or die $!;
	
	my $e = MyEvent->new($sock, EV_READ, sub { ok(my $h = shift->fh->accept); ok(1); $h->close; });
	$e->add;
	undef $e;
	
	ok($MyEvent::DESTROYS[0], 1);
	event_mainloop;
	ok($MyEvent::DESTROYS[1], 2);

	unlink $PATH;
	wait;
    } else { 
	# CHILD
	sleep 2;
	my $real_client = IO::Socket::UNIX->new(Peer => $PATH) or die $@;
	$real_client->close;
	exit;
    }
}

{   # timer-event
    my $e = MyTimer->new(sub { ok(1); });
    $e->add(1);
    undef $e;   

    ok($MyTimer::DESTROYS[0], 1);
    event_mainloop;
    ok($MyTimer::DESTROYS[1], 2);
}

{   # signal-event
    if (my $pid = fork) {
	sleep 1;
	kill SIGHUP => $pid;
	wait;
    } else {
	# CHILD
	my $e = MySignal->new(SIGHUP, sub { ok(1); shift->remove; });
	$e->add;
	undef $e;   

	ok($MyTimer::DESTROYS[0], 1);
	event_mainloop;
	ok($MyTimer::DESTROYS[1], 2);
	exit;
    }
}
