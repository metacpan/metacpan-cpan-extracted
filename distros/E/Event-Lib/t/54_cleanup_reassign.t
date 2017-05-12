# Check that reassigning to a pending event wont remove it from the event queue. It
# should remain scheduled. But then also check that this 'dangling' event is 
# properly cleaned up.

package MyEvent;
use Event::Lib;
use base qw/Event::Lib::event/;
use warnings;

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
use POSIX qw/SIGHUP SIGUSR1/;

BEGIN { plan tests => 5 + 4 + 4};

{   # fh-event
    my $PATH1 = "t/sock1-$$";
    my $PATH2 = "t/sock2-$$";
    if (fork) {
	# PARENT
	my $sock1 = IO::Socket::UNIX->new(
	    Local => $PATH1,
	    Listen => 1,
	) or die "$@";
	$sock1->listen or die $!;
	my $sock2 = IO::Socket::UNIX->new(
	    Local => $PATH2,
	    Listen => 1,
	) or die "$@";
	$sock2->listen or die $!;

	open my $me, $0 or die $!;
	my $e = MyEvent->new($sock1, EV_READ, sub { ok(my $h = shift->fh->accept); $h->close; });
	$e->add;
	ok($e->pending);
	$e = MyEvent->new($sock2, EV_READ, sub { ok(my $h = shift->fh->accept); $h->close; });
	$e->add;

	ok($MyEvent::DESTROYS[0], 1);
	event_mainloop;
	ok($MyEvent::DESTROYS[1], 2);

	unlink $_ for $PATH1, $PATH2;
	wait;
    } else { 
	# CHILD
	sleep 2;
	my $real_client1 = IO::Socket::UNIX->new(Peer => $PATH1) or die $@;
	sleep 1;
	my $real_client2 = IO::Socket::UNIX->new(Peer => $PATH2) or die $@;
	$_->close for $real_client1, $real_client2;
	exit;
    }
}

{   # timer-event
    my $e = MyTimer->new(sub { ok(1); });
    $e->add(1);
    $e = MyTimer->new(sub { ok(1); });
    $e->add(2);

    ok($MyTimer::DESTROYS[0], 1);
    event_mainloop;
    ok($MyTimer::DESTROYS[1], 2);
}

{   # signal-event
    if (my $pid = fork) {
	sleep 1;
	kill SIGHUP	=> $pid;
	kill SIGUSR1	=> $pid;
	wait;
    } else {
	# CHILD
	my $e = MySignal->new(SIGHUP, sub { ok(1); shift->remove; });
	$e->add;
	$e = MySignal->new(SIGUSR1, sub { ok(1); shift->remove; });
	$e->add;

	ok($MyTimer::DESTROYS[0], 1);
	event_mainloop;
	ok($MyTimer::DESTROYS[1], 2);
	exit;
    }
}
