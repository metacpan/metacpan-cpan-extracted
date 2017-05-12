package Distributed::Process::Client;

use warnings;
use strict;

=head1 NAME

Distributed::Process::Client - a class to run a client in a Distributed::Process cluster.

=cut

use Carp;
use Socket qw/ :crlf /;
use IO::Socket;
use Distributed::Process;
use Distributed::Process::Interface;
our @ISA = qw/ Distributed::Process::Interface /;

=head1 SYNOPSIS

    use Distributed::Process;
    use Distributed::Process::Client;
    use MyTest;

    $c = new Distributed::Process::Client
	-id           => 'client1',
	-worker_class => 'MyTest',
	-port         => 8147,
	-host         => 'localhost',
    ;
    $c->run();

=head1 DESCRIPTION

This class handles the client part of the cluster. It derives its handling of
the network connection from C<Distributed::Process::Interface>.

A C<D::P::Worker> object must be associated to the Client, by means of the
worker() or worker_class() methods, so that the client can run methods from it
when requested to do so by the server.

=head2 Commands

A C<D::P::Client> object will react on the following commands received on its
in_handle().

=over 4

=item B</run>

Calls the worker's run() method. This is method should be overloaded by
subclasses of C<D::P::Worker> to perform the real job that is to be distributed
on the cluster.

=item B</reset>

Calls the worker's reset_result() method to flush its list of results.

=item B</quit>

Exits the program.

=item B</get_result>

Returns the results from the worker. The results are preceeded with the line
C</begin_results> and followed by the word C<ok>. Each result line gets
prefixed with the client's id() and a tab character ("C<\t>", ASCII 0x09).

The worker itself returns its result line prefixed with a timestamp. An example
of output could thus be:

    /begin_results
    client1	20050316-152519	Running method test1
    client1	20050316-152522	Time for running test1: 2.1234 seconds
    ok

=back

=head2 Methods

=over 4

=cut

=item B<run>

Reads line coming in from handle() and processes them.

Each line is first C<chomp>ed and C<split> on whitespace, and an action is
performed depending on the first word on the line. See the list of known
commands above.

=cut

sub run {

    my $self = shift;
    DEBUG 'connecting';
    my $h = $self->handle();
    local $/ = CRLF;
    $self->send("/worker " . $self->id());
    while ( 1 ) {
	no warnings qw/ uninitialized /;
        my ($command, @arg) = split /\s+/, ($self->wait_for_pattern(qr{^/run|quit|reset|get_result}))[-1];
	exit 1 unless $command;

	no warnings qw/ uninitialized /;
        for ( $command ) {
            /run/ and do {
                $self->worker()->run();
                $self->send('/run_done');
                last;
            };
            /quit/ and exit 0;
            /reset/ and do {
                $self->worker()->reset_result();
                last;
            };
            /get_result/ and do {
                my $id = $self->id();
                $self->send('/begin_results');
                $self->send("$id\t$_") foreach $self->worker()->result();
                $self->send('ok');
            };
        }
    }
}

=item B<handle>

=item B<in_handle>

=item B<out_handle>

These three are synonyms for the handle() method that returns the
C<IO::Socket::INET> object implementing the connection to the server.

The first call to handle() creates this object, effectively establishing the
connection to port port() on host host().

=cut

sub handle {

    my $self = shift;

    return $self->{_handle} if $self->{_handle};
    $self->{_handle} = new IO::Socket::INET
	PeerAddr => $self->host(),
	PeerPort => $self->port(),
	Proto    => 'tcp',
	    or croak "Cannot connect to server: $!";
    $self->{_handle}->autoflush(1);
    $self->{_handle};
}

*in_handle = *out_handle = *handle;

=item B<worker> I<OBJECT>

=item B<worker>

Sets or returns the current worker object. I<OBJECT> should be an instance of
C<Distributed::Process::Worker> or, most probably, of a subclass of it. If
I<OBJECT> is not provided, the fist call to worker() will instanciate an object
of the class returned by worker_class(), passing to its constructor the
arguments returned by worker_args().

=cut

sub worker {
    
    my $self = shift;

    if ( @_ ) {
	$self->{_worker} = $_[0];
	$self->{_worker}->client($self);
    }
    else {
	$self->{_worker} ||= do {
	    my $class = $self->worker_class();
	    $class->new($self->worker_args(), -client => $self);
	};
    }
    $self->{_worker};
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

=item B<id>

A unique identifier for the client. This will be prepended to the lines sent
back to the server as a response to the C</get_result> command. The process id
(C<$$>) is returned if id() is not set.

=item B<worker_class>

The name of the class to use when instanciating a C<D::P::Worker> object.

=item B<host>

=item B<port>

The host and port where to connect to the server.

=back

=cut

sub id {

    my $self = shift;
    my $old = defined($self->{_id}) ? $self->{_id} : $$;
    $self->{_id} = $_[0] if @_;
    return $old;
}

foreach my $method ( qw/ worker_class host port / ) {
    no strict 'refs';
    *$method = sub {
	my $self = shift;
	my $old = $self->{"_$method"};
	$self->{"_$method"} = $_[0] if @_;
	return $old;
    };
}

=head1 SEE ALSO

L<Distributed::Process::Interface>,
L<Distributed::Process::Worker>,

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

1; # End of Distributed::Process::Client
