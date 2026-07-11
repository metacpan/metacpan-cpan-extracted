package Log::Abstraction;

# TODO: OpenTelemetry (OTel) Logs backend — not yet implemented.
#
# The goal is to route log messages to an OTel collector via
# OpenTelemetry::Logs::Logger->emit_record(), allowing Log::Abstraction
# to participate in a unified traces+logs+metrics pipeline.
#
# Why it is blocked (last assessed 2026-07-10, OTel Perl v0.033):
#
#   1. emit_record() is a no-op stub.  OpenTelemetry::Logs::Logger
#      contains "method emit_record ( %args ) { }" — every call is
#      silently discarded.  This has been the case since logs were added
#      as "experimental" in v0.023 (June 2024).
#
#   2. The SDK has no Logs implementation at all.  SDK::Trace::* is
#      complete (providers, processors, samplers, OTLP exporter), but
#      there is no SDK::Logs::LogRecord, no Batch/Simple processor, and
#      no SDK::Logs::LoggerProvider.  OpenTelemetry::Exporter::OTLP::Logs
#      exists as a module but has no processor pipeline to feed it.
#
#   3. The official Log::Any::Adapter::OpenTelemetry has a documented
#      FIXME: it cannot safely cache the Logger at construction time,
#      because acquiring a Logger before a real LoggerProvider is
#      registered returns a no-op that can never be upgraded.  This is
#      an unresolved architectural issue upstream.
#
#   4. is_debug() / is_* detection in the OTel adapter reads
#      otel_config('LOG_LEVEL'), which is the SDK's own internal
#      diagnostic level, not the application log level — a semantic bug
#      that would propagate into any adapter we write on top.
#
#   5. The Logs stack depends on Object::Pad (Corinna), adding a
#      non-trivial dependency and Perl >= 5.26 requirement in practice.
#
# When to revisit: watch for OpenTelemetry::SDK::Logs::LogRecord::Processor
# appearing on CPAN.  That signals the end-to-end SDK pipe is functional.
# Estimated: late 2026, based on the Trace SDK timeline (~6-9 months after
# the Trace API stabilised).
#
# Implementation sketch (for when the above blockers are resolved):
#   - Add an 'opentelemetry' sub-key to the HASH logger backend.
#   - In _log: call otel_logger_provider()->logger()->emit_record(
#         timestamp       => Time::HiRes::time(),
#         severity_text   => $level,
#         severity_number => $OTEL_SEVERITY{$level},
#         body            => $str,
#         attributes      => $self->{ctx} ? { ctx => $self->{ctx} } : {},
#     );
#   - Map internal levels: trace=1, debug=5, info=9, notice=10,
#     warn=13, error=17 (OTel SeverityNumber spec, table 5).
#   - Store the provider reference, not a cached Logger, to survive
#     provider swaps (workaround for blocker 3 above).

# Enforce strict variable declarations and enable common warnings
use strict;
use warnings;

# Automatically throw exceptions on failed built-in I/O (open, close, print...)
use autodie qw(:all);

# Core and CPAN dependencies
use Carp;
use Config::Abstraction 0.36;
use Data::Dumper;
use Params::Get 0.13;
use POSIX qw(strftime);
use Readonly;
use Readonly::Values::Syslog 0.04;
use Return::Set;
use Scalar::Util 'blessed';

# Sub::Private in enforce mode: _-prefixed subs decorated :Private croak when
# called from outside this package.  HARNESS_ACTIVE bypasses checks during
# make test so white-box tests can still reach private methods.
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private;

# Sys::Syslog imported with bare-function names used in _log
use Sys::Syslog 0.28;

# ---------------------------------------------------------------------------
# Module-level constants -- no magic strings or numbers anywhere below
# ---------------------------------------------------------------------------

# Default minimum log level when none is specified in new()
Readonly::Scalar my $DEFAULT_LEVEL => 'warning';

# Default SMTP delivery parameters for the sendmail backend
Readonly::Scalar my $DEFAULT_SMTP_HOST => 'localhost';
Readonly::Scalar my $DEFAULT_SMTP_PORT => 25;
Readonly::Scalar my $DEFAULT_FROM_ADDR => 'noreply@localhost';
Readonly::Scalar my $MIN_PORT          => 1;
Readonly::Scalar my $MAX_PORT          => 65535;

# Default syslog connection parameters
Readonly::Scalar my $DEFAULT_SYSLOG_FACILITY => 'local0';
Readonly::Scalar my $DEFAULT_SYSLOG_OPTIONS  => 'cons,pid';
Readonly::Scalar my $DEFAULT_SYSLOG_IDENTITY => 'user';

# Default log-line format tokens for file/fd/scalar-path backends
Readonly::Scalar my $DEFAULT_FORMAT         => '%level%> [%timestamp%] %class% %callstack% %message%';
Readonly::Scalar my $DEFAULT_FORMAT_NOCLASS => '%level%> [%timestamp%] %callstack% %message%';

# Map internal level names to POSIX syslog priority strings
Readonly::Hash my %LEVEL_TO_SYSLOG_PRIORITY => (
	trace   => 'debug',
	debug   => 'debug',
	info    => 'info',
	notice  => 'notice',
	warn    => 'warning',
	warning => 'warning',
	error   => 'err',
);

# Regex: characters forbidden in a log-file path (prevents command injection)
Readonly::Scalar my $RE_SAFE_PATH => qr/^([^<>|*?;!`\$"\x00-\x1F]+)$/;

# Regex: path component that would escape the intended directory
Readonly::Scalar my $RE_DOTDOT => qr/\.\./;

# Regex: characters forbidden in an SMTP hostname (allows a-z, A-Z, 0-9, dot, hyphen)
Readonly::Scalar my $RE_SAFE_HOST => qr/[^a-zA-Z0-9.\-]/;

# Regex: a valid TCP port number string (decimal digits only; range checked separately)
Readonly::Scalar my $RE_PORT => qr/^\d+$/;

# Default path to the journald native-protocol socket on systemd systems
Readonly::Scalar my $DEFAULT_JOURNALD_SOCKET => '/run/systemd/journal/socket';

=head1 NAME

Log::Abstraction - Logging Abstraction Layer

=head1 VERSION

0.33

=cut

our $VERSION = 0.33;

=head1 SYNOPSIS

  use Log::Abstraction;

  my $logger = Log::Abstraction->new(logger => 'logfile.log');

  $logger->debug('This is a debug message');
  $logger->info('This is an info message');
  $logger->notice('This is a notice message');
  $logger->trace('This is a trace message');
  $logger->warn({ warning => 'This is a warning message' });

=head1 DESCRIPTION

The C<Log::Abstraction> class provides a flexible logging layer on top of
different types of loggers, including code references, arrays, file paths,
and objects.  It also supports logging to syslog if configured.

=head1 METHODS

=head2 new

  my $logger = Log::Abstraction->new(%args);
  my $logger = Log::Abstraction->new(\%args);
  my $logger = Log::Abstraction->new($file_path);

  # Clone with optional overrides
  my $clone = $logger->new(level => 'debug');

Creates a new C<Log::Abstraction> instance, or clones an existing one when
called on an object.

=head3 Arguments

=over 4

=item * C<carp_on_warn>

If set to 1, and no C<logger> is given, call C<Carp::carp> on C<warn()>.
Also causes C<error()> to C<carp> if C<croak_on_error> is not set.

=item * C<croak_on_error>

If set to 1, and no C<logger> is given, call C<Carp::croak> on C<error()>.

=item * C<config_file>

Path to a configuration file (YAML, XML, INI, etc.) whose contents are
merged with the constructor arguments.  On non-Windows systems the class
can also be configured via environment variables prefixed with
C<"Log::Abstraction::">.  For example:

  export Log::Abstraction::script_name=foo

=item * C<ctx>

Arbitrary context value passed through to CODE-ref logger callbacks as
C<$args-E<gt>{ctx}>.

=item * C<format>

Format string for file/fd backends.  Tokens expanded at log time:

  %callstack%   caller file and line number
  %class%       blessed class of the logger object
  %level%       upper-cased level name
  %message%     the joined log message
  %timestamp%   YYYY-MM-DD HH:MM:SS (local time)
  %env_FOO%     value of $ENV{FOO}, or empty string if unset

The special value C<"json"> (not a format string but a magic keyword) switches
all file and fd backends to emit one compact JSON object per log line:

  {"timestamp":"...","level":"info","message":"...","file":"...","line":42}

This format is compatible with log aggregators such as journald, Loki,
Elasticsearch, and Splunk.  C<class> is included when the logger is a subclass
of C<Log::Abstraction>.

B<Security note:> because C<format> may contain C<%env_*%> tokens, avoid
granting untrusted sources write access to config files that set this key.

=item * C<level>

Minimum level at which to emit log entries.  Defaults to C<"warning">.
Valid values (case-insensitive): C<trace>, C<debug>, C<info>, C<notice>,
C<warn>/C<warning>, C<error>.

=item * C<logger>

One of:

=over 4

=item * A code reference -- called with a hashref C<{ class, file, line, level, message, ctx }>

=item * An object -- method matching the level name is called on it

=item * A hash reference -- may contain C<file>, C<array>, C<fd>, C<syslog>, C<journald>, and/or C<sendmail> keys

=item * An array reference -- C<{ level, message }> hashrefs are pushed onto it

=item * A scalar string -- treated as a file path to append to

=back

When not supplied, L<Log::Log4perl> is initialised as the default backend.

The C<sendmail> sub-hash supports:
C<host>, C<port>, C<to>, C<from>, C<subject>, C<level>, C<min_interval>.
At most one email is sent per C<min_interval> seconds per instance.

The C<journald> sub-hash sends each message as a single datagram to the
systemd journal using the journald native protocol.  Supported keys:

=over 4

=item * C<socket> -- path to the journald socket (default: F</run/systemd/journal/socket>)

=item * C<identifier> -- value for the C<SYSLOG_IDENTIFIER> field (default: basename of C<$0>)

=item * any other key -- included verbatim as an uppercase journald field name

=back

The C<PRIORITY> field is set automatically from the log level (0=emerg...7=debug).
Delivery failures are silent (C<Carp::carp> only); the application is never crashed by a journald error.

=item * C<script_name>

Script name reported to syslog.  Auto-detected from C<$0> if not supplied.

=item * C<verbose>

When using the default Log::Log4perl backend, raises the logging level to
DEBUG when set to a true value.

=back

=head3 Returns

A blessed C<Log::Abstraction> object.

=head3 Side Effects

Loads C<File::Basename> if C<syslog> is configured and C<script_name> is
not supplied.  Loads C<Log::Log4perl> if no logger backend is specified.

=head3 Example

  my $logger = Log::Abstraction->new(
      level  => 'debug',
      logger => \@messages,
  );

  my $clone = $logger->new(level => 'info');

=head3 API Specification

=head4 Input

  {
      carp_on_warn   => { type => 'boolean', optional => 1 },
      config_file    => { type => 'string',  optional => 1 },
      croak_on_error => { type => 'boolean', optional => 1 },
      ctx            => { optional => 1 },
      format         => { type => 'string',  optional => 1 },
      level          => { type => 'string',  regex => qr/^(trace|debug|info|notice|warn(?:ing)?|error)$/i, optional => 1 },
      logger         => { optional => 1 },
      script_name    => { type => 'string',  optional => 1 },
      verbose        => { type => 'boolean', optional => 1 },
  }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

  Error                                     Meaning / Action
  ----------------------------------------  -----------------------------------------
  "<class>: <path>: File not readable"      config_file path exists but is unreadable.
                                            Check file permissions.
  "<class>: Can't load configuration       Config::Abstraction could not parse the
    from <path>"                            file.  Check syntax and format.
  "<class>: syslog needs to know the        syslog backend requested but script_name
    script name"                            could not be determined.  Pass it explicitly.
  "<class>: attempt to encapsulate          logger => Log::Abstraction would create
    Log::Abstraction as a logging class,    a needless forwarding loop.  Use a
    that would add a needless indirection"  different backend.
  "<class>: invalid syslog level '<l>'"     level value is not a recognised syslog
                                            level name.  Use trace/debug/info/notice/
                                            warn/warning/error.

=head3 PSEUDOCODE

  FUNCTION new(class_or_obj, args...)

    Parse args:
      IF single non-hash scalar
      THEN store as logger shorthand
      ELSE extract named params via Params::Get

    IF config_file present:
      CROAK if file is not readable
      Load via Config::Abstraction, merge into args (constructor args win)
      Restore caller-supplied array ref that config merge would have dropped

    IF called on a blessed instance (clone form):
      shallow-clone self merged with override args
      validate and store new level integer if level given in args
      deep-copy message history list
      RETURN clone

    IF syslog requested and script_name not supplied:
      auto-detect script name via File::Basename
      CROAK if still undefined

    IF logger arg is a Log::Abstraction object:
      CROAK (would create a needless forwarding loop)

    IF no logger AND no file AND no array:
      load Log::Log4perl, easy_init at DEBUG or ERROR per verbose flag
      store Log4perl logger as the backend

    Normalise and validate level:
      IF level is an arrayref, take first element
      lc() the level string
      CROAK if not in syslog_values lookup
      default to $DEFAULT_LEVEL if not supplied

    RETURN bless { messages => [], merged args, level => numeric } as class

  END FUNCTION

=cut

sub new {
	my $class = shift;

	# Accept a plain hash, a hashref, or a single scalar (file-path shorthand)
	my %args;
	if((scalar(@_) == 1) && (ref($_[0]) ne 'HASH')) {
		$args{'logger'} = shift;
	} elsif(my $params = Params::Get::get_params(undef, \@_)) {
		%args = %{$params};
	}

	# Load configuration from a file when config_file is present
	if(exists($args{'config_file'})) {
		if(!-r $args{'config_file'}) {
			croak("$class: ", $args{'config_file'}, ': File not readable');
		}
		if(my $config = Config::Abstraction->new(
			config_dirs => [''],
			config_file => $args{'config_file'},
			env_prefix  => "${class}::",
		)) {
			# Merge file config with constructor args; constructor wins
			$config = $config->all();
			if($config->{$class}) {
				$config = $config->{$class};
			}
			my $array = $args{'array'};
			%args = (%{$config}, %args);
			# Restore caller-supplied array ref after merge (config can't supply refs)
			if($array) {
				$args{'array'} = $array;
			}
		} else {
			croak("$class: Can't load configuration from ", $args{'config_file'});
		}
	}

	# Handle function-call form: Log::Abstraction::new() with no class
	if(!defined($class)) {
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# Called on an existing instance -- return a shallow clone
		my $clone = bless { %{$class}, %args }, ref($class);
		if(my $level = $args{'level'}) {
			$level = lc($level);
			if(!defined($syslog_values{$level})) {
				Carp::croak("$class: invalid syslog level '$level'");
			}
			$clone->{level} = $syslog_values{$level};
		}
		# Deep-copy the message history so parent and clone diverge independently
		$clone->{messages} = [ @{$class->{messages}} ];
		return $clone;
	}

	# Auto-detect script name when syslog backend is requested
	if($args{'syslog'} && !$args{'script_name'}) {
		require File::Basename;
		$args{'script_name'} = File::Basename::basename($ENV{'SCRIPT_NAME'} || $0);
		croak("$class: syslog needs to know the script name")
			if(!defined($args{'script_name'}));
	}

	# Reject attempts to use this module as its own logger backend
	if(defined(my $logger = $args{logger})) {
		if(Scalar::Util::blessed($logger) && (ref($logger) eq __PACKAGE__)) {
			croak(
				"$class: attempt to encapsulate ",
				__PACKAGE__,
				' as a logging class, that would add a needless indirection',
			);
		}
	} elsif((!$args{'file'}) && (!$args{'array'})) {
		# Fall back to Log::Log4perl when no other backend is configured
		require Log::Log4perl;
		Log::Log4perl->import();
		Log::Log4perl->easy_init(
			$args{verbose} ? $Log::Log4perl::DEBUG : $Log::Log4perl::ERROR
		);
		$args{'logger'} = Log::Log4perl->get_logger();
	}

	# Resolve and store the numeric threshold for the requested level
	my $level = $args{'level'};
	if($level) {
		if(ref($level) eq 'ARRAY') {
			$level = $level->[0];
		}
		$level = lc($level);
		if(!defined($syslog_values{$level})) {
			Carp::croak("$class: invalid syslog level '$level'");
		}
		$args{'level'} = $level;
	} else {
		$args{'level'} = $DEFAULT_LEVEL;
	}

	# Construct and return the blessed object
	return bless {
		messages => [],
		%args,
		level => $syslog_values{ $args{'level'} },
	}, $class;
}

# ---------------------------------------------------------------------------
# _sanitize_email_header -- remove CR/LF to prevent SMTP header injection
#
# Purpose:      Strip carriage-return and line-feed characters from any string
#               that will appear in a MIME header field (To, From, Subject).
# Entry:        $value -- a scalar, possibly containing \r, \n, or \r\n.
# Exit:         Returns the sanitised scalar, or undef if input was undef.
# Notes:        Called from _log before every header_set() call.
# ---------------------------------------------------------------------------
sub _sanitize_email_header :Private {
	my ($value) = @_;

	return unless defined $value;

	# Strip all CR, LF and CRLF sequences
	$value =~ s/\r\n?|\n//g;

	return Return::Set::set_return(
		$value,
		{ type => 'string', 'matches' => qr/^[^\r\n]*$/ },
	);
}

# ---------------------------------------------------------------------------
# _validate_file_path -- validate and untaint a filesystem path
#
# Purpose:      Ensure a caller-supplied path does not contain dangerous
#               characters or directory-traversal sequences before it is
#               passed to open().
# Entry:        $self  -- the logger object (for error context in croak).
#               $path  -- the raw path string to validate.
# Exit:         Returns the untainted capture (Perl taint-safe string).
#               Croaks with a descriptive message if validation fails.
# Notes:        Blocks the character set <, >, |, *, ?, ;, !, `, $, "
#               and all C0 control characters, as well as ".." sequences.
# ---------------------------------------------------------------------------
sub _validate_file_path :Private {
	my ($self, $path) = @_;

	# Block ".." path-traversal and all dangerous shell metacharacters
	if($path =~ $RE_SAFE_PATH && $path !~ $RE_DOTDOT) {
		return $1;    # $1 is the untainted capture from RE_SAFE_PATH
	}
	Carp::croak(ref($self), ": Invalid file name: $path");
}

# ---------------------------------------------------------------------------
# _journald_send -- encode fields and send one datagram to the journald socket
#
# Purpose:      Format key=value fields in the journald native protocol and
#               deliver them as a single Unix-domain SOCK_DGRAM packet.
# Entry:        $self        -- the logger object (unused but required for
#                              consistent OOP dispatch; enforces Sub::Private).
#               $socket_path -- filesystem path of the journald socket.
#               %fields      -- FIELD_NAME => value pairs; names must be
#                              uppercase ASCII + digits + underscore.
# Exit:         Returns nothing.  Croaks on socket or send failure (the caller
#               wraps every call in eval{} so failures are silent to the app).
# Side effects: Opens a transient Unix datagram socket, sends, closes.
# Notes:        Values containing newline or NUL use the binary framing
#               (field-name NL uint64-LE-length value NL) as specified by
#               https://systemd.io/JOURNAL_NATIVE_PROTOCOL/.
#               Values without newlines or NULs use the simpler FIELD=VALUE NL
#               text format.
# ---------------------------------------------------------------------------
sub _journald_send :Private {
	my ($self, $socket_path, %fields) = @_;

	# Build the datagram payload from all supplied fields
	my $payload = '';
	for my $key (sort keys %fields) {
		my $value = defined($fields{$key}) ? "$fields{$key}" : '';
		if($value =~ /[\n\0]/) {
			# Binary framing: field-name LF uint64LE-length value LF
			$payload .= $key . "\n" . pack('Q<', length($value)) . $value . "\n";
		} else {
			$payload .= "$key=$value\n";
		}
	}

	# Open a Unix-domain datagram socket, send, and close
	require Socket;
	socket(my $sock, Socket::AF_UNIX(), Socket::SOCK_DGRAM(), 0);
	my $dest = Socket::sockaddr_un($socket_path);
	send($sock, $payload, 0, $dest);
	close $sock;
}

# ---------------------------------------------------------------------------
# _format_message -- expand a log-format string into a final log line
#
# Purpose:      Centralise the repeated format-token substitution so that
#               file, fd, and scalar-path backends all share one code path.
# Entry:        $self        -- the logger object (source of 'format' setting).
#               $level       -- log level string (e.g. 'debug').
#               $str         -- the already-joined message string.
#               $use_class   -- 1 to include %class% in the default format,
#                               0 to use the no-class format.
#               $caller_file -- pre-resolved source file of the logging call.
#               $caller_line -- pre-resolved source line of the logging call.
# Exit:         Returns the formatted log line (without trailing newline).
# Notes:        %env_FOO% tokens are expanded with a // '' fallback so that
#               missing environment variables expand silently to empty string.
#               caller_file/caller_line are computed by _log at the correct
#               stack depth (adjusted for the extra _high_priority frame on
#               warn/error calls) so the reported location is always the
#               caller's code, not an internal dispatch frame.
#
# Pseudocode:
#   FUNCTION _format_message(self, level, str, use_class, caller_file, caller_line)
#     IF self->{'format'} eq 'json':
#       Build hash: timestamp, level, message, file=caller_file, line=caller_line
#                   (+ class if subclass)
#       RETURN JSON::PP::encode_json(\%hash)   [single compact line]
#
#     Choose default format template:
#       use_class=1 → DEFAULT_FORMAT (includes %class%)
#       use_class=0 → DEFAULT_FORMAT_NOCLASS
#     Override with self->{'format'} if the caller supplied a custom format
#
#     Compute token values:
#       ulevel    = uc(level)
#       class     = blessed class if it is a subclass, else '' (base package)
#       callstack = caller_file and caller_line
#       timestamp = strftime 'YYYY-MM-DD HH:MM:SS'
#
#     Expand tokens in format string:
#       %level%       → ulevel
#       %class%       → class (may be empty)
#       %message%     → str
#       %callstack%   → callstack
#       %timestamp%   → timestamp
#       %env_FOO%     → $ENV{FOO} // '' (silent if env var unset)
#
#     RETURN formatted line string
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _format_message :Private {
	my ($self, $level, $str, $use_class, $caller_file, $caller_line) = @_;

	my $format = $self->{'format'};

	# 'json' is a magic format value: emit a compact JSON object per line
	if(defined($format) && ($format eq 'json')) {
		require JSON::PP;
		my $bclass = blessed($self);
		my $class  = ($bclass && $bclass ne __PACKAGE__) ? $bclass : undef;
		my %obj = (
			timestamp => strftime('%Y-%m-%d %H:%M:%S', localtime),
			level     => $level,
			message   => $str,
			file      => $caller_file,
			line      => $caller_line + 0,
		);
		$obj{class} = $class if defined($class);
		return JSON::PP::encode_json(\%obj);
	}

	# Select the appropriate default when no custom format is configured ('' is falsy)
	my $default = $use_class ? $DEFAULT_FORMAT : $DEFAULT_FORMAT_NOCLASS;
	$format = $format || $default;

	my $ulevel = uc($level);

	# Suppress the class name for the base package (only show for subclasses)
	my $bclass = blessed($self);
	my $class  = ($bclass && $bclass ne __PACKAGE__) ? $bclass : '';

	my $callstack = "$caller_file $caller_line";
	my $timestamp = strftime '%Y-%m-%d %H:%M:%S', localtime;

	# Expand all recognised tokens in a single pass per token type
	$format =~ s/%level%/$ulevel/g;
	$format =~ s/%class%/$class/g;
	$format =~ s/%message%/$str/g;
	$format =~ s/%callstack%/$callstack/g;
	$format =~ s/%timestamp%/$timestamp/g;
	$format =~ s/%env_(\w+)%/$ENV{$1} \/\/ ''/ge;

	return $format;
}

# ---------------------------------------------------------------------------
# _log -- central dispatcher that routes a message to all active backends
#
# Purpose:      Every public logging method ultimately calls _log.  It checks
#               the current level threshold, records the message in the
#               internal history, then dispatches to the configured backend(s).
# Entry:        $self    -- the logger object.
#               $level   -- one of trace/debug/info/notice/warn/error.
#               @messages -- one or more message strings (or a single arrayref).
# Exit:         Returns nothing (void).  Croaks on configuration errors.
# Side effects: Appends to $self->{messages}.  May write to a file, fd,
#               array, syslog, or email backend.  May load Email::* modules.
# Notes:        Enforced private: croaks if called from outside this package.
#               The caller depth used for file/line in CODE-ref callbacks is
#               caller(1), which resolves correctly for trace/debug/info/notice
#               but points one frame inward for warn/error (via _high_priority).
#
# Pseudocode:
#   FUNCTION _log(self, level, messages...)
#     CROAK if caller package is not this package (private method guard)
#     CROAK if level is not a recognised syslog level name
#     RETURN early if syslog_values{level} > self->{'level'} (below threshold)
#
#     Flatten single-arrayref argument to a list; filter out undefs; join to $str
#     Push { level, message } onto self->{messages} (always recorded)
#     Set $class = '' for base package, else the blessed class name
#
#     IF self->{'logger'} is a CODE ref:
#       Build args hashref { class, file, line, level, message, ctx? }
#       Call logger->( args )
#
#     ELSIF self->{'logger'} is an ARRAY ref:
#       Push { level, message }
#
#     ELSIF self->{'logger'} is a HASH ref:
#       IF 'file' key present:
#         validate path; format line; (eval) open>>file, print, close
#       IF 'array' key present:
#         push { level, message }
#       IF 'sendmail' key present with a 'to' address:
#         IF level passes threshold AND not throttled:
#           CROAK if host contains unsafe characters
#           CROAK if port is out of 1-65535 range
#           (eval) load Email::* modules; build email with sanitised headers;
#                  send via SMTP transport; carp on delivery failure
#           Record timestamp for throttle
#       IF 'syslog' key present:
#         IF level passes threshold:
#           Open syslog connection on first use (setlogsock, openlog)
#           (eval) map level to syslog priority; call Sys::Syslog::syslog;
#                  carp with Data::Dumper output on failure
#       IF 'journald' key present:
#         Map level to syslog PRIORITY integer
#         Build fields: MESSAGE, PRIORITY, SYSLOG_IDENTIFIER, plus any extra
#         (eval) _journald_send(socket_path, %fields); carp on failure
#       IF 'fd' key present:
#         Format line; print to filehandle
#       ELSIF no actionable key (no file/array/syslog/sendmail/journald/fd):
#         CROAK (configuration error)
#
#     ELSIF self->{'logger'} is an unblessed scalar (file path):
#       Validate path; format line; (eval) open>>file, print, close
#
#     ELSIF self->{'logger'} is a blessed object:
#       Map 'notice' to 'info' for backends without notice() (e.g. Log::Log4perl)
#       CROAK if object cannot handle the level
#       Call $logger->$level(@messages)
#
#     ELSIF self->{'array'} top-level key:
#       Push { level, message }
#
#     IF self->{'file'} top-level key:
#       Validate path; format line; (eval) open>>file, print, close
#     IF self->{'fd'} top-level key:
#       Format line; print to filehandle
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _log :Private {
	my ($self, $level, @messages) = @_;

	# Reject direct calls from outside this package (also enforced by :Private)
	if(!(caller)[0]->isa(__PACKAGE__)) {
		Carp::croak('Illegal Operation: _log is a private method');
	}

	# Sanity-check the level (should not be reachable in normal use)
	if(!defined($syslog_values{$level})) {
		Carp::croak(ref($self), ": Invalid level '$level'");
	}

	# Drop messages that fall below the configured threshold
	if($syslog_values{$level} > $self->{'level'}) {
		return;
	}

	# Flatten a single arrayref argument to a plain list
	if((scalar(@messages) == 1) && (ref($messages[0]) eq 'ARRAY')) {
		@messages = @{$messages[0]};
	}

	# Remove any undef elements before joining
	@messages = grep { defined } @messages;
	my $str = join('', @messages);
	chomp($str);

	# Record in the internal message history regardless of backend
	push @{$self->{messages}}, { level => $level, message => $str };

	# Compute class once; suppress the package name for base-class instances
	my $class = blessed($self) || $self;
	if($class eq __PACKAGE__) {
		$class = '';
	}

	# Resolve caller file/line at the correct stack depth.
	# For trace/debug/info/notice: _log ← public_method ← user → depth=1
	# For warn/error: _log ← _high_priority ← public_method ← user → depth=2
	my $depth = ((caller(1))[3] // '') =~ /::_high_priority$/ ? 2 : 1;
	my $caller_file = (caller($depth))[1];
	my $caller_line = (caller($depth))[2];

	# -----------------------------------------------------------------------
	# Dispatch to the configured backend(s)
	# -----------------------------------------------------------------------
	if(my $logger = $self->{'logger'}) {
		if(ref($logger) eq 'CODE') {
			# CODE-ref backend: build the args hashref and invoke the callback
			my $args = {
				class   => blessed($self) || __PACKAGE__,
				file    => $caller_file,
				line    => $caller_line,
				level   => $level,
				message => \@messages,
			};
			if(my $ctx = $self->{ctx}) {
				$args->{ctx} = $ctx;
			}
			$logger->($args);
		} elsif(ref($logger) eq 'ARRAY') {
			# ARRAY-ref backend: push a simple hashref
			push @{$logger}, { level => $level, message => $str };
		} elsif(ref($logger) eq 'HASH') {
			# HASH backend: route to whichever sub-keys are present

			# -- file sub-backend -------------------------------------------
			if(my $raw_file = $logger->{'file'}) {
				my $file = $self->_validate_file_path($raw_file);
				my $use_class = ($class ne '') ? 1 : 0;
				my $line = $self->_format_message($level, $str, $use_class, $caller_file, $caller_line);
				# Log failures are silent by design; the app must not crash on I/O errors
				eval {
					open(my $fout, '>>', $file);
					print $fout "$line\n";
					close $fout;
				};
			}

			# -- array sub-backend ------------------------------------------
			if(my $array = $logger->{'array'}) {
				push @{$array}, { level => $level, message => $str };
			}

			# -- sendmail sub-backend ---------------------------------------
			if(exists($logger->{'sendmail'}) && exists($logger->{'sendmail'}->{'to'})) {
				my $sm = $logger->{'sendmail'};

				# Check the level threshold for email (undef means send always)
				if((!defined($sm->{'level'})) ||
				   ($syslog_values{$level} <= $syslog_values{ $sm->{'level'} })) {

					# Honour the minimum-interval throttle
					my $throttled = 0;
					if(my $interval = $sm->{'min_interval'}) {
						my $now = time();
						$throttled = defined($self->{_last_email_sent})
							&& ($now - $self->{_last_email_sent}) < $interval;
					}

					if(!$throttled) {
						# Validate host and port before any eval so bad config croaks immediately
						my $host = $sm->{'host'} || $DEFAULT_SMTP_HOST;
						Carp::croak(ref($self), ": Invalid SMTP host: $host")
							if $host =~ $RE_SAFE_HOST;
						my $port = $sm->{'port'} || $DEFAULT_SMTP_PORT;
						Carp::croak(ref($self), ": Invalid SMTP port: $port")
							unless $port =~ $RE_PORT
								&& $port >= $MIN_PORT
								&& $port <= $MAX_PORT;

						# Load mail modules lazily; wrap only I/O in eval to handle delivery failures
						eval {
							require Email::Simple;
							require Email::Sender::Simple;
							require Email::Sender::Transport::SMTP;

							Email::Simple->import();
							Email::Sender::Simple->import('sendmail');
							Email::Sender::Transport::SMTP->import();

							# Build the email object with sanitised headers
							my $email = Email::Simple->new('');
							$email->header_set(
								'to',
								_sanitize_email_header($sm->{'to'}),
							);
							my $from = $sm->{'from'} || $DEFAULT_FROM_ADDR;
							$email->header_set(
								'from',
								_sanitize_email_header($from),
							);
							if(my $subject = $sm->{'subject'}) {
								$email->header_set(
									'subject',
									_sanitize_email_header($subject),
								);
							}
							$email->body_set(join(' ', @messages));

							my $transport = Email::Sender::Transport::SMTP->new({
								host => $host,
								port => $port,
							});
							sendmail($email, { transport => $transport });
						};

						if($@) {
							Carp::carp("Failed to send email: $@");
							return;
						}

						# Record send time for the throttle on success
						$self->{_last_email_sent} = time();
					}
				}
			}

			# -- syslog sub-backend -----------------------------------------
			if(my $syslog = $logger->{'syslog'}) {
				if((!defined($syslog->{'level'})) ||
				   ($syslog_values{$level} <= $syslog->{'level'})) {

					# Open the persistent syslog connection on first use
					if(!$self->{_syslog_opened}) {
						my $facility = delete $syslog->{'facility'} || $DEFAULT_SYSLOG_FACILITY;
						my $min_level = delete $syslog->{'level'};

						# Accept 'server' as an alias for 'host' (CHI convention)
						if($syslog->{'server'}) {
							$syslog->{'host'} = delete $syslog->{'server'};
						}
						Sys::Syslog::setlogsock($syslog) if(scalar keys %{$syslog});
						$syslog->{'facility'} = $facility;
						$syslog->{'level'}    = $min_level;

						openlog($self->{script_name}, $DEFAULT_SYSLOG_OPTIONS, $DEFAULT_SYSLOG_IDENTITY);
						$self->{_syslog_opened} = 1;
					}

					# Map internal level names to syslog priority strings
					eval {
						my $priority = $LEVEL_TO_SYSLOG_PRIORITY{$level} // 'warning';
						my $facility = $syslog->{'facility'};
						Sys::Syslog::syslog("$priority|$facility", join(' ', @messages));
					};
					if($@) {
						my $err = $@;
						$err .= ":\n" . Data::Dumper->new([$syslog])->Dump();
						Carp::carp($err);
					}
				}
			}

			# -- journald sub-backend --------------------------------------
			if(my $jd = $logger->{'journald'}) {
				# Map internal level name to journald/syslog PRIORITY integer (0=emerg, 7=debug)
				my $priority  = $syslog_values{$level};
				my $sock_path = $jd->{'socket'} || $DEFAULT_JOURNALD_SOCKET;

				# Determine the syslog identifier (script name or basename of $0)
				my $ident = $jd->{'identifier'} || $self->{'script_name'} || do {
					require File::Basename;
					File::Basename::basename($0);
				};

				# Mandatory journald fields
				my %fields = (
					MESSAGE           => $str,
					PRIORITY          => $priority,
					SYSLOG_IDENTIFIER => $ident,
				);

				# Include any extra fields from the journald config hash
				for my $key (keys %{$jd}) {
					next if lc($key) =~ /^(?:socket|identifier)$/;
					$fields{uc($key)} = $jd->{$key};
				}

				# Delivery failures are silent; the app must not crash on log errors
				eval { $self->_journald_send($sock_path, %fields) };
				Carp::carp(ref($self), ": journald send failed: $@") if $@;
			}

			# -- fd sub-backend ---------------------------------------------
			if(my $fout = $logger->{'fd'}) {
				my $use_class = ($class ne '') ? 1 : 0;
				my $line = $self->_format_message($level, $str, $use_class, $caller_file, $caller_line);
				print $fout "$line\n";

			} elsif(!$logger->{'file'} && !$logger->{'array'}
					&& !$logger->{'syslog'} && !exists($logger->{'sendmail'})
					&& !$logger->{'fd'} && !$logger->{'journald'}) {
				# Hash logger with no recognised sub-key -- configuration error
				croak(ref($self), ": Don't know how to deal with the $level message");
			}

		} elsif(!ref($logger)) {
			# Scalar-path backend: validate path then append to the file
			my $safe_path = $self->_validate_file_path($logger);
			my $use_class = ($class ne '') ? 1 : 0;
			my $line = $self->_format_message($level, $str, $use_class, $caller_file, $caller_line);
			# Log failures are silent by design; the app must not crash on I/O errors
			eval {
				open(my $fout, '>>', $safe_path);
				print $fout "$line\n";
				close $fout;
			};

		} elsif(Scalar::Util::blessed($logger)) {
			# Object backend: delegate to the method matching the level name
			if(!$logger->can($level)) {
				if(($level eq 'notice') && $logger->can('info')) {
					# Log::Log4perl has no notice() method; map to info()
					$level = 'info';
				} else {
					croak(
						ref($self), ': ', ref($logger),
						" doesn't know how to deal with the $level message",
					);
				}
			}
			$logger->$level(@messages);

		} else {
			croak(ref($self),
				": configuration error, no handler written for the $level message");
		}

	} elsif($self->{'array'}) {
		# Top-level 'array' key (not nested inside logger hash)
		push @{$self->{'array'}}, { level => $level, message => $str };
	}

	# -----------------------------------------------------------------------
	# Top-level 'file' and 'fd' keys (parallel to 'logger')
	# -----------------------------------------------------------------------
	if($self->{'file'}) {
		my $file = $self->_validate_file_path($self->{'file'});
		my $use_class = ($class ne '') ? 1 : 0;
		my $line = $self->_format_message($level, $str, $use_class, $caller_file, $caller_line);
		# Log failures are silent by design; the app must not crash on I/O errors
		eval {
			open(my $fout, '>>', $file);
			print $fout "$line\n";
			close $fout;
		};
	}

	if(my $fout = $self->{'fd'}) {
		my $use_class = ($class ne '') ? 1 : 0;
		my $line = $self->_format_message($level, $str, $use_class, $caller_file, $caller_line);
		print $fout "$line\n";
	}
}

# ---------------------------------------------------------------------------
# _high_priority -- common handler for warn() and error() calls
#
# Purpose:      Extracts the warning/error text from a variety of argument
#               forms (plain list, named 'warning' key, or arrayref value),
#               then dispatches to _log and optionally to Carp.
# Entry:        $self    -- the logger object.
#               $level   -- 'warn' or 'error'.
#               @_       -- remaining arguments in any of the accepted forms.
# Exit:         Returns nothing (void).
# Side effects: Calls _log, which appends to $self->{messages} and writes to
#               configured backends.  May call Carp::carp or Carp::croak.
# Notes:        The duplicated extraction logic that appeared in earlier
#               versions has been collapsed into a single if/else block.
#
# Pseudocode:
#   FUNCTION _high_priority(self, level, args...)
#     RETURN early if no args supplied
#     RETURN early if level is below WARNING threshold (defensive guard)
#
#     Attempt to parse args as named-parameter form via Params::Get (in eval)
#
#     IF named 'warning' key found in result:
#       Extract warning value; RETURN if value is undef
#       IF value is an arrayref: join defined elements into a string
#     ELSE (plain list form):
#       Join defined elements of @_ into a string
#       RETURN if resulting string is empty
#
#     IF called as a class method (self is the package name, not an object):
#       IF error level: CROAK with warning text; RETURN
#       CARP with warning text; RETURN
#
#     Call self->_log(level, warning)
#
#     IF error level:
#       IF croak_on_error flag set OR no logger/array backend configured:
#         CROAK with warning text
#
#     IF carp_on_warn flag set OR no logger/array backend configured:
#       CARP with warning text
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _high_priority :Private {
	my $self  = shift;
	my $level = shift;    # 'warn' or 'error'

	# Nothing to log if no arguments supplied
	return if(scalar(@_) == 0);

	# Silently drop levels lower than WARNING (should not happen in practice)
	return if($syslog_values{$level} > $WARNING);

	# Try to interpret arguments as warn(warning => VALUE) named form
	my $params;
	eval { $params = Params::Get::get_params('warning', @_) };

	# Determine the final warning string from whichever form was passed
	my $warning;
	if($params && ref($params) eq 'HASH' && exists($params->{warning})) {
		# Named form: warn({ warning => ... }) or warn(warning => ...)
		$warning = $params->{warning};
		return unless defined($warning);
		if(ref($warning) eq 'ARRAY') {
			# Arrayref value: join defined elements
			$warning = join('', grep { defined } @{$warning});
		}
	} else {
		# Plain list form: warn('text', 'more text', ...)
		$warning = join('', grep { defined } @_);
		return unless length($warning);
	}

	# If called as a class method rather than on an instance, use Carp directly
	if($self eq __PACKAGE__) {
		if($syslog_values{$level} <= $ERROR) {
			Carp::croak($warning);
		}
		Carp::carp($warning);
		return;
	}

	# Log the message through the normal dispatch path
	$self->_log($level, $warning);

	# Optionally escalate to Carp for error-level messages
	if($syslog_values{$level} <= $ERROR) {
		if($self->{'croak_on_error'}
			|| (!defined($self->{logger}) && !defined($self->{array}))) {
			Carp::croak($warning);
		}
	}

	# Optionally also emit a Carp::carp for warn-level messages
	if($self->{'carp_on_warn'}
		|| (!defined($self->{logger}) && !defined($self->{array}))) {
		Carp::carp($warning);
	}
}

=head2 level

  my $current = $logger->level();
  $logger->level('debug');

Get or set the minimum logging level.  When setting, returns C<$self> to
allow method chaining.  When getting, returns the current level as an
integer (per the syslog numeric scale; lower numbers are higher priority).

=head3 Arguments

=over 4

=item * C<$level> (optional)

A level name string: C<trace>, C<debug>, C<info>, C<notice>, C<warn>/C<warning>,
or C<error>.  Case-insensitive.  Omit to perform a pure get.

=back

=head3 Returns

In getter mode: an integer in the range 0 (emergency) to 7 (debug/trace).

In setter mode: C<$self> (to allow chaining).

=head3 Side Effects

When setting, updates C<$self-E<gt>{level}>.

=head3 Example

  $logger->level('debug');
  my $n = $logger->level();   # e.g. 7

  # Method chaining
  $logger->level('info')->info('Now at info level');

=head3 API Specification

=head4 Input

  {
      level => { type => 'string', regex => qr/^(trace|debug|info|notice|warn(?:ing)?|error)$/i, optional => 1 },
  }

=head4 Output

  Getter: { type => 'integer', min => 0, max => 7 }
  Setter: { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

  Warning                                   Meaning / Action
  ----------------------------------------  ------------------------------------------
  "<class>: invalid syslog level '<l>'"     The supplied level name is not recognised.
                                            Use trace/debug/info/notice/warn/error.

=head3 PSEUDOCODE

  FUNCTION level(self, level?)

    IF level argument supplied:
      CARP and RETURN undef if level is not a recognised syslog name
      Store syslog_values{level} in self->{'level'}
      RETURN self  (allows method chaining)

    ELSE (getter mode):
      RETURN self->{'level'}  (current numeric threshold)

  END FUNCTION

=cut

sub level {
	my ($self, $level) = @_;

	if($level) {
		# Setter path: validate, store and return $self for chaining
		if(!defined($syslog_values{$level})) {
			Carp::carp(ref($self), ": invalid syslog level '$level'");
			return;    # undef signals the caller that validation failed
		}
		$self->{'level'} = $syslog_values{$level};
		return $self;
	}

	# Getter path: return the numeric threshold
	return Return::Set::set_return(
		$self->{'level'},
		{ 'type' => 'integer', 'min' => 0, 'max' => 7 },
	);
}

=head2 is_debug

  if($logger->is_debug()) { ... }

Returns a true value when the logger is configured at C<debug> level or
below (i.e. debug messages will actually be emitted).  Provided for
compatibility with L<Log::Any>.

=head3 Arguments

None.

=head3 Returns

C<1> if the current level threshold includes debug (or trace) messages;
C<0> otherwise.

=head3 Example

  if($logger->is_debug()) {
      $logger->debug('Expensive diagnostic: ' . Dumper(\%state));
  }

=head3 API Specification

=head4 Input

  {} (no arguments)

=head4 Output

  { type => 'boolean' }

=cut

sub is_debug {
	my $self = $_[0];

	# $DEBUG is exported by Readonly::Values::Syslog
	return ($self->{'level'} && ($self->{'level'} >= $DEBUG)) ? 1 : 0;
}

=head2 messages

  my $aref = $logger->messages();

Returns a reference to a shallow copy of all messages emitted through this
logger since it was created (or since the last clone).

=head3 Arguments

None.

=head3 Returns

An array reference of hashrefs, each with keys C<level> (string) and
C<message> (string).

=head3 Side Effects

None.  The returned array is a copy; modifying it does not affect the
internal history.

=head3 Example

  $logger->info('hello');
  my $msgs = $logger->messages();
  # $msgs->[0] = { level => 'info', message => 'hello' }

=head3 API Specification

=head4 Input

  {} (no arguments)

=head4 Output

  { type => 'arrayref', element_type => { level => 'string', message => 'string' } }

=cut

sub messages {
	my $self = $_[0];

	return [ @{$self->{messages}} ];
}

=head2 trace

  $logger->trace(@messages);
  $logger->trace(\@messages);

Logs a message at C<trace> level (the most verbose level, below C<debug>).
The message is dropped silently when the configured level threshold is above
C<trace>.

=head3 Arguments

=over 4

=item * C<@messages>

One or more strings, or a single array reference.  All elements are joined
without a separator before storage.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->trace('entering sub foo, args=', join(',', @args));

  # Chaining
  $logger->trace('start')->debug('details')->info('summary');

=head3 API Specification

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=cut

sub trace {
	my $self = shift;
	$self->_log('trace', @_);
	return $self;
}

=head2 debug

  $logger->debug(@messages);
  $logger->debug(\@messages);

Logs a message at C<debug> level.

=head3 Arguments

=over 4

=item * C<@messages>

One or more strings, or a single array reference.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->debug('Query took ', $elapsed, 'ms');

=head3 API Specification

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=cut

sub debug {
	my $self = shift;
	$self->_log('debug', @_);
	return $self;
}

=head2 info

  $logger->info(@messages);
  $logger->info(\@messages);

Logs a message at C<info> level.

=head3 Arguments

=over 4

=item * C<@messages>

One or more strings, or a single array reference.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->info('Server started on port ', $port);

=head3 API Specification

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=cut

sub info {
	my $self = shift;
	$self->_log('info', @_);
	return $self;
}

=head2 notice

  $logger->notice(@messages);
  $logger->notice(\@messages);

Logs a message at C<notice> level (higher priority than C<info>, lower than
C<warn>).

=head3 Arguments

=over 4

=item * C<@messages>

One or more strings, or a single array reference.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->notice('Configuration reloaded');

=head3 API Specification

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=cut

sub notice {
	my $self = shift;
	$self->_log('notice', @_);
	return $self;
}

=head2 warn

  $logger->warn(@messages);
  $logger->warn(\@messages);
  $logger->warn(warning => $text);
  $logger->warn({ warning => $text });
  $logger->warn(warning => \@parts);

Logs a warning message.  Also dispatches to syslog and/or email backends
when those are configured.  Falls back to C<Carp::carp> when no logger
backend is set.

A C<warn()> call with an empty or all-undef argument list is a silent no-op.

=head3 Arguments

=over 4

=item * C<@messages>

A plain list of strings joined without separator, B<or> a named C<warning>
parameter whose value may be a string or an array reference of strings.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to internal message history.  Writes to all configured backends.
May call C<Carp::carp> if C<carp_on_warn> is set or no backend is active.

=head3 Example

  $logger->warn('Disk usage is high');
  $logger->warn(warning => 'Connection reset', ' retrying');
  $logger->warn({ warning => ['Part A', 'Part B'] });

=head3 API Specification

=head4 Input

  # Named form
  { warning => { type => [ 'scalar', 'arrayref' ] } }
  # Plain-list form
  { messages => { type => 'arrayref' } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

  (no croak/carp messages from this method itself; see _high_priority)

=cut

sub warn {
	my $self = shift;

	# Empty argument list is a documented no-op
	if(scalar(@_) > 0) {
		$self->_high_priority('warn', @_);
	}
	return $self;
}

=head2 error

  $logger->error(@messages);
  $logger->error(warning => $text);

Logs an error-level message.  Behaves identically to C<warn()> but at the
C<error> level, which triggers C<Carp::croak> if C<croak_on_error> is set
or no logger backend is active.

=head3 Arguments

Same argument forms as C<warn()>.

=head3 Returns

C<$self>, to allow method chaining.  Note: if C<croak_on_error> is set, the
method never returns -- execution unwinds via C<Carp::croak>.

=head3 Side Effects

Same as C<warn()> plus optional C<Carp::croak> escalation.

=head3 Example

  $logger->error('Fatal: database unavailable');

=head3 API Specification

=head4 Input

  { warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

  Croak                                     Meaning / Action
  ----------------------------------------  ------------------------------------------
  (the error message text itself)           croak_on_error is set, or no backend is
                                            active.  The call stack is unwound.

=cut

sub error {
	my $self = shift;
	$self->_high_priority('error', @_);
	return $self;
}

=head2 fatal

  $logger->fatal(@messages);

Synonym for C<error()>.  Provided for compatibility with logging frameworks
that use C<fatal> as the highest-severity level name.

=head3 Arguments

Same as C<error()>.

=head3 Returns

C<$self>.

=head3 Side Effects

Same as C<error()>.

=head3 Example

  $logger->fatal('Unrecoverable state; aborting');

=head3 API Specification

=head4 Input

  { warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

Same as C<error()>.

=cut

sub fatal {
	my $self = shift;
	$self->_high_priority('error', @_);
	return $self;
}

# ---------------------------------------------------------------------------
# DESTROY -- close the persistent syslog connection when the object is freed
#
# Purpose:      Ensure the syslog socket is closed cleanly on object
#               destruction, avoiding resource leaks under persistent
#               interpreters such as mod_perl.
# Entry:        $self -- the logger object being destroyed.
# Exit:         void
# Side effects: Calls Sys::Syslog::closelog() and removes _syslog_opened flag.
# Notes:        Uses fully-qualified Sys::Syslog::closelog() so that
#               Test::Mockingbird can intercept the call in tests.
# ---------------------------------------------------------------------------
sub DESTROY {
	my $self = $_[0];

	if($self->{_syslog_opened}) {
		Sys::Syslog::closelog();
		delete $self->{_syslog_opened};
	}
}

=encoding utf-8

=head1 EXAMPLES

=head2 CSV file logging for BI import

The code-reference backend gives you full control over the output format.
The example below writes every message at C<trace> level and above as a
CSV row to a file, producing output that can be loaded directly into a
spreadsheet or BI tool (Tableau, Power BI, Metabase, etc.).

Each row contains: C<timestamp>, C<level>, C<class>, C<file>, C<line>, C<message>.

  use Log::Abstraction;

  my $csv_file = 'app_events.csv';

  # Write the header row once (skip if the file already exists and has data).
  unless (-s $csv_file) {
      open my $fh, '>', $csv_file or die "Cannot open $csv_file: $!";
      print $fh qq{timestamp,level,class,file,line,message\n};
      close $fh;
  }

  # Helper: quote a single CSV field (escapes embedded double-quotes).
  my $csv_field = sub {
      my $v = defined $_[0] ? $_[0] : '';
      $v =~ s/"/""/g;
      return qq{"$v"};
  };

  my $logger = Log::Abstraction->new(
      level  => 'trace',        # capture everything from trace upwards
      logger => sub {
          my $args = $_[0];

          my $timestamp = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime);
          my $message  = join(' ', @{ $args->{message} // [] });

          open my $fh, '>>', $csv_file or return;
          print $fh join(',',
              $csv_field->($timestamp),
              $csv_field->($args->{level}),
              $csv_field->($args->{class}),
              $csv_field->($args->{file}),
              $csv_field->($args->{line}),
              $csv_field->($message),
          ), "\n";
          close $fh;
      },
  );

  $logger->trace('application started');
  $logger->info('user logged in', { user => 'alice' });
  $logger->warn({ warning => 'disk usage above 80%' });

The resulting C<app_events.csv> looks like:

  timestamp,level,class,file,line,message
  "2026-05-27T14:00:00Z","trace","Log::Abstraction","app.pl","42","application started"
  "2026-05-27T14:00:01Z","info","Log::Abstraction","app.pl","43","user logged in"
  "2026-05-27T14:00:02Z","warn","Log::Abstraction","Log/Abstraction.pm","820","disk usage above 80%"

Note: C<class> is always C<Log::Abstraction> (or the subclass name if you subclass the
module).  For C<trace>, C<debug>, C<info>, and C<notice> calls, C<file> and C<line>
resolve to the caller's source location.  For C<warn> and C<error> calls the
extra C<_high_priority> stack frame shifts the resolution one level inward, so
C<file> and C<line> point into the module rather than the calling script.

For production use, consider replacing the manual C<$csv_field> quoting with
L<Text::CSV> for correct handling of embedded newlines and other edge cases.

If you also want real-time alerting on critical events, add the email logic
directly inside the code-ref callback -- test C<$args-E<gt>{level}> and call
your mailer for C<warn> / C<error> messages while still writing the CSV row
for every message.

Alternatively, use the C<sendmail> hash-ref backend on its own (without the
code-ref) and add a C<level> key to restrict emails to warn-and-above:

  my $logger = Log::Abstraction->new(
      level  => 'warn',
      logger => {
          sendmail => {
              host         => 'smtp.example.com',
              to           => 'ops@example.com',
              from         => 'logger@example.com',
              subject      => 'Application alert',
              level        => 'warn',   # only email at warn level and above
              min_interval => 300,      # at most one alert email per 5 minutes
          },
      },
  );

Note: the C<sendmail> backend writes the module's standard text format, not
CSV.  To produce CSV rows I<and> send email alerts from the same logger,
embed both the CSV-write and the mail-send logic inside a single code-ref
callback as described above.

=head1 LIMITATIONS

=over 4

=item B<Syslog hash mutation>

The C<syslog> sub-hash passed to C<new()> is mutated in-place on the first
log call: C<facility> and C<level> are temporarily removed before
C<setlogsock()> is called, then restored; C<server> is permanently renamed
to C<host>.  Sharing a syslog hashref between two C<Log::Abstraction>
instances is not supported and produces undefined behaviour on the second
instance.

=item B<No structured log fields>

All backends except the CODE-ref backend reduce the message to a flat string.
To log structured key/value pairs, use a CODE-ref backend that formats the
data itself.

=item B<Single-threaded email throttle>

The C<min_interval> throttle for the C<sendmail> backend and the
C<_syslog_opened> first-open flag are stored on the object without mutex
protection.  Under Perl ithreads or other concurrency models, objects shared
between threads are not safe.

=item B<OpenTelemetry not yet supported>

The OTel Logs SDK for Perl is incomplete; see the TODO block at the top of
F<lib/Log/Abstraction.pm> for a full status report and the list of blockers.
Monitor L<https://metacpan.org/pod/OpenTelemetry::SDK> for progress.

=item B<Log::Log4perl is a de-facto required dependency>

When no C<logger>, C<file>, or C<array> backend is configured, C<new()>
loads L<Log::Log4perl> and uses it as the default backend.  Although listed
as an optional runtime dependency, it is required in that default-backend
path.

=back

=head1 AUTHOR

Nigel Horne C<njh@nigelhorne.com>

=head1 SEE ALSO

=over 4

=item * L<Log::Any> and L<Log::Any::Adapter::Abstraction>

Route messages from any C<Log::Any>-using CPAN module through
C<Log::Abstraction> with a single C<Log::Any::Adapter-E<gt>set()> call.

=item * L<Test Dashboard|https://nigelhorne.github.io/Log-Abstraction/coverage/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-log-abstraction at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Abstraction>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Log::Abstraction

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Log-Abstraction>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Abstraction>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Log-Abstraction>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Log::Abstraction>

=back

=head1 FORMAL SPECIFICATION

=head2 new

  ┌─ LogState ──────────────────────────────────────────────────
  │ level    : ℤ
  │ messages : seq { level : STRING; message : STRING }
  │ logger   : LOGGER
  └─────────────────────────────────────────────────────────────

  ┌─ New ───────────────────────────────────────────────────────
  │ args? : Args
  │ result! : LogState
  ├─────────────────────────────────────────────────────────────
  │ result!.level = syslog_values(args?.level ∨ 'warning')
  │ result!.messages = ⟨⟩
  │ result!.logger = args?.logger
  └─────────────────────────────────────────────────────────────

  Clone operation (called on an existing object):

  ┌─ Clone ─────────────────────────────────────────────────────
  │ ΔLogState
  │ overrides? : Args
  ├─────────────────────────────────────────────────────────────
  │ result!.level    = syslog_values(overrides?.level ∨ level)
  │ result!.messages = messages   {deep copy}
  │ result!.logger   = overrides?.logger ∨ logger
  └─────────────────────────────────────────────────────────────

=head2 level

  ┌─ LevelGet ─────────────────────────────────────────────────
  │ ΞLogState
  │ result! : ℤ
  ├─────────────────────────────────────────────────────────────
  │ result! = level
  │ 0 ≤ result! ∧ result! ≤ 7
  └─────────────────────────────────────────────────────────────

  ┌─ LevelSet ─────────────────────────────────────────────────
  │ ΔLogState
  │ new_level? : STRING
  ├─────────────────────────────────────────────────────────────
  │ new_level? ∈ dom(syslog_values)
  │ level' = syslog_values(new_level?)
  └─────────────────────────────────────────────────────────────

=head2 is_debug

  ┌─ IsDebug ──────────────────────────────────────────────────
  │ ΞLogState
  │ result! : BOOLEAN
  ├─────────────────────────────────────────────────────────────
  │ result! = (level ≥ syslog_values('debug'))
  └─────────────────────────────────────────────────────────────

=head2 messages

  ┌─ Messages ─────────────────────────────────────────────────
  │ ΞLogState
  │ result! : seq { level : STRING; message : STRING }
  ├─────────────────────────────────────────────────────────────
  │ result! = messages
  └─────────────────────────────────────────────────────────────

=head2 trace

  ┌─ Trace ────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ⟨⟩
  │ syslog_values('trace') ≤ level
  │ messages' = messages ⌢ ⟨{level ↦ 'trace', message ↦ ⊕(msg?)}⟩
  └─────────────────────────────────────────────────────────────

=head2 debug

  ┌─ Debug ────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ⟨⟩
  │ syslog_values('debug') ≤ level
  │ messages' = messages ⌢ ⟨{level ↦ 'debug', message ↦ ⊕(msg?)}⟩
  └─────────────────────────────────────────────────────────────

=head2 info

  ┌─ Info ─────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ⟨⟩
  │ syslog_values('info') ≤ level
  │ messages' = messages ⌢ ⟨{level ↦ 'info', message ↦ ⊕(msg?)}⟩
  └─────────────────────────────────────────────────────────────

=head2 notice

  ┌─ Notice ───────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ⟨⟩
  │ syslog_values('notice') ≤ level
  │ messages' = messages ⌢ ⟨{level ↦ 'notice', message ↦ ⊕(msg?)}⟩
  └─────────────────────────────────────────────────────────────

=head2 warn

  ┌─ Warn ─────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING | { warning : STRING | seq STRING }
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ∅ ∧ join(msg?) ≠ ''
  │ syslog_values('warn') ≤ level
  │ messages' = messages ⌢ ⟨{level ↦ 'warn', message ↦ join(msg?)}⟩
  └─────────────────────────────────────────────────────────────

=head2 error

  ┌─ Error ────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING | { warning : STRING | seq STRING }
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ∅ ∧ join(msg?) ≠ ''
  │ syslog_values('error') ≤ level
  │ messages' = messages ⌢ ⟨{level ↦ 'error', message ↦ join(msg?)}⟩
  │ croak_on_error = 1 ⟹ execution_continues = false
  └─────────────────────────────────────────────────────────────

=head2 fatal

  fatal ≡ error   (identical operation schema)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
