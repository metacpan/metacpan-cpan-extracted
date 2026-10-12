package Log::Abstraction::Backend::File;

# The file backend: append a formatted line to a file
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

our $VERSION = '0.40';

=head1 NAME

Log::Abstraction::Backend::File - append messages to a file

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for C<logger =E<gt> $path>, a top-level C<file>, or the C<file> key
of a C<logger> hash.  Each message is formatted (with the backend's
C<format>, or else the logger's) and appended to the file, which is opened
for each message.  The path is checked, and the file rotated, by
Log::Abstraction.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	$event->{'write'}->($self->{'file'}, $event->{'render'}->($self->{'format'}));
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
