package Log::Abstraction::Backend::Syslog;

# The syslog backend: send messages to syslog through Sys::Syslog
use strict;
use warnings;

use parent 'Log::Abstraction::Backend';

use Carp ();
use Readonly ();
use Sys::Syslog 0.28 ();

our $VERSION = '0.40';

# Default syslog connection parameters
Readonly::Scalar my $DEFAULT_FACILITY => 'local0';
Readonly::Scalar my $DEFAULT_OPTIONS  => 'cons,pid';
Readonly::Scalar my $DEFAULT_IDENTITY => 'user';

# Map internal level names to POSIX syslog priority strings.  syslog has no
# priority below debug, so trace shares debug's threshold
Readonly::Hash my %PRIORITY => (
	trace     => 'debug',
	debug     => 'debug',
	info      => 'info',
	notice    => 'notice',
	warn      => 'warning',
	warning   => 'warning',
	error     => 'err',
	critical  => 'crit',
	alert     => 'alert',
	emergency => 'emerg',
);

# Number of live Log::Abstraction instances that have opened the
# process-global syslog connection; closelog() is only called when the last
# one is destroyed
my $open_count = 0;

=head1 NAME

Log::Abstraction::Backend::Syslog - send messages to syslog

=head1 VERSION

0.40

=head1 DESCRIPTION

Built for the C<syslog> key of a C<logger> hash.  The connection is opened
(C<setlogsock()> with the hash's other keys, then C<openlog()>) for the
first message, and the message sent with C<syslog()> through a C<%s>
format, so C<%> sequences in it are logged literally.  The caller's hash is
not changed: C<facility>, C<level> and C<format> are taken out of a copy,
and C<server> renamed C<host>.

C<openlog()> and C<closelog()> are process-wide, so the instances that have
opened the connection are counted, and C<closelog()> is called when the
last one is destroyed.

For use by L<Log::Abstraction> only; see L<Log::Abstraction::Backend>.

=head1 METHODS

=head2 new

  my $backend = Log::Abstraction::Backend::Syslog->new(
      syslog => \%syslog, level => $level, format => $format,
  );

=cut

sub new {
	my ($class, %args) = @_;

	# Work on a copy so that the caller's hash is not changed
	my %sock = %{$args{'syslog'}};
	my $facility = delete($sock{'facility'}) || $DEFAULT_FACILITY;
	delete @sock{qw(level format)};

	# Accept 'server' as an alias for 'host' (CHI convention)
	if($sock{'server'}) {
		$sock{'host'} = delete $sock{'server'};
	}

	return $class->SUPER::new(%args, facility => $facility, sock => \%sock);
}

=head2 emit

  $backend->emit($logger, $event);

=cut

sub emit {
	my ($self, $logger, $event) = @_;

	# Open the persistent syslog connection on first use
	if(!$logger->{'_syslog_opened'}) {
		my $sock = $self->{'sock'};
		Sys::Syslog::setlogsock({ %{$sock} }) if(scalar keys %{$sock});
		Sys::Syslog::openlog($logger->{'script_name'}, $DEFAULT_OPTIONS, $DEFAULT_IDENTITY);
		$logger->{'_syslog_opened'} = 1;
		$open_count++;
	}

	# The message is passed through '%s' so that a '%m' (or any other '%'
	# sequence) in it is logged literally
	eval {
		my $priority = $PRIORITY{$event->{'level'}};
		Sys::Syslog::syslog("$priority|$self->{facility}", '%s', $self->text($event, $event->{'text'}));
	};
	if($@) {
		Carp::carp(ref($logger), ": syslog failed: $@");
	}
}

=head2 retain_connection

  Log::Abstraction::Backend::Syslog->retain_connection();

Counts another user of the open connection: a clone of a logger that has
opened it.

=cut

sub retain_connection {
	$open_count++;
	return;
}

=head2 release_connection

  Log::Abstraction::Backend::Syslog->release_connection();

A logger that opened the connection is going away; calls C<closelog()> if it
was the last.

=cut

sub release_connection {
	$open_count-- if($open_count > 0);
	Sys::Syslog::closelog() if($open_count == 0);
	return;
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
