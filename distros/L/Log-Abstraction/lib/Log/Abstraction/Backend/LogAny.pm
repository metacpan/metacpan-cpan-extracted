package Log::Abstraction::Backend::LogAny;

# The log_any backend: send messages on to Log::Any
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

use Carp ();
use Readonly ();
use Scalar::Util ();

our $VERSION = '0.40';

# The Log::Any method for each internal level name
Readonly::Hash my %METHOD => (
	trace     => 'trace',
	debug     => 'debug',
	info      => 'info',
	notice    => 'notice',
	warn      => 'warning',
	error     => 'error',
	critical  => 'critical',
	alert     => 'alert',
	emergency => 'emergency',
);

=head1 NAME

Log::Abstraction::Backend::LogAny - send messages on to Log::Any

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for the C<log_any> key of a C<logger> hash, or a L<Log::Any> logger
(C<Log::Any::Proxy>) as the C<logger>.  A category name is looked up with
C<Log::Any-E<gt>get_logger()> for the first message.  The message goes to
the method for its level (C<warn> becomes C<warning>), with the structured
fields as Log::Any's trailing hash reference; with a C<format>, the
formatted line instead.  If Log::Any dies, it carps.

Nothing is sent while a message is already being forwarded (see
C<$Log::Abstraction::Backend::FORWARDING>), so a message that comes back
through L<Log::Any::Adapter::Abstraction> doesn't loop.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 new

  my $backend = Log::Abstraction::Backend::LogAny->new(
      log_any => $proxy_or_category, level => $level, format => $format,
  );

=cut

sub new {
	my ($class, %args) = @_;

	my $self = $class->SUPER::new(%args);
	$self->{'proxy'} = $args{'log_any'} if(Scalar::Util::blessed($args{'log_any'}));
	return $self;
}

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	return if($Log::Abstraction::Backend::FORWARDING);
	local $Log::Abstraction::Backend::FORWARDING = 1;

	my $ok = eval {
		# Proxies follow Log::Any::Adapter->set(), so one is enough
		my $proxy = $self->{'proxy'} //= do {
			require Log::Any;
			Log::Any->get_logger(category => $self->{'log_any'});
		};
		my $method = $METHOD{$event->{'level'}};
		if(defined($self->{'format'})) {
			$proxy->$method($event->{'render'}->($self->{'format'}));
		} else {
			$proxy->$method($event->{'message'}, ($event->{'fields'} ? ($event->{'fields'}) : ()));
		}
		1;
	};
	Carp::carp(ref($logger), ": Log::Any failed: $@") if(!$ok);
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
