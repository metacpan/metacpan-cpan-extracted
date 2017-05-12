package Distributed::Process::Master;

use warnings;
use strict;

=head1 NAME

Distributed::Process::Master - a class to conduct the chorus of D::P::Workers, under a D::P::Server.

=head1 SYNOPSIS

    use Distributed::Process::Master;
    use Distributed::Process::Server;

    use MyWorker; # subclass of Distributed::Process::Worker

    $m = new Distributed::Process::Master
	-in_handle    => \*STDIN,
	-out_handle   => \*STDOUT,
	-worker_class => 'MyWorker',
    ;
    $s = new Distributed::Process::Server
	-master => $m,
	-port   => 8147,
    ;
    $s->listen();

=head1 DESCRIPTION

A C<D::P::Server> manages a number of C<D::P::Interface> objects, one of which
is a C<Distributed::Process::Master>. The role of the Master is to handle
requests from the user, coming in on its in_handle() (usually, the standard
input), and act as an interface between the user and the
C<D::P::Worker> objects.

=cut

use Carp;
use Distributed::Process;
use Distributed::Process::Worker;
use Distributed::Process::RemoteWorker;

use threads;
use threads::shared;
use Thread::Semaphore;
use Thread::Queue;
use Distributed::Process::Interface;
our @ISA = qw/ Distributed::Process::Interface /;
@Distributed::Process::Worker::ISA = qw/ Distributed::Process::RemoteWorker /;

our $SELF;
sub new {

    my $self = shift;
    $SELF ||= $self->SUPER::new(@_);
    $SELF->_ignore_queue();
    $SELF;
}

=head2 Commands

A C<D::P::Master> object will react on the following commands received on its
in_handle().

=over 4

=item B</run>

Invokes the run() method (see below).

=item B</reset>

Invokes the reset_result() method on all the Worker objects.

=item B</freq> I<NUMBER>

Sets the frequency() to a new value

=item B</quit>

Invokes the quit() method on the C<P::D::Server>, effectively shutting down the
server and the clients.

=back

=cut

=head2 Methods

=over 4

=cut

sub _is_ready_to_run {

    my $self = shift;
    return unless $self->n_workers() <= $self->workers();
    foreach ( @{$self->{_workers}} ) {
        return unless $_->is_ready();
    }
    1;
}

=item B<add_worker> I<WORKER>

=item B<add_worker> I<LIST>

Adds a Worker to the list of known workers. If the first argument is a
C<D::P::Worker>, use this as the new worker. Otherwise, create a new instance
of class worker_class(), passing I<LIST> as arguments to the constructor.

In any case, the new worker will be passed the parameters defined by
worker_args().

Returns the new worker object.

=cut

sub add_worker {

    my $self = shift;
    my $worker = shift;
    DEBUG 'Adding a worker';
    if (!ref($worker) || !$worker->isa('Distributed::Process::Worker') ) {
	my $class = $self->worker_class();
	$worker = $class->new(-master => $self, $worker, @_);
    }
    else {
	$worker->master($self);
    }
    my %attr = $self->worker_args();
    while ( my ($meth, $value) = each %attr ) {
	$worker->$meth($value);
    }
    my $in_queue = new Thread::Queue;
    my $out_queue = new Thread::Queue;
    $worker->in_queue($out_queue);
    $worker->out_queue($in_queue);
    $worker->get_id();
    push @{$self->{_workers}}, $worker;
    INFO 'new worker arrived';
    $self->send('new worker arrived');
    return $worker;
}

sub _broadcast {

    my $self = shift;

    foreach ( @{$self->{_workers}} ) {
	$_->in_queue()->enqueue(@_);
    }
}

sub _queue_is_pending {

    my $self = shift;

    foreach ( @{$self->{_workers}} ) {
	return 1 if $_->out_queue()->pending();
    }
    return;
}

sub _read_queues {

    my $self = shift;

    foreach ( @{$self->{_workers}} ) {
	my $q = $_->out_queue();
	DEBUG "looking in queue from $_";
	if ( $q->pending() ) {
	    return ($_, $q->dequeue());
	}
    }
    return;
}

=item B<workers>

Returns the list of known C<P::D::Worker> objects. In scalar context, returns their number.

=cut

sub workers {

    my $self = shift;
    wantarray ? sort { $a->id() cmp $b->id() } @{$self->{_workers}} : scalar @{$self->{_workers}};
}

=item B<has_enough_workers>

Returns true when the number of connected workers is enough (i.e., greater than
or equal to n_workers()).

=cut

sub has_enough_workers {

    my $self = shift;

    $self->n_workers() <= $self->workers();
}

=item B<reset_result>

Broadcast a message to all workers to flush their results list.

=cut

sub reset_result {

    my $self = shift;
    $self->_broadcast('/reset');
}

=item B<synchro> I<TOKEN>

This method is invoked when a worker receives a C</synchro> command from its
connected client. It increments the counter associated with the I<TOKEN>, and
when this counter reaches the number of connected client (which means that all
the clients have reached the synchronisation point), the master lets the
workers send another C</synchro> message in reply to their clients, which can
go on with the rest of their task.

=cut

sub synchro {

    my $self = shift;
    my $token = shift;

    $self->{_synchro_counter}{$token} ||= 0;
    DEBUG "Synchro counter for $token is " . ($self->{_synchro_counter}{$token}+1);
    if ( ++$self->{_synchro_counter}{$token} == $self->n_workers() ) {
	$self->{_synchro_counter}{$token} = 0;
	sleep 1;
	$_->in_queue()->enqueue("/synchro $token") foreach $self->workers();
    }
}

=item B<delay> I<TOKEN>

This works much the same way as synchro().
This method is invoked when a worker receives a C</delay> command from its
connected client. It increments the counter associated with the I<TOKEN>, and
when this counter reaches the number of connected client (which means that all
the clients have reached the synchronisation point), the master lets the
workers send another C</delay> message in reply to their clients. However,
instead of sending these messages all at once, the master waits for some time
to elapse between each client call. This time is configurable with the C</freq>
command.

=cut

sub delay {

    my $self = shift;
    my $token = shift;

    $self->{_synchro_counter}{$token} ||= 0;

    if ( ++$self->{_synchro_counter}{$token} == $self->n_workers() ) {
	my $delay = 1 / ($self->frequency() || 1);
	$self->{_synchro_counter}{$token} = 0;
	my $thr = async {
	    foreach ( $self->workers() ) {
		DEBUG "sleeping for $delay seconds";
		select undef, undef, undef, $delay;
		$_->in_queue()->enqueue("/delay $token");
	    }
	};
	$thr->detach();
    }
}

=item B<result>

Returns the list of result() from the C<D::P::MasterWorker>. Subclasses can
overload this method to filter the results before they are sent to the user.

=cut

sub result {

    my $self = shift;

    INFO 'gathering results';
    map $_->result(), $self->workers();
}

=item B<run_done>

This method is called when a worker receives the C</run_done> command from its
connected client. It increments a counter, and when all clients have sent this
command, run_done() calls the result() method to gather the results from all
the clients and send them to the out_handle().

=cut

sub run_done {

    my $self = shift;
    return if ++$self->{_run_done} < $self->workers();
    DEBUG 'fetching the results';
    my @result = $self->result();
    DEBUG 'sending the results';
    $self->send(@result, 'ok');
}

=item B<run>

Broadcast a message to the workers to let them send a C</run> command to their
connected client.

=cut

sub run {

    my $self = shift;
    return unless $self->_is_ready_to_run();
    DEBUG 'Giving the go to the workers';
    $self->{_run_done} = 0;
    $self->_broadcast('/run');

}

sub _ignore_queue { shift->{_ignore_queue} = 1 }
sub _heed_queue { shift->{_ignore_queue} = 0 }
sub _is_ignoring_queue { shift->{_ignore_queue} }
sub _is_heeding_queue { !(shift->{_ignore_queue}) }

=item B<available_for_reading>

This method is called by the wait_for_pattern() method in
C<Distributed::Process::Interface> to check whether it should return or go on
waiting for lines to read on the in_handle(). available_for_reading() returns 1
when something is available on in_handle() (i.e., the user has typed a command
on the terminal), or 0 if a worker is sending a message. It blocks until one of
the two happens.

wait_for_pattern(), in turn will read the in_handle() if
available_for_reading() yielded 1, or return undef if it yielded 0.

=cut

sub available_for_reading {

    my $self = shift;

    return 1 if $self->_is_ignoring_queue();
    my $s = new IO::Select $self->in_handle();
    DEBUG "Waiting for a message";
    while ( 1 ) {
	DEBUG("Something ready to read on the network"), return 1 if $s->can_read($self->timeout() || .1);
	DEBUG("Incoming message from a worker"), return 0 if $self->_queue_is_pending();
    }
}

=item B<listen>

This method is called by the C<Distributed::Process::Server> when enough
clients are connected. It listens for commands typed by the user on the
terminal and, at the same time, to messages sent by the workers, and take
appropriate actions based on the command received.

=cut

sub listen {

    my $self = shift;

    my $h = $self->in_handle();

    $self->send('ready to run');

    $self->_heed_queue();
    while ( 1 ) {
	my @res = $self->wait_for_pattern(qr{^/\S+});

	if ( @res ) {
	    my ($command, @arg) = split /\s+/, $res[-1];
	    DEBUG "Received command $command";
	    for ( $command ) {
		/\brun/i and do {
		    $self->run();
		    last;
		};
		/\breset/i and do {
		    $self->reset_result();
		    last;
		};
		/\bfreq/i and do {
		    if ( @arg ) {
			$self->frequency($arg[0]);
		    }
		    else {
			$self->send($self->frequency());
		    }
		    last;
		};
		/\bquit/ and do {
		    $self->_broadcast('/quit');
		    sleep 1;
		    exit 0;
		};
	    }
	}
	else {
	    my ($worker, $msg) = $self->_read_queues();
	    DEBUG "Received message $msg";
	    ($msg, my @arg) = split /\s+/, $msg;
	    for ( $msg ) {
		/\bsynchro/ and do {
		    $self->synchro($arg[0]);
		    last;
		};
		/\bdelay/ and do {
		    $self->delay($arg[0]);
		    last;
		};
		/\brun_done/ and do {
		    $self->run_done();
		    last;
		};
	    }
	}
    }
}

=item B<worker_class> C<NAME>

=item B<worker_class>

Returns or sets the class to use when instanciating C<P::D::Worker> objects to
handle incoming connections.

When setting the worker_class(), this method will call the go_remote() method
on it to alter its inheritance, and make it a subclass of
C<Distributed::Process::RemoteWorker>.

=cut

sub worker_class {

    my $self = shift;
    my $old = $self->{_worker_class};
    if ( @_ ) {
	$self->{_worker_class} = $_[0];
	$_[0]->go_remote();
    }
    return $old;
}

=item B<worker_args> I<LIST>

=item B<worker_args> I<ARRAYREF>

=item B<worker_args>

The list of arguments to pass to the worker_class() constructor. If the first
argument is an array ref, it will be dereferenced.

Returns the former list of arguments or the current list when invoked without
arguments.

=cut

sub worker_args {

    my $self = shift;
    my @old = @{$self->{_worker_args} || []};
    if ( @_ ) {
	$self->{_worker_args} = ref($_[0]) eq 'ARRAY' ? $_[0] : [ @_ ]
    }
    return @old;
}

=back

=head2 Attributes

The following list describes the attributes of this class. They must only be
accessed through their accessors.  When called with an argument, the accessor
methods set their attribute's value to that argument and return its former
value. When called without arguments, they return the current value.

=over 4

=item B<n_workers>

The number of C<P::D::Worker> that are expected to connect on the server. When
enough connections are established, the Master will print a "ready to run"
message to warn the user.

=item B<frequency>

The frequency at which a method run by postpone() should be invoked, in Hz.

Suppose you want all the workers to run their __method() 0.25 seconds after one
another. You'd write your Worker run() method like this:

    sub run {
	my $self = shift;
	$self->postpone(__method => 'arguments to __method);
    }

You'd then set the Master's frequency() to 4, to have it launch 4 calls per
second, or 1 call every 0.25 second.

See L<Distributed::Process::Worker> for details.

=item B<id>

The unique ID for the Master, as a D::P::Interface is "C<master>".

=item B<timeout>

How often available_for_reading() will check for messages from the workers. The
rest of the time, it will wait for messages on in_handle(). The default is 0.1
seconds, meaning that available_for_reading() will check for messages from the
workers ten times per second.

=back

=cut

sub id { 'master' }

foreach my $method ( qw/ n_workers frequency timeout / ) {

    no strict 'refs';
    *$method = sub {
	my $self = shift;
	my $old = $self->{"_$method"};
	$self->{"_$method"} = $_[0] if @_;
	return $old;
    };
}

=head1 AUTHOR

Cédric Bouvier, C<< <cbouvi@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-distributed-process@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Distributed::Process::Master
