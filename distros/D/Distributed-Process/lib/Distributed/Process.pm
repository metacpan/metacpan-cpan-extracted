package Distributed::Process;

use strict;

=head1 NAME

Distributed::Process - a framework for running a process simultaneously on several
machines.

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';

=head1 SYNOPSIS

First, write a subclass of Distributed::Process::Worker that will implement the
tasks to be run remotely in its run() method.

    package MyWorker;
    use Distributed::Process;
    use Distributed::Process::Worker;

    sub run {
	my $self = shift;

	# do interesting stuff
	...

	# report about what happened
	$self->result("logs the results");
    }

Write a small server to pilot the workers:

    # Server
    use Distributed::Process;
    use Distributed::Process::Server;
    use Distributed::Process::Master;
    use MyWorker;

    $master = new Distributed::Process::Master 
	-in_handle => \*STDIN, -out_handle => \*STDOUT,
	-worker_class => 'MyWorker',
	-n_workers => 2;
    $server = new Distributed::Process::Server -port => 8147, -master => $master;

    $server->listen();

Write a small client as well that uses the custom worker class and install it
on all the client machines:

    # Client
    use Distributed::Process;
    use Distributed::Process::Client;
    use MyWorker;

    $client = new Distributed::Process::Client -worker_class => 'MyWorker',
	-host => 'the-server', -port => 8147;
    $client->run();

=head1 DESCRIPTION

This modules distribution provides a framework to run tasks simultaneously on
several computers, while centrally keeping control from another machine.

=head2 Architecture Overview

The tasks to run are implemented in a "worker" class, that derives from
C<D::P::Worker>; let's call it C<MyWorker>. The subclass must overload the
run() method that will be invoked from the server.

=head3 Server Side

On the server side, a C<D::P::Server> object will handle the network
connections, i.e. sockets. Each handle is associated with a
C<D::P::Interface> object. This object can be either be a C<D::P::Master>, or a
C<D::P::RemoteWorker>.

Instead of being bound to a network socket, the C<D::P::Master> object is
typically bound to the standard input and output, and can thus receive orders
from the user and give feedback on the terminal. It maintains a list of
C<D::P::RemoteWorker> objects, one for each network connection.

The C<D::P::RemoteWorker> objects implement the communication between the
server and the clients. Its inheritance is changed at run-time, so that it is a
subclass of the MyWorker class, and thus benefits from all the methods
implemented in the worker class.

When the C<D::P::Master> receives the C</run> command (on standard input), it
invokes the run() method on each of the C<D::P::RemoteWorker> objects, which in
turn will send a C</run> command to their connected client.

After the run() is over, the C<D::P::Master> broadcasts the
C</get_result> command and gathers the results from all C<D::P::RemoteWorker>
objects, and prints out the results.

=head3 Client Side

On the client side, a C<D::P::Client> object manages to connection to the
server and instanciates the C<MyWorker> class, derived from C<D::P::Worker>.

When the client receives the C</run> command from the server, it invokes the
run() method of the C<MyWorker> class. This method can in turn invoke methods
from C<D::P::LocalWorker> (which it derives from) to talk back to the server:

=over 4

=item B<synchro()>: enables all the workers to wait for all the others to reach
the same point in the execution of run() before proceeding.

=item B<delay()>: just like synchro(), but after the synchronization point is
reached, each worker will go on a short time after the previous worker. This
prevents all the workers to run a task exactly at once, but rather spreads the
work on a longer period of time.

=item B<run_on_server()>: let a method be run on the server, instead of the
client.

=item B<time()>: measures the time another method takes to complete and reports
it.

=item B<result()>: records a string as a "result". It will be sent back to the
server after the run is complete.

=back

=cut

use threads;
use Thread::Semaphore;
my $CAN_PRINT = new Thread::Semaphore;

our %DEBUG_FLAGS;

use Exporter;
our @ISA = qw/ Exporter /;

my %message_types = qw/
    DEBUG DBG
    INFO  INF
    WARN  WRN
    ERROR ERR
/;

our @EXPORT = keys %message_types;

=head2 Constructor

=over 4

=item B<new> I<LIST>

Although this class is not supposed to be instanciated, it provides a
constructor for its subclasses to inherit from. This constructor takes a
I<LIST> of named arguments. The names will be converted to lowercase and
stripped off from their leading hyphens, if any. The constructor then calls the
method by the same name with the value as argument. These calls are the same:

    $obj = new Distributed::Process  method => $value;
    $obj = new Distributed::Process -method => $value;
    $obj = new Distributed::Process -METHOD => $value;

    $obj = new Distributed::Process;
    $obj->method($value);

=cut
sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;
    while ( @_ ) {
	my ($attr, $value) = (lc shift, shift);
	$attr =~ s/^-+//;
	$self->$attr($value);
    }
    return $self;
}

=back

=head2 Exports

This module exports the DEBUG(), ERROR(), WARN() and INFO() functions that are no ops by default. If you
import the C<:debug>, C<:error>, C<:warn> and/or C<:info> special tags, the corresponding functions are turned into one that
prints its arguments to standard error.

You need importing the special tags only once for this to take effect. For exemple the
main program can say:

    use Distributed::Process qw/ :debug /;

While all the other modules just say:

    use Distributed::Process;

Still, the C<DEBUG> function will become active everywhere.

=head2 Functions

=over 4

=item B<DEBUG> I<LIST>

=item B<ERROR> I<LIST>

=item B<WARN> I<LIST>

=item B<INFO> I<LIST>

By default, these functions do nothing. However, if at some point the C<:debug>, C<:error>, C<:warn>, or C<:info>
tag were imported, these functions will print their arguments to standard error, prepended
with the Process ID, the fully qualified name of its caller, and the thread id,
e.g.:

    <DBG>3147:Package::function(1): message
    <ERR>3147:Package::function(1): message
    <WRN>3147:Package::function(1): message
    <INF>3147:Package::function(1): message

If the global variable $ID is declared in the main program, it will be used instead of the Process ID:

    our $ID = 'server';

    <DBG>server:Package::function(1): message
    <ERR>server:Package::function(1): message
    <WRN>server:Package::function(1): message
    <INF>server:Package::function(1): message

=cut

sub import {
    my $package = shift;
    my %arg = map { $_ => 1 } @_;
    foreach ( keys %message_types ) {
	my $type = $message_types{$_};
	$DEBUG_FLAGS{$_} = 1 if delete $arg{"\L:$_"};
	no strict 'refs';
	no warnings 'redefine';
	*$_ = $DEBUG_FLAGS{$_}
	? sub {
	    my $sub = (caller(1))[3];
	    my $tid = threads->self()->tid();
	    my $pid = $main::ID || $$;
	    $CAN_PRINT->down();
	    print STDERR "<$type>$pid: $sub($tid): @_\n";
	    $CAN_PRINT->up();
	}
	: sub {};
    }
    @_ = ($package, keys %arg);
    goto &Exporter::import;
}

=back

=head1 AUTHOR

Cédric Bouvier, C<< <cbouvi@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-distributed-process@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Distributed::Process
