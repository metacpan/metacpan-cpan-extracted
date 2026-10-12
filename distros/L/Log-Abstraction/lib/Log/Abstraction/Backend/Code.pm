package Log::Abstraction::Backend::Code;

# The code-reference backend: call it with a hash of the message
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

our $VERSION = '0.40';

=head1 NAME

Log::Abstraction::Backend::Code - call a code reference with each message

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for C<logger =E<gt> \&code>.  The code is called with
C<{ class, file, line, level, message, ctx, fields }>, where C<message> is an
array reference of the message's parts, and C<ctx> and C<fields> are only
present when set.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	my $args = {
		class   => $event->{'class'},
		file    => $event->{'file'},
		line    => $event->{'line'},
		level   => $event->{'level'},
		message => $event->{'parts'},
	};
	$args->{'ctx'} = $event->{'ctx'} if($event->{'ctx'});
	$args->{'fields'} = $event->{'fields'} if($event->{'fields'});
	$self->{'code'}->($args);
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
