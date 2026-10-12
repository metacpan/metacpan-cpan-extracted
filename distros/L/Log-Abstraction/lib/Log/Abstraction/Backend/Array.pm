package Log::Abstraction::Backend::Array;

# The array backend: push the history entry onto an array
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

our $VERSION = '0.40';

=head1 NAME

Log::Abstraction::Backend::Array - push messages onto an array

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for C<logger =E<gt> \@array>, a top-level C<array>, or the C<array>
key of a C<logger> hash.  Pushes C<{ level, message }> hash references, with
C<fields> when the message has structured fields.  With a C<format>, the
C<message> is the formatted line.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	push @{$self->{'array'}}, {
		@{$event->{'entry'}},
		(defined($self->{'format'}) ? (message => $event->{'render'}->($self->{'format'})) : ()),
	};
}

=head1 AUTHOR

Nigel Horne C<njh@nigelhorne.com>

=head1 SEE ALSO

L<Log::Abstraction>, L<Log::Abstraction::Backend>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
