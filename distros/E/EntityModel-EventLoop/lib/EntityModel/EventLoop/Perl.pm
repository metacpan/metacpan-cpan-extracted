package EntityModel::EventLoop::Perl;
{
  $EntityModel::EventLoop::Perl::VERSION = '0.001';
}
# ABSTRACT: Pure-Perl event loop implementation
use EntityModel::Class {
	_isa => [qw(EntityModel::EventLoop)],
};
use Time::HiRes ();

=head1 NAME

EntityModel::EventLoop::Perl - basic Perl implementation for EntityModel 'event loop'

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Used only for testing in the absence of a real event loop.

=head1 METHODS

=cut

=head2 defer

'Defers' execution of the given codeblock. Actually does nothing of the sort, it just runs the
code immediately.

=cut

sub defer {
	my $self = shift;
	my $code = shift;
	$code->();
	$self;
}

=head2 sleep

Runs the given code block after an interval. Blocks execution until the timer expires.

Instance method which expects an interval (in seconds) and a single coderef.

=cut

sub sleep {
	my $self = shift;
	my ($interval, $code) = @_;
	Time::HiRes::sleep $interval;
	$code->();
	return $self;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<EntityModel> - cross-language ORM

=item * L<EntityModel::EventLoop::IO::Async> - an implementation using a real event loop.

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.
