package Distributed::Process::LocalWorker;

use warnings;
use strict;

=head1 NAME

Distributed::Process::LocalWorker - a base class for Distributed::Process::Worker when running on the client side.

=head1 DESCRIPTION

This class implements the methods declared in C<D::P::BaseWorker> as they
should work on the client side.

=cut

use POSIX qw/ strftime /;

use Time::HiRes qw/ gettimeofday tv_interval /;

use Distributed::Process;
use Distributed::Process::BaseWorker;
our @ISA = qw/ Distributed::Process::BaseWorker /;

=head2 Methods

=over 4

=item B<time> I<NAME>, I<LIST>

Runs the method I<NAME> with I<LIST> as arguments, while measuring its run
time. Returns whatever the I<NAME> method returns and appends to the result() a
string of the form:

    Time for running NAME: n.nnnnn seconds

=cut

sub time {

    my $self = shift;
    my $method = shift;

    my $t0 = [ gettimeofday ];
    my @result = ($self->$method(@_));
    my $elapsed = tv_interval $t0;
    $self->result(sprintf "Time for running $method: %.5f seconds", $elapsed);
    @result;
}

=item B<reset_result>

Empties the stack of results.

=cut

sub reset_result {

    my $self = shift;
    $self->{_result} = [];
}

=item B<result> I<LIST>

=item B<result>

When called with a non-empty I<LIST> of arguments, pushes I<LIST> onto the
stack of results. These results are meant to be sent back when the server
requests them. Each line in I<LIST> is first prepended with a timestamp of the
form C<YYYYMMDD-HHMMSS>).

When called without any arguments, returns the list of results.

=cut

sub result {

    my $self = shift;

    if ( @_ ) {
	INFO "adding '@_' to results";
        my $first = shift @_;
        my $time = strftime "%Y%m%d-%H%M%S", localtime;
	#push @{$self->{_result}}, "$time\t$first", @_;
        #$RESULT_QUEUE->enqueue("$time\t$first", @_);
        push @{$self->{_result}}, "$time\t$first", @_;
	return;
    }
    else {
	INFO "returning results";
        return @{$self->{_result} || []};
    }
}

=item B<synchro> I<TOKEN>

Sends the command C</synchro TOKEN> to the server and waits until the server
replies with the same C</synchro> command before returning. The server should
reply only when all the connected clients have sent the same C</synchro>
command. I<TOKEN> is only a identification string, mainly useful for logging
purposes.

=cut

sub synchro {

    my $self = shift;
    my $token = shift;

    $self->client()->send("/synchro $token");
    $self->client()->wait_for_pattern(qr{^/synchro});
}

=item B<delay> I<TOKEN>

This works much the same way as synchro() but the server replies to each client
one after the other, and waiting for some (configurable) time between each one.
See L<Distributed::Process::Master> for details.

=cut

sub delay {

    my $self = shift;
    my $token = shift;

    $self->client()->send("/delay $token");
    $self->client()->wait_for_pattern(qr{^/delay});
}

=item B<run_on_server> I<NAME>, I<LIST>

Sends a C</run_method> command to let the server invoke the method named
C<NAME> with I<LIST> as argument on its instance of the worker. This instance,
running on the server, has its inheritance dynamically changed, so that it
derives from C<D::P::RemoteWorker> instead of C<D::P::LocalWorker>. Besides
this, all its methods are available.

When developping a subclass to C<D::P::Worker>, one should probably create
methods that run on the client and methods that run on the server. It is
unlikely to need to run one of the methods on both the server side and the
client side.

=cut

sub run_on_server {

    my $self = shift;
    my $method = shift;

    $self->client()->send("/run_method $method @_");
    $self->client()->wait_for_pattern(qr{^/begin_method_result});
    my @res = $self->client()->wait_for_pattern(qr{^ok});
    pop @res;
    INFO "Returned from server: @res";
    wantarray ? @res : $res[0];
}

=back

=head2 Attributes

The following list describes the attributes of this class. They must only be
accessed through their accessors.  When called with an argument, the accessor
methods set their attribute's value to that argument and return its former
value. When called without arguments, they return the current value.

=over 4

=item B<client>

The C<D::P::Client> object which handles the network connection for this worker.

=cut

foreach my $method ( qw/ client / ) {
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

L<Distributed::Process::BaseWorker>,
L<Distributed::Process::RemoteWorker>,
L<Distributed::Process::Worker>

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

1; # End of Distributed::Process::LocalWorker
