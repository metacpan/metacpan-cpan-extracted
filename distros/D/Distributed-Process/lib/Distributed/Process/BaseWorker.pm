package Distributed::Process::BaseWorker;

use warnings;
use strict;

=head1 NAME

Distributed::Process::BaseWorker - base class for all workers, both local and
remote

=head1 SYNOPSIS

=cut

use Distributed::Process;
our @ISA = qw/ Distributed::Process /;

=head1 DESCRIPTION

=head2 Methods

None of these methods is actually implemented in this base class. They're all
implemented either in Distributed::Process::LocalWorker, or in
Distributed::Process::RemoteWorker.

Methods in Distributed::Process::LocalWorker will usually simply send a command
to their RemoteWorker counterpart, asking it to perform some action on the
server side.

Methods in Distributed::Process::RemoteWorker will perform the actions
requested by the clients and possibly give a reply back.

=over 4

=item B<synchro> I<TOKEN>

Waits for all the connected clients to reach this synchronisation point.
I<TOKEN> is an identifier, used to identify which synchronisation point is
being reached.

=cut

sub synchro {}

=item B<run>

This must must be overloaded in subclasses to actually implement the task that
is to be run remotely. 

=cut

sub run {}

=item B<delay> I<TOKEN>

Just like synchro(), waits for all the connected clients to reach this point.
But each client will be notified after a configurable amount of time. This
allows the server to let the clients proceed within an interval from each
other. See L<Distributed::Process::Master> for details.

=cut

sub delay {}

=item B<time> I<NAME>, I<LIST>

Runs the method I<NAME> with the given I<LIST> of arguments and reports the
time it took by means of the result() method.

=cut

sub time {

    my $self = shift;
    my $method = shift;

    $self->$method(@_);
}

=item B<reset_result>

Flushes the results from memory. This should be called between two calls to
run() so that the results from the second run are not appended to those of the
first.

=cut

sub reset_result {}

=item B<result> I<STRING>

=item B<result>

When called with an argument, adds the I<STRING> to the queue of messages to
send back to the server.

When called without arguments, returns the list of queued messages.

=cut

sub result {}

=back

=head1 SEE ALSO

L<Distributed::Process::LocalWorker>,
L<Distributed::Process::MasterWorker>,
L<Distributed::Process::RemoteWorker>,
L<Distributed::Process::Worker>.

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

1; # End of Distributed::Process::BaseWorker
