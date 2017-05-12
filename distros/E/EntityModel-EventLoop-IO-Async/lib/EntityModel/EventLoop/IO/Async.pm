package EntityModel::EventLoop::IO::Async;
# ABSTRACT: Wrapper around an IO::Async::Loop instance
use EntityModel::Class {
	_isa => [qw(EntityModel::EventLoop)],
	loop => 'IO::Async::Loop',
};

our $VERSION = '0.001';

=head1 NAME

EntityModel::EventLoop::IO::Async - handler for L<IO::Async::Loop> object.

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Support for an L<IO::Async> event loop.

=head1 METHODS

=cut

=head2 loop

Direct accessor for the L<IO::Async::Loop> object, can be used to provide a specific loop:

 $el->loop(IO::Async::Loop::Epoll->new);

=cut

=head2 event_loop

Returns the event loop, instantiating a new one if necessary. Should be used in preference
to L</loop> for making sure that a valid event loop is available, since this will raise an
exception if no event loop could be instantiated.

=cut

sub event_loop {
	my $self = shift;
	$self->loop(IO::Async::Loop->new) unless $self->loop;
	return $self->loop || die "No event loop available";
}

=head2 defer

Defers execution of the given codeblock using L<IO::Async::Loop/$loop->later( $code )>.

=cut

sub defer {
	my $self = shift;
	my $code = shift;
	$self->event_loop->later($code);
	$self;
}

=head2 sleep

Runs the given code block after an interval.

Instance method which expects an interval (in seconds) and a single coderef.

=cut

sub sleep {
	my $self = shift;
	my ($interval, $code) = @_;
	$self->event_loop->enqueue_timer(
		delay => $interval,
		code => $code
	);
	return $self;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<EntityModel> - cross-language ORM

=item * L<EntityModel::EventLoop> - base class for event loop integration with L<EntityModel>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.
