package Distributed::Process::Server;

use warnings;
use strict;

=head1 NAME

Distributed::Process::Server - a class to run the server of a Distributed::Process
cluster.

=cut

use Socket qw/ :crlf /;
use IO::Socket;
use IO::Select;

use Distributed::Process;
our @ISA = qw/ Distributed::Process /;

use Distributed::Process::Worker;

=head1 SYNOPSIS

    use Distributed::Process;
    use Distributed::Process::Master;
    use Distributed::Process::Server;
    use MyTest;

    $m = new Distributed::Process::Master ... ;
    $s = new Distributed::Process::Server -master => $m, -port => 8147;

    $s->listen();

=head1 DESCRIPTION

This class handles the server part of the cluster.

It maintains an internal list of Interface objects, one of which is the Master.
The Master object must be instanciated and declared with the Server before the
listen() method is invoked.

The listen() method will welcome incoming connections and declare them with the
Master as new Workers. Commands received on theses sockets will be handled by
the handle_line() method of the corresponding Interface, be it a Worker or the
Master.

=head2 Methods

=over 4

=item B<listen>

Starts listening on port(), waiting for incoming connections. If a new
connection is made, it is supposed to be from a Worker, and the handle is thus
passed on to the Master, by means of its add_worker() method.

When the master has_enough_workers(), the Server stops welcoming new
connections and launches the Master's listen() method.

=cut

sub listen {

    my $self = shift;

    my $lsn = new IO::Socket::INET ReuseAddr => 1, Listen => 1, LocalPort => $self->port();
    die $! unless $lsn;

    my $master = $self->master();
    while ( 1 ) {
	my $client = $lsn->accept();
	$client->autoflush(1);
	$master->add_worker(-server => $self, -handle => $client)->run();
	last if $master->has_enough_workers();
    }
    $master->listen();
}

=item B<master> I<MASTER>

=item B<master>

Sets or returns the current Distributed::Process::Master object for this server,
and adds it to the list of interfaces.

=cut
sub master {

    my $self = shift;
    my $old = $self->{_master};

    if ( @_ ) {
	my $master = $_[0];
	$self->{_master} = $master;
	$master->server($self);
    }
    return $old;
}

=back

=head2 Attributes

The following list describes the attributes of this class. They must only be
accessed through their accessors.  When called with an argument, the accessor
methods set their attribute's value to that argument and return its former
value. When called without arguments, they return the current value.

=over 4

=item B<port>

The port on which the server listens to incoming connections.

=cut

foreach my $method ( qw/ port / ) {

    no strict 'refs';
    *$method = sub {
	my $self = shift;
	my $old = $self->{"_$method"};
	$self->{"_$method"} = $_[0] if @_;
	return $old;
    };
}

=back

=head1 SEE ALSO

L<Distributed::Process::Interface>,
L<Distributed::Process::Master>,

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

1; # End of Distributed::Process::Server
