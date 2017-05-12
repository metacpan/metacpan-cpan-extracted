package EntityModel::EventLoop;
# ABSTRACT: Abstract interface for managing eventloop objects for EntityModel
use EntityModel::Class {
	_isa => [qw(Mixin::Event::Dispatch)],
};

our $VERSION = '0.001';

=head1 NAME

EntityModel::EventLoop - not an event loop

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Abstract framework for attaching event loops to L<EntityModel>.

This abstract class definition is implemented by various subclasses
(L</SEE ALSO>). Normally none of these modules would be used directly:
other classes such as the L<EntityModel::Storage>-derived async storage
backends will use them to obtain the relevant event loop object or to
queue tasks using whichever event loop happens to be available.

Note that this is B<not> an event loop implementation - if you're looking
for one of those, there are many options available: try L<POE> or L<IO::Async>
perhaps.

=cut

=head2 defer

Defers execution of the given code block.

Instance method which expects a single coderef as parameter.

=cut

sub defer { die '->defer is abstract' }

=head2 sleep

Runs the given code block after an interval.

Instance method which expects an interval (in seconds) and a single coderef.

=cut

sub sleep { die '->sleep is abstract' }

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<EntityModel> - cross-language ORM

=item * L<EntityModel::EventLoop::IO::Async> - implementation using L<IO::Async>

=item * L<EntityModel::EventLoop::POE> - implementation using L<POE>

=item * L<EntityModel::EventLoop::AnyEvent> - implementation using L<AnyEvent>

=item * L<EntityModel::EventLoop::Mojo::IOLoop> - implementation using the L<Mojo::IOLoop> from L<Mojolicious>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011-2012. Licensed under the same terms as Perl itself.
