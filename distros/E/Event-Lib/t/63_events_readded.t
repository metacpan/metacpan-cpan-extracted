# A read event kept in a member of an object and readded accordingly.  This
# test is essentially the same as t/62 only that the read-event is added
# directly and not via a timer event.

package A;

use Test; 
use Event::Lib;
use constant DELAY => 0.5;

BEGIN {
    plan tests => 5;
}
   
sub read_one_byte {
    my ($event, undef, $self) = @_;
    read($self->fh, my $char, 1);
    ok($char, 'a');
    $self->count( $self->count - 1);
    if ($self->count) {
	$self->my_event_add(EV_READ, \&read_one_byte, $self->reader);
    }
}
    
sub new {
    my ($class, $fh, $iters) = @_;
    my $self = bless {
	_count  => undef,
	_reader => undef,
	_fh	=> $fh,
    } => shift;
    $self->reader( event_new($self->fh, EV_READ, \&read_one_byte, $self) );
    $self->count( $iters );
    return $self;
}

sub my_event_add {
    my ($self, $e_type, $e_cb, $e) = @_;
    $e->add;
}

sub run {
    my $self = shift;
    $self->my_event_add(EV_READ, \&read_one_byte, $self->reader);
    event_mainloop;
}

sub count {
    my $self = shift;
    $self->{_count} = shift if @_;
    return $self->{_count};
}

sub fh {
    my $self = shift;
    $self->{_fh} = shift if @_;
    return $self->{_fh};
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
    

