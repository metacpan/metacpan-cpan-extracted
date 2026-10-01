package Log::Any::Adapter::Abstraction;

# Route Log::Any log calls through a Log::Abstraction backend
use strict;
use warnings;

use parent 'Log::Any::Adapter::Base';

use Carp;
use Log::Abstraction;
use Readonly::Values::Syslog 0.04;
use Scalar::Util 'blessed';

our $VERSION = '0.35';

=head1 NAME

Log::Any::Adapter::Abstraction - Log::Any adapter backed by Log::Abstraction

=head1 VERSION

0.35

=head1 SYNOPSIS

  use Log::Any::Adapter;
  use Log::Abstraction;

  my @messages;

  # Option A: pass a pre-built Log::Abstraction instance
  my $logger = Log::Abstraction->new(logger => \@messages, level => 'debug');
  Log::Any::Adapter->set('Abstraction', instance => $logger);

  # Option B: let the adapter create a Log::Abstraction for you
  Log::Any::Adapter->set('Abstraction', level => 'debug', logger => \@messages);

  # Any module that uses Log::Any will now route through Log::Abstraction
  use Log::Any '$log';
  $log->info('Hello world');

=head1 DESCRIPTION

C<Log::Any::Adapter::Abstraction> is a L<Log::Any> adapter that routes
messages from any module using L<Log::Any> through a L<Log::Abstraction>
backend.  Configure a single C<Log::Abstraction> instance (with file, syslog,
email, array, or code-ref backends) and all C<Log::Any>-using CPAN modules
automatically send their output there.

=head2 Level mapping

Log::Any has nine severity levels; Log::Abstraction has six.  The mapping is:

  Log::Any level   Log::Abstraction method
  ---------------  -----------------------
  trace            trace
  debug            debug
  info             info
  notice           notice
  warning          warn
  error            error
  critical         error
  alert            error
  emergency        error

C<critical>, C<alert>, and C<emergency> all route to C<error()> because
Log::Abstraction follows the syslog six-level model.

=head1 METHODS

=head2 init

Called automatically by C<Log::Any::Adapter::Base::new()>.  Initialises the
internal C<Log::Abstraction> backend.

=head3 Arguments (passed as key=E<gt>value pairs to C<Log::Any::Adapter-E<gt>set>)

=over 4

=item * C<instance>

An existing C<Log::Abstraction> object.  When supplied, the adapter wraps it
directly without creating a new instance.  Anything other than a
C<Log::Abstraction> object (or subclass) is a fatal error.

=item * Any C<Log::Abstraction-E<gt>new()> argument

C<logger>, C<level>, C<file>, C<fd>, C<array>, C<format>, C<ctx>,
C<script_name>, C<verbose>, C<carp_on_warn>, C<croak_on_error>,
C<config_file>, C<max_messages>.  Used to build a fresh C<Log::Abstraction>
instance when C<instance> is not supplied.

=back

=head3 Example

  Log::Any::Adapter->set('Abstraction',
      level  => 'debug',
      format => 'json',
      file   => '/var/log/myapp.log',
  );

=head3 API Specification

=head4 Input

  {
      instance    => { type => OBJECT, isa => 'Log::Abstraction', optional => 1 },
      logger      => { optional => 1 },
      level       => { type => SCALAR, optional => 1 },
      file        => { type => SCALAR, optional => 1 },
      fd          => { optional => 1 },
      array       => { type => ARRAYREF, optional => 1 },
      format      => { type => SCALAR, optional => 1 },
      ctx         => { optional => 1 },
      script_name => { type => SCALAR, optional => 1 },
      verbose     => { type => BOOLEAN, optional => 1 },
      carp_on_warn   => { type => BOOLEAN, optional => 1 },
      croak_on_error => { type => BOOLEAN, optional => 1 },
      config_file    => { type => SCALAR, optional => 1 },
      max_messages   => { type => INTEGER, min => 0, optional => 1 },
  }

=head4 Output

  { type => 'object', class => 'Log::Any::Adapter::Abstraction' }

=head3 MESSAGES

  Error                                     Meaning / Action
  ----------------------------------------  -----------------------------------------
  "...: instance must be a Log::Abstraction  'instance' was given something other
    object"                                 than a Log::Abstraction object.
  (any Log::Abstraction croak)              The supplied constructor args are invalid.
                                            See Log::Abstraction for detail.

=cut

# ---------------------------------------------------------------------------
# Map Log::Any level names to Log::Abstraction dispatch method names.
# critical, alert, and emergency all collapse to error() -- Log::Abstraction
# follows the syslog six-level model and has no distinct level above error.
# ---------------------------------------------------------------------------
my %LA_TO_METHOD = (
	trace     => 'trace',
	debug     => 'debug',
	info      => 'info',
	notice    => 'notice',
	warning   => 'warn',
	error     => 'error',
	critical  => 'error',
	alert     => 'error',
	emergency => 'error',
);

# Map Log::Any level names to Log::Abstraction level strings for threshold checks.
my %LA_TO_LEVEL = (
	trace     => 'trace',
	debug     => 'debug',
	info      => 'info',
	notice    => 'notice',
	warning   => 'warn',
	error     => 'error',
	critical  => 'error',
	alert     => 'error',
	emergency => 'error',
);

# ---------------------------------------------------------------------------
# init -- create or store the Log::Abstraction instance backing this adapter
#
# Purpose:  Called by Log::Any::Adapter::Base::new() after blessing the
#           adapter hash.  Either wraps an existing Log::Abstraction object
#           (from the 'instance' key) or builds a new one from the remaining
#           adapter constructor arguments.
# Entry:    $self -- adapter hash blessed into this class.
# Exit:     Sets $self->{_logger}; returns nothing.
# Side effects: May construct a Log::Abstraction object (which may open
#               file handles, start syslog, etc.).
# ---------------------------------------------------------------------------
sub init {
	my $self = shift;

	# Reuse a caller-supplied Log::Abstraction instance if one was provided;
	# anything else is a mistake, not a request for a default logger
	if(defined(my $inst = $self->{instance})) {
		if(!blessed($inst) || !$inst->isa('Log::Abstraction')) {
			Carp::croak(__PACKAGE__, ': instance must be a Log::Abstraction object');
		}
		$self->{_logger} = $inst;
		return;
	}

	# Build a fresh Log::Abstraction from the constructor key=value pairs
	my %new_args;
	for my $key (qw(
		logger level file fd array format ctx script_name verbose
		carp_on_warn croak_on_error config_file max_messages
	)) {
		$new_args{$key} = $self->{$key} if exists $self->{$key};
	}
	$self->{_logger} = Log::Abstraction->new(%new_args);
}

=head2 Logging methods

=over 4

=item trace

=item debug

=item info

=item notice

=item warning

=item error

=item critical

=item alert

=item emergency

=back

  $adapter->info($message);

Called by L<Log::Any> with the formatted message; each sends it to the
matching L<Log::Abstraction> method (see L</Level mapping>).  These methods
are generated when the module loads.  A croak from Log::Abstraction (e.g.
C<croak_on_error>) is turned into a C<Carp::carp>, so logging never dies.

=head3 API Specification

=head4 Input

  { message => { type => 'string' } }

=head4 Output

  { type => 'undef' }

=head2 Detection methods

=over 4

=item is_trace

=item is_debug

=item is_info

=item is_notice

=item is_warning

=item is_error

=item is_critical

=item is_alert

=item is_emergency

=back

  if($adapter->is_debug()) { ... }

Return 1 if a message at that level would be logged by the wrapped
L<Log::Abstraction> instance's level threshold, otherwise 0.  As in
Log::Abstraction, C<is_trace> equals C<is_debug>, and C<is_critical>,
C<is_alert> and C<is_emergency> equal C<is_error>.

=head3 API Specification

=head4 Input

  {} (no arguments)

=head4 Output

  { type => 'boolean' }

=cut

# ---------------------------------------------------------------------------
# Build logging methods for every Log::Any level name.
# Each method delegates to the corresponding Log::Abstraction dispatch method.
# Logging through Log::Any must never kill the module doing the logging, so
# a croak from Log::Abstraction (e.g. croak_on_error) is turned into a carp.
# ---------------------------------------------------------------------------
for my $la_level (keys %LA_TO_METHOD) {
	my $method = $LA_TO_METHOD{$la_level};
	no strict 'refs';
	*{$la_level} = sub {
		my ($self, $msg) = @_;
		eval { $self->{_logger}->$method($msg); 1 } or Carp::carp($@);
		return;
	};
}

# ---------------------------------------------------------------------------
# Build is_* detection methods for every Log::Any level name.
# Returns 1 when the adapter's Log::Abstraction threshold is at or below the
# requested level (i.e. messages at that level would not be dropped).
# ---------------------------------------------------------------------------
for my $la_level (keys %LA_TO_LEVEL) {
	my $threshold = $syslog_values{ $LA_TO_LEVEL{$la_level} };
	no strict 'refs';
	*{"is_$la_level"} = sub {
		my $self = $_[0];
		return ($self->{_logger}->level() >= $threshold) ? 1 : 0;
	};
}

=head1 LIMITATIONS

=over 4

=item B<Nine-to-six level collapse>

Log::Any has nine severity levels; Log::Abstraction has six.  C<critical>,
C<alert>, and C<emergency> all map to C<error()>.  Applications that rely on
distinguishing these three levels in downstream Log::Abstraction backends will
lose that distinction.

=item B<No structured field support>

Log::Any's C<log_fields()> mechanism for structured fields is not forwarded
to Log::Abstraction.  Only the final formatted string is dispatched; callers
that need structured output should use the Log::Abstraction CODE-ref backend
and access the formatted string via the C<message> key.

=item B<Logging never dies>

A croak from the wrapped C<Log::Abstraction> instance, such as from
C<croak_on_error>, is turned into a C<Carp::carp> so that a module logging
through Log::Any is never killed by its log call.

=item B<Log::Any as optional, not required>

This adapter requires L<Log::Any> at runtime, but Log::Any is listed as a
C<recommends> dependency rather than C<requires>.  CPAN clients that do not
install recommended modules will allow this adapter to be installed but not
loaded.  Install Log::Any explicitly if you intend to use this adapter.

=back

=head1 AUTHOR

Nigel Horne C<njh@nigelhorne.com>

=head1 SEE ALSO

L<Log::Abstraction>, L<Log::Any>, L<Log::Any::Adapter>

=encoding utf-8

=head1 FORMAL SPECIFICATION

=head2 init
  ┌─ AdapterState ──────────────────────────────────────────────
  │ _logger : Log::Abstraction
  └─────────────────────────────────────────────────────────────

  ┌─ Init ──────────────────────────────────────────────────────
  │ args? : { instance? : Log::Abstraction | logger_args }
  │ result! : AdapterState
  ├─────────────────────────────────────────────────────────────
  │ args?.instance ≠ ∅ ∧ isa(args?.instance, Log::Abstraction)
  │   ⟹ result!._logger = args?.instance
  │ args?.instance = ∅
  │   ⟹ result!._logger = Log::Abstraction::new(logger_args)
  └─────────────────────────────────────────────────────────────

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
