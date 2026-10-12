package Log::Abstraction::Backend::Fd;

# The fd backend: print a formatted line to a file handle
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

our $VERSION = '0.40';

=head1 NAME

Log::Abstraction::Backend::Fd - print messages to a file handle

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for a top-level C<fd>, or the C<fd> key of a C<logger> hash.  Each
message is formatted (with the backend's C<format>, or else the logger's)
and printed to the handle.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	$event->{'write'}->($self->{'fd'}, $event->{'render'}->($self->{'format'}));
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
