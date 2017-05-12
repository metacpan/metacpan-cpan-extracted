package Distributed::Process::Worker;

use warnings;
use strict;

use Distributed::Process;
use Distributed::Process::LocalWorker;
our @ISA = qw/ Distributed::Process::LocalWorker /;

=head1 NAME

Distributed::Process::Worker - a base class for a worker

=head1 SYNOPSIS

    package MyWorker;
    use Distributed::Process::Worker;
    our @ISA = qw/ Distributed::Process::Worker /;

    sub run {

	my $self = shift;

	# do useful stuff
    }

    1;

=head1 DESCRIPTION

The tasks that one wishes to run distributedly must be implemented in the run()
method of a class derived from C<Distributed::Process::Worker>. By default,
this in turn derives from C<Distributed::Process::LocalWorker>, so the custom
class also derives from it, and can run "as is" on the client side.

On the server side, the C<Distributed::Process::Master> object changes the
inheritance of C<Distributed::Process::Worker> to make it a subclass of
C<Distributed::Process::RemoteWorker>. The custom worker class thus also
becomes a subclass of it, and is ready to run on the server.

=head2 Methods

=over 4

=item B<go_remote>

This is called by the C<D::P::Master> object to change the inheritance and
redefind the run() method. run() on the server does not actually run the tasks
defined in the custom worker class, but sends a C</run> command on the netork
to the connected client.

=cut

sub go_remote {

    my $self = shift;
    require Distributed::Process::RemoteWorker;
    @ISA = qw/ Distributed::Process::RemoteWorker /;
    $self->SUPER::go_remote();
}

=back

=head1 SEE ALSO

L<Distributed::Process::LocalWorker>, L<Distributed::Process::RemoteWorker>,
L<Distributed::Process::Master>

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

1; # End of Distributed::Process::Worker
