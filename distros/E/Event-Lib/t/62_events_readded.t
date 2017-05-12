# A read-event added via a timer-event.  Both events are furthermore kept in
# members of the object so they are created only once and readded accordingly

package A;

use Test; 
use Event::Lib;
use constant DELAY => 0.5;

BEGIN {
    plan tests => 10;
}
    
sub trigger {
    my ($event, $e_type, $self) = @_;
    ok(1);
    $self->reader->add;
    $self->count( $self->count - 1);
    if ($self->count) {
	$event->add(DELAY);
    }
}

sub read_one_byte {
    my $event = shift;
    read($event->fh, my $char, 1);
    ok($char, 'a');
}
    
sub new {
    my ($class, $fh, $iters) = @_;
    my $self = bless {
	_count  => undef,
	_timer	=> undef,
	_reader => undef,
    } => shift;
    $self->timer( timer_new(\&trigger, $self) );
    $self->reader( event_new($fh, EV_READ, \&read_one_byte) );
    $self->count( $iters );
    return $self;
}

sub run {
    my $self = shift;
    $self->timer->add(DELAY);
    event_mainloop;
}

sub count {
    my $self = shift;
    $self->{_count} = shift if @_;
    return $self->{_count};
}

sub timer {
    my $self = shift;
    $self->{_timer} = shift if @_;
    return $self->{_timer};
}

sub reader {
    my $self = shift;
    $self->{_reader} = shift if @_;
    return $self->{_reader};
}

package main;

use Event::Lib;
use IO::Socket;

use constant CHARACTER_COUNT => 5;

my $PATH = "t/sock-$$";

unless (fork) {
    sleep 1;
    my $client = IO::Socket::UNIX->new(Peer => $PATH) or die $@;
    $client->autoflush(1);
    $client->write('a') for 1 .. CHARACTER_COUNT;
} else {
    my $server = IO::Socket::UNIX->new(
	    Local => $PATH,
	    Listen => 1,
    ) or die $@;
    $server->listen or die $!;
    my $client = $server->accept;
    my $proxy = A->new($client, CHARACTER_COUNT)->run;
    $client->close;
    unlink $PATH;
    wait;
}
    

