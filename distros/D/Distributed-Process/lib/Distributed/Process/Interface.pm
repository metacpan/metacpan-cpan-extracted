package Distributed::Process::Interface;

use warnings;
use strict;

=head1 NAME

Distributed::Process::Interface - a base class for handling a network
connection and the commands received from it.

=head1 DESCRIPTION

=cut

use IO::Socket;
use Socket qw/ :crlf /;
use Distributed::Process;
import Distributed::Process;
our @ISA = qw/ Distributed::Process /;

=head2 Methods

=over 4

=cut

sub handle {
    goto &in_handle;
}

=item B<wait_for_pattern> I<REGEX>

Reads lines on the connection in_handle() until the line matches I<REGEX>.
Returns the list of all the read lines, including the one that matched.

=cut

sub wait_for_pattern {

    my $self = shift;
    my $pattern = shift;
    my $fh = $self->in_handle();
    local $/ = CRLF;
    my @res = ();
    DEBUG "waiting for $pattern";
    local $_;
    while ( $self->available_for_reading() && defined($_ = <$fh>) ) {
        chomp;
	DEBUG "received line '$_'";
        push @res, $_;
        next unless /$pattern/;
        return @res;
    }
    return;
}

=item B<available_for_reading>

This method is invoked by wait_for_pattern() before reading a line on
in_handle(), to decide whether to stop waiting for a given pattern. If
available_for_reading() returns true, wait_for_pattern() will go on waiting for
lines to flow in; if it yields false, wait_for_pattern() will return C<undef>.

By default, available_for_reading() always returns C<1>, which means that
wait_for_pattern() indefinitely reads lines from in_handle() until one of them
matches the given pattern. Subclasses can overload available_for_reading() to
return C<0> should something different occur.

=cut

sub available_for_reading { 1 }

=item B<send> I<LIST>

Prints each string in I<LIST> with a CR+LF sequence to the output stream.

=cut

sub send {

    my $self = shift;

    foreach ( @_ ) {
        DEBUG "sending '$_'";
        print { $self->out_handle() } $_ . CRLF;
    }
}

=back

=head2 Attributes

The following list describes the attributes of this class. They must only be
accessed through their accessors.  When called with an argument, the accessor
methods set their attribute's value to that argument and return its former
value. When called without arguments, they return the current value.

=over 4

=item B<server>

The C<P::D::Server> under which the Interface is running.

=item B<id>

A unique identifier for the interface.

=item B<handle>

=item B<in_handle>

The C<IO::Handle> object that represents the input stream.

=item B<out_handle>

The C<IO::Handle> object that represents the output stream.

=back

=cut

foreach my $method ( qw/ _queue id server in_handle out_handle / ) {

    no strict 'refs';
    *$method = sub {
	my $self = shift;
	my $old = $self->{"_$method"};
	$self->{"_$method"} = $_[0] if @_;
	return $old;
    };
}

=head1 SEE ALSO

L<Distributed::Process::Server>,
L<Distributed::Process::Client>,
L<Distributed::Process::Master>,
L<Distributed::Process::RemoteWorker>

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

1; # End of Distributed::Process::Interface
