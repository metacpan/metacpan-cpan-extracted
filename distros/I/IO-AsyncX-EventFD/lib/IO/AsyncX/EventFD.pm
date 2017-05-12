package IO::AsyncX::EventFD 0.001;
# ABSTRACT: Linux eventfd support for IO::Async

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

IO::AsyncX::EventFD - simple eventfd notifications

=head1 SYNOPSIS

 #!/usr/bin/env perl
 use strict;
 use warnings;
 
 use IO::Async::Loop;
 use IO::AsyncX::EventFD;
 
 my $loop = IO::Async::Loop->new;
 $loop->add(my $eventfd = IO::AsyncX::EventFD->new(notify => sub {
 	warn "Had event\n"
 }));
 $loop->loop_once(0.001);
 warn "Notifying...\n";
 $eventfd->notify;
 $loop->loop_once(0.001);

=head1 DESCRIPTION

Provides a very thin layer over L<Linux::FD::Event>.

=cut

use IO::Async::Handle;
use Linux::FD;
use curry::weak;

use mro;

=head1 METHODS

=head2 notify

Sends a notification to the event FD. This consists of a call to
L<Linux::FD::Event/add> with the value 1.

=cut

sub notify {
	my ($self) = @_;
	$self->handle->read_handle->add(1);
	$self
}

=head2 eventfd

Returns the L<Linux::FD::Event> handle.

=cut

sub eventfd { shift->handle->read_handle }

=head2 configure

Configuration. Currently supports the following named parameters:

=over 4

=item * notify - the callback which will be triggered when there's a new semaphore value

=back

=cut

sub configure {
	my ($self, %args) = @_;
	for(qw(notify)) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	$self->next::method(%args);
}

=head1 METHODS - Internal

=cut

=head2 _add_to_loop

Called when we are added to the loop.

=cut

sub _add_to_loop {
	my ($self, $loop) = @_;
	my $fd = Linux::FD::Event->new(0, qw(non-blocking semaphore));
	$self->add_child(
		$self->{handle} = IO::Async::Handle->new(
			read_handle   => $fd,
			on_read_ready => $self->curry::weak::on_read_ready,
		)
	);
}

=head2 on_read_ready

Called when there's a read event.

=cut

sub on_read_ready {
	my ($self) = @_;
	return unless my $h = $self->handle->read_handle;
	$self->{notify}->() while $h->get and $self->{notify};
}

=head2 handle

Returns the underlying L<IO::Async::Handle> instance.
=cut

sub handle { shift->{handle} }

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Database::Async::SQLite> - uses eventfd as a notification mechanism from the sqlite thread

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2015-2016. Licensed under the same terms as Perl itself.

