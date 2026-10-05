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

# TODO: Outstanding items from the 0.35 gap analysis (2026-09-30).
#
#   - Sub::Private enforcement is silently disabled when this module is
#     loaded at run time (require, use_ok, Log::Any::Adapter->set), and
#     "Too late to run CHECK block" is emitted to the user.  Needs a fix in
#     Sub::Private (e.g. wrap immediately or use INIT when CHECK has passed).
#
# Roadmap - features:
#   - sendmail digests: batch messages suppressed by min_interval into the
#     next email instead of discarding them.
#   - Log::Dispatch / Log::Any producer mode.
#   - Redaction: redact => [qr/password=\S+/] applied before any backend.
#
# Roadmap - technical debt:
#   - Split _log into per-backend classes (Log::Abstraction::Backend::*)
#     built once in new(), so the caller's syslog hash is not mutated and
#     the "Don't know how to deal" fallback disappears.
#   - Keep file handles open (re-open on inode change) instead of
#     open/print/close for every message.  logrotate then needs the file
#     reopened: add a reopen() method (and document hooking it to SIGHUP),
#     and have _rotate close the handle before renaming.  Not every log
#     rotation tool sends SIGHUP, so also close and reopen on a write when more
#     than a configurable time (default 5 minutes) has passed since the
#     last reopen.  Not needed while files are opened per message.
#   - Reuse the journald socket rather than creating one per message.
#   - Optional asynchronous/non-blocking delivery for the sendmail backend;
#     a blocking SMTP conversation inside a log call is a latency hazard.

# Enforce strict variable declarations and enable common warnings
use strict;
use warnings;

# Automatically throw exceptions on failed built-ins (open, close, socket,
# send...).  Not ':all': that adds system()/exec(), which this module never
# calls, and which would make IPC::System::Simple a hidden dependency
use autodie qw(:default);

# Core and CPAN dependencies.  Functions are called by their full names
# and nothing is imported, so that they can't be called as methods on a
# logger ($log->croak, $log->syslog ...).  Readonly::Values::Syslog only
# exports variables (%syslog_values, $DEBUG ...)
use Carp ();
use Config::Abstraction 0.40;
use Params::Get 0.15;
use POSIX ();
use Readonly ();
use Readonly::Values::Syslog 0.04;
use Return::Set 0.04;
use Scalar::Util ();
use Time::HiRes ();
use Time::Local ();

# Sub::Private in enforce mode: _-prefixed subs decorated :Private croak when
# called from outside this package.  HARNESS_ACTIVE bypasses checks during
# make test so white-box tests can still reach private methods.
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private 0.05;

# Sys::Syslog, called as Sys::Syslog::openlog() etc. in _log and DESTROY
use Sys::Syslog 0.28 ();

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

# Default strftime pattern for %timestamp% and the JSON timestamp
Readonly::Scalar my $DEFAULT_TIMESTAMP_FORMAT => '%Y-%m-%d %H:%M:%S';

# strftime pattern for timestamp_format => 'iso8601' or 'rfc3339', without
# the offset, which is 'Z' in UTC and '%:z' otherwise
Readonly::Scalar my $RFC3339_TIMESTAMP_FORMAT => '%Y-%m-%dT%H:%M:%S';

# Most digits of fractional seconds (nanoseconds); a %N without a width
# gives this many
Readonly::Scalar my $MAX_TIMESTAMP_PRECISION => 9;

# Number of rotated files kept (FILE.1 ... FILE.5) when rotate_keep isn't given
Readonly::Scalar my $DEFAULT_ROTATE_KEEP => 5;

# Multipliers for the K/M/G suffixes of rotate_size
Readonly::Hash my %SIZE_UNITS => (
	''  => 1,
	'k' => 1024,
	'm' => 1024 ** 2,
	'g' => 1024 ** 3,
);

# rotate_interval names, each mapped to a function of (epoch seconds, UTC
# offset in seconds, use UTC?) that returns the period it falls in.  The file
# rotates when its last-modified time is in an earlier period than now.
# Weeks start on Monday: day 0 (1970-01-01) was a Thursday
Readonly::Hash my %ROTATE_PERIOD => (
	hourly  => sub { int(($_[0] + $_[1]) / 3600) },
	daily   => sub { int(($_[0] + $_[1]) / 86_400) },
	weekly  => sub { int((int(($_[0] + $_[1]) / 86_400) + 3) / 7) },
	monthly => sub { my @tm = $_[2] ? gmtime($_[0]) : localtime($_[0]); ($tm[5] * 12) + $tm[4] },
);

# Default log-line format tokens for file/fd/scalar-path backends
Readonly::Scalar my $DEFAULT_FORMAT         => '%level%> [%timestamp%] %class% %callstack% %message%';
Readonly::Scalar my $DEFAULT_FORMAT_NOCLASS => '%level%> [%timestamp%] %callstack% %message%';

# Map internal level names to POSIX syslog priority strings.  syslog has no
# priority below debug, so trace shares debug's threshold (see the POD)
Readonly::Hash my %LEVEL_TO_SYSLOG_PRIORITY => (
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

# Regex: characters forbidden in a log-file path (prevents command injection).
# Anchored with \z, not $, which would accept a trailing newline
Readonly::Scalar my $RE_SAFE_PATH => qr/^([^<>|*?;!`\$"\x00-\x1F]+)\z/;

# Regex: path component that would escape the intended directory
Readonly::Scalar my $RE_DOTDOT => qr/\.\./;

# Regex: characters forbidden in an SMTP hostname (allows a-z, A-Z, 0-9, dot, hyphen)
Readonly::Scalar my $RE_SAFE_HOST => qr/[^a-zA-Z0-9.\-]/;

# Regex: a valid TCP port number string (decimal digits only; range checked separately)
Readonly::Scalar my $RE_PORT => qr/^\d+$/;

# Default path to the journald native-protocol socket on systemd systems
Readonly::Scalar my $DEFAULT_JOURNALD_SOCKET => '/run/systemd/journal/socket';

# Regex: a valid journald field name (uppercase ASCII, digits and underscore,
# not starting with an underscore, which journald reserves for trusted fields)
Readonly::Scalar my $RE_JOURNALD_FIELD => qr/^[A-Z0-9][A-Z0-9_]*$/;

# Largest journald datagram sent; the default socket send buffer is ~212KB
# on most Linux systems and bigger datagrams fail, so longer messages are
# truncated to fit.  Some systems have smaller buffers, so on EMSGSIZE the
# limit is halved and the send retried, down to $JOURNALD_MIN_PAYLOAD
Readonly::Scalar my $JOURNALD_MAX_PAYLOAD => 200_000;
Readonly::Scalar my $JOURNALD_MIN_PAYLOAD => 4_096;

# Longest journald field name; journald ignores fields with longer names
Readonly::Scalar my $JOURNALD_MAX_FIELD_NAME => 64;

# Marker appended to a message truncated to fit in a journald datagram
Readonly::Scalar my $TRUNCATED_MARKER => ' [truncated]';

# Number of live instances that have opened the process-global syslog
# connection; closelog() is only called when the last one is destroyed
my $syslog_open_count = 0;

# Single JSON encoder for format => 'json', built on first use.  It returns
# a character string so that all backends share one output-encoding path
my $json_encoder;

=head1 NAME

Log::Abstraction - Logging Abstraction Layer

=head1 VERSION

0.37

=cut

our $VERSION = '0.37';

=head1 SYNOPSIS

  use Log::Abstraction;

  # The default level is 'warning'; 'trace' lets every example through
  my $logger = Log::Abstraction->new(logger => 'logfile.log', level => 'trace');

  $logger->debug('This is a debug message');
  $logger->info('This is an info message');
  $logger->notice('This is a notice message');
  $logger->trace('This is a trace message');
  $logger->warn({ warning => 'This is a warning message' });

  # Structured fields
  $logger->info('User logged in', { user_id => 42 });

=head1 DESCRIPTION

The C<Log::Abstraction> class provides a flexible logging layer on top of
different types of loggers, including code references, arrays, file paths,
and objects.  It also supports logging to syslog if configured.

=head2 Unicode

Messages may be character strings containing any Unicode text.  The file,
fd and scalar-path backends write character strings as UTF-8 (unless an
C<fd> handle already has a C<:utf8> or C<:encoding> layer, in which case the
handle does the encoding), and C<format =E<gt> 'json'> output is UTF-8 too.
journald fields are sent as UTF-8.  Byte strings are written unchanged.

=head2 Structured fields

Every logging method accepts a hash reference of structured fields after
the message:

  $logger->info('User logged in', { user_id => 42, ip => $ip });
  $logger->warn('Slow query', { ms => 1250 });

A hash reference is taken as fields only when it is the last of two or more
arguments, so C<warn({ warning =E<gt> ... })> keeps its meaning, and a lone
hash reference is still a message.  An empty hash reference is ignored.  The
fields are copied, so changing the hash afterwards doesn't change what was
logged.  They are kept out of the message and go to each backend as follows:

=over 4

=item * L</messages>, C<array> and an ARRAY C<logger> -- a C<fields> key in
the entry, alongside C<level> and C<message>.

=item * a CODE C<logger> -- a C<fields> key in the hashref it is called with.

=item * C<format =E<gt> 'json'> -- a nested C<fields> object.  Objects are
stringified; other references are kept as JSON data.

=item * C<journald> -- journal fields.  Each name is upper-cased, characters
other than C<A-Z>, C<0-9> and C<_> become C<_>, leading underscores are
removed and it is cut to 64 characters; a field left with no name is
dropped.  Fields override the extra keys in the C<journald> hash, but never
C<MESSAGE>, C<PRIORITY> or C<SYSLOG_IDENTIFIER>.

=item * text formats (C<file>, C<fd>, a scalar C<logger>), C<syslog>,
C<sendmail> and object loggers -- appended to the message as logfmt-style
C<key=value> pairs in key order, e.g. C<User logged in ip=10.0.0.1 user_id=42>.
Characters other than C<[\w.-]> in a key become C<_>.  A value that is empty
or contains white space, C<">, C<=> or C<\> is double-quoted, with C<"> and
C<\> escaped and control characters written as C<\n>, C<\r>, C<\t> or
C<\xNN>.  Objects are stringified and other references written as JSON.  An
object logger is passed the pairs as an extra argument after the message.

=back

When logging through L<Log::Any>, a hash reference at the end of the call,
together with the proxy's C<context>, arrives here as fields; see
L<Log::Any::Adapter::Abstraction/structured>.

=head2 Per-backend level and format

Every backend can have its own C<level> and C<format>, as well as the
logger's.  C<syslog>, C<journald> and C<sendmail> are hashes already, so
they take them as keys.  C<file>, C<fd> and C<array>, inside a C<logger> hash
or at the top level, may be given as a hash holding the destination under
the backend's own name:

  my $log = Log::Abstraction->new(
      level  => 'debug',
      logger => {
          file   => { file => '/var/log/myapp.log', format => 'json' },
          fd     => { fd => \*STDERR, level => 'warning' },
          array  => { array => \@recent, level => 'info' },
          syslog => { level => 'error', format => '%level%: %message%' },
      },
  );

=over 4

=item * C<level> -- the backend only gets messages at this level or more
severe.  A level name or a syslog number (0-7).  The logger's C<level> is
applied first, so a backend's level can only narrow it: set the logger's
C<level> to the most verbose any backend wants.

=item * C<format> -- a format string, or C<json>, as for the logger's
L</format>, which it overrides.  For C<file> and C<fd> it is the line
written.  For the others, which by default get the message as it is, it
replaces the message: the C<array> entry's C<message>, the text sent to
syslog, the journal's C<MESSAGE> field and the email body.

=back

The plain forms (C<file =E<gt> $path>, C<fd =E<gt> $handle>,
C<array =E<gt> \@array>) still work and have no level or format of their
own.  A blessed handle object is a destination, not the hash form.

=head2 File rotation

Log files written by path (a scalar C<logger>, a C<file> key in a C<logger>
hash, and the top-level C<file>) can be rotated by size, by time, or both:

  my $log = Log::Abstraction->new(
      file            => '/var/log/myapp.log',
      rotate_size     => '10M',
      rotate_interval => 'daily',
      rotate_keep     => 7,
  );

Before each write the file is checked, and if it is due it is renamed to
F<myapp.log.1>, the old F<.1> to F<.2> and so on, the oldest beyond
C<rotate_keep> being deleted; the line then goes to a new F<myapp.log>.  A
rotation that fails (e.g. for lack of permission) is ignored, and the line is
still written.  File handles passed as C<fd> aren't rotated.

Rotation isn't coordinated between processes: if several processes log to the
same file, use B<logrotate> instead.

=head3 logrotate

The file is opened, appended to and closed for every message, never held
open, so B<logrotate>'s default (rename the file and let the application
create a new one) works without C<copytruncate>, and without sending the
process a C<SIGHUP>: the next message is written to the new file.

=head1 METHODS

=head2 new

  my $logger = Log::Abstraction->new(%args);
  my $logger = Log::Abstraction->new(\%args);
  my $logger = Log::Abstraction->new($file_path);

  # Clone with optional overrides
  my $clone = $logger->new(level => 'debug');

Creates a new C<Log::Abstraction> instance, or clones an existing one when
called on an object.  It may also be called as a plain function,
C<Log::Abstraction::new(%args)>, which behaves like
C<Log::Abstraction-E<gt>new(%args)>.

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

Format string for the file, fd and scalar-path backends; a backend's own
C<format> (see L</Per-backend level and format>) overrides it for that
backend.  Unset or an empty string means the default,
C<%level%E<gt> [%timestamp%] %class% %callstack% %message%>.  Tokens expanded
at log time:

  %callstack%   caller file and line number
  %class%       blessed class of the logger object
  %level%       upper-cased level name
  %message%     the joined log message
  %timestamp%   the time of the call; YYYY-MM-DD HH:MM:SS local time by
                default (see timestamp_format, timestamp_precision and utc)
  %env_FOO%     value of $ENV{FOO}, or empty string if unset

Tokens are only expanded in the format string itself, never in the text
of the message.  Each line break in a message is followed by a tab, so a
continuation line can't be mistaken for a new log entry.

The special value C<"json"> (not a format string but a magic keyword) switches
all file and fd backends to emit one compact JSON object per log line:

  {"timestamp":"...","level":"info","message":"...","file":"...","line":42}

This format is compatible with log aggregators such as journald, Loki,
Elasticsearch, and Splunk.  C<class> is included when the logger is a subclass
of C<Log::Abstraction>, and C<fields> when the call has L</Structured fields>.
Keys are emitted in sorted order.

B<Security note:> because a format may contain C<%env_*%> tokens, which
expand to environment variables, avoid granting untrusted sources write
access to config files that set C<format> or any backend's C<format> (see
L</Per-backend level and format>).

=item * C<level>

Minimum level at which to emit log entries.  Defaults to C<"warning">.
Valid values (case-insensitive): C<trace>, C<debug>, C<info>/C<informational>,
C<notice>, C<warn>/C<warning>, C<error>/C<err>, C<crit>/C<critical>/C<fatal>,
C<alert>, C<emerg>/C<emergency>/C<panic>.  C<trace> and C<debug> are the same
threshold (see L</LIMITATIONS>).  It may also be an array reference, whose
first element is used, as some configuration-file formats produce.

=item * C<max_messages>

The most entries to keep in the in-memory history returned by
L</messages>; when it is full, the oldest entry is discarded.  Must be a
non-negative integer; C<0> keeps no history at all.  Unlimited by default, which in a long-running process
means the history grows without bound.

=item * C<logger>

One of:

=over 4

=item * A code reference -- called with a hashref C<{ class, file, line, level, message, ctx, fields }>
(C<ctx> and C<fields> only when there are any)

=item * An object -- method matching the level name is called on it

=item * A hash reference -- may contain C<file>, C<array>, C<fd>, C<syslog>, C<journald>, and/or C<sendmail> keys,
each of which may have its own C<level> and C<format> (see L</Per-backend level and format>)

=item * An array reference -- C<{ level, message }> hashrefs are pushed onto it, with a
C<fields> key when the call has L</Structured fields>

=item * A scalar string -- treated as a file path to append to

=back

When not supplied, L<Log::Log4perl> is initialised as the default backend.

The C<sendmail> sub-hash supports:
C<host>, C<port>, C<to>, C<from>, C<subject>, C<level>, C<format>,
C<min_interval>.  C<to> is required.  With C<format>, the email body is the
formatted line rather than the message.  C<level> may be a level name or a syslog number (0-7);
without it, every message is emailed.
At most one email is sent per C<min_interval> seconds per instance.  If
delivery fails, C<Carp::carp> is called and the other backends still receive
the message.

The C<syslog> sub-hash supports the keys below.  The message is passed to
C<syslog()> through a C<%s> format, so C<%> sequences in it, such as C<%m>,
are logged literally.

=over 4

=item * C<facility> -- the syslog facility (default: C<local0>)

=item * C<level> -- only messages at this level or more severe are sent; a level name or a syslog number (0-7)

=item * C<format> -- format the message with this (see L</format>) before sending it; by default the message is sent as it is

=item * C<host> (or its alias C<server>), and any other L<Sys::Syslog/setlogsock> option -- passed to C<setlogsock()>

=back

The C<journald> sub-hash sends each message as a single datagram to the
systemd journal using the journald native protocol.  Supported keys:

=over 4

=item * C<socket> -- path to the journald socket (default: F</run/systemd/journal/socket>)

=item * C<identifier> -- value for the C<SYSLOG_IDENTIFIER> field (default: basename of C<$0>)

=item * C<level> -- only messages at this level or more severe are sent; a level name or a syslog number (0-7)

=item * C<format> -- the C<MESSAGE> field is the message formatted with this (see L</format>); by default it is the message as it is

=item * any other key -- included verbatim as an uppercase journald field name.
The upper-cased name must contain only C<A-Z>, C<0-9> and C<_>, and must not
start with C<_>; C<new()> croaks otherwise.

=back

The C<PRIORITY> field is set automatically from the log level (0=emerg...7=debug).
A message too large for one datagram (about 200KB) is truncated and
C<[truncated]> appended.
Delivery failures are silent apart from a single C<Carp::carp> (repeated only
after a later send has succeeded); the application is never crashed by a
journald error.

=item * C<rotate_interval>

Rotate log files by time: C<hourly>, C<daily>, C<weekly> (weeks start on
Monday) or C<monthly>, case-insensitive.  Before each write, a file whose
last-modified time is in an earlier period than now (in local time, or UTC
with C<utc>) is rotated, so a file not written to for a while rotates on the
next write.  See L</File rotation>.

=item * C<rotate_keep>

How many rotated files to keep, F<FILE.1> to F<FILE.I<n>> (default 5).  With
C<0>, a file due for rotation is deleted instead.

=item * C<rotate_size>

Rotate log files that have reached this size: a number of bytes, optionally
followed by C<K>, C<M> or C<G> (powers of 1024), e.g. C<10M>.  See
L</File rotation>.

=item * C<script_name>

Script name reported to syslog.  Auto-detected from C<$0> if not supplied.

=item * C<timestamp_format>

How C<%timestamp%>, and the C<timestamp> key of C<format =E<gt> 'json'>,
are written.  Either a L<POSIX/strftime> pattern (default
C<%Y-%m-%d %H:%M:%S>) or one of these names (case-insensitive):

  iso8601, rfc3339   2026-10-03T20:14:23-04:00, or 2026-10-04T00:14:23Z with utc

The pattern may also use:

  %N        fractional seconds, 9 digits (nanoseconds)
  %3N       fractional seconds, 3 digits (milliseconds); any width 1-9
  %z        UTC offset as +hhmm (on every platform, unlike some strftimes)
  %:z       UTC offset as +hh:mm, as RFC 3339 needs
  %Z        the time-zone name; "UTC" when utc is set
  %%        a literal %

Fractional seconds come from L<Time::HiRes> and are truncated, not rounded;
digits beyond the system clock's resolution (usually microseconds) are
noise.  The timestamp is taken once per message, so every backend shows the
same time.

=item * C<timestamp_precision>

The number of fractional-second digits, 0-9 (default 0), added after the
seconds (each C<%S>) of whichever C<timestamp_format> is in use:

  Log::Abstraction->new(timestamp_format => 'rfc3339', timestamp_precision => 3, utc => 1);
  # 2026-10-04T00:14:24.094Z

=item * C<utc>

If true, timestamps are in UTC rather than local time.

=item * C<verbose>

When using the default Log::Log4perl backend, raises the logging level to
DEBUG when set to a true value.

=back

=head3 Returns

A blessed C<Log::Abstraction> object.

=head3 Side Effects

Loads C<File::Basename> if C<syslog> is configured (either at the top level
or in a C<logger> hash) and C<script_name> is not supplied.  Loads
C<Log::Log4perl> if no backend (C<logger>, C<file>, C<fd> or C<array>) is
specified.

=head3 Example

  my $logger = Log::Abstraction->new(
      level  => 'debug',
      logger => \@messages,
  );

  my $clone = $logger->new(level => 'info');

=head3 API SPECIFICATION

=head4 Input

  {
      carp_on_warn   => { type => 'boolean', optional => 1 },
      config_file    => { type => 'string',  optional => 1 },
      croak_on_error => { type => 'boolean', optional => 1 },
      ctx            => { optional => 1 },
      format         => { type => 'string',  optional => 1 },
      level          => { type => 'string',  regex => qr/^(trace|debug|info(?:rmational)?|notice|warn(?:ing)?|err(?:or)?|crit(?:ical)?|fatal|alert|emerg(?:ency)?|panic)$/i, optional => 1 },
      logger         => { optional => 1 },
      max_messages   => { type => 'integer', min => 0, optional => 1 },
      rotate_interval => { type => 'string', regex => qr/^(hourly|daily|weekly|monthly)$/i, optional => 1 },
      rotate_keep    => { type => 'integer', min => 0, optional => 1 },
      rotate_size    => { type => 'string',  regex => qr/^\s*[1-9]\d*\s*[kmg]?b?\s*$/i, optional => 1 },
      script_name    => { type => 'string',  optional => 1 },
      timestamp_format    => { type => 'string', min => 1, optional => 1 },
      timestamp_precision => { type => 'integer', min => 0, max => 9, optional => 1 },
      utc            => { type => 'boolean', optional => 1 },
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
  "<class>: max_messages must be a          max_messages is negative or not a number.
    non-negative integer, not '<v>'"
  "<class>: rotate_size must be a           rotate_size is not, e.g., 1048576, 512K,
    positive number of bytes, optionally    10M or 1G.
    with K, M or G, not '<v>'"
  "<class>: rotate_interval must be         rotate_interval is not one of those names.
    hourly, daily, weekly or monthly,
    not '<v>'"
  "<class>: rotate_keep must be a           rotate_keep is negative or not a number.
    non-negative integer, not '<v>'"
  "<class>: timestamp_format must be a      timestamp_format is undef, empty or a
    non-empty string"                       reference.
  "<class>: timestamp_precision must be     timestamp_precision is not a whole
    an integer from 0 to 9, not '<v>'"      number of digits from 0 to 9.
  "<class>: invalid <backend> level '<l>'"  A backend's 'level' (file, fd, array,
                                            sendmail, journald) is neither a level
                                            name nor 0-7.  (A bad syslog 'level'
                                            gives "invalid syslog level", as above.)
  "<class>: the <backend> format must be   A backend's 'format' is undef, empty or
    a non-empty string"                     a reference.
  "<class>: the <backend> hash needs a      The hash form of file, fd or array has
    '<backend>' key"                        no destination (e.g. file => { level =>
                                            'info' } without a 'file' key).
  "<class>: the sendmail backend needs      The sendmail sub-hash has no 'to' key.
    a 'to' address"
  "<class>: invalid journald field name     An extra journald key, upper-cased, is not
    '<k>'"                                  [A-Z0-9_] or starts with '_'.

The following are not raised by C<new()> but later, by the logging methods
(C<trace>, C<debug>, C<info>, C<notice>, C<warn>, C<error>, C<fatal>,
C<critical>, C<alert>, C<emergency>), when
a message that passes the level threshold reaches the backend concerned.
Croaks are configuration errors; delivery failures only carp, because a
logging failure must never crash the application.

  Croak                                     Meaning / Action
  ----------------------------------------  -----------------------------------------
  "<class>: Invalid file name: <path>"      A file path (logger string, 'file' key or
                                            logger hash 'file') contains one of
                                            < > | * ? ; ! ` $ " or a control
                                            character, or contains '..'.
  "<class>: Invalid SMTP host: <host>"      The sendmail 'host' contains characters
                                            other than A-Z a-z 0-9 . -
  "<class>: Invalid SMTP port: <port>"      The sendmail 'port' is not an integer in
                                            1-65535.
  "<class>: Don't know how to deal with     A logger hash has none of the keys file,
    the <level> message"                    array, fd, syslog, journald or sendmail.
  "<class>: <object class> doesn't know     An object logger has no method for this
    how to deal with the <level> message"   level.  (notice falls back to info.)
  "<class>: configuration error, no         logger is a reference of an unsupported
    handler written for the <level>         type, e.g. a SCALAR or GLOB reference.
    message"

  Carp                                      Meaning / Action
  ----------------------------------------  -----------------------------------------
  "Failed to send email: <error>"           SMTP delivery failed.  The other backends
                                            still receive the message.
  "<class>: syslog failed: <error>"         Sys::Syslog::syslog() died.
  "<class>: journald send failed: <error>"  The journald socket could not be reached.
                                            Given once, then not again until a send
                                            succeeds.

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
      CROAK on an invalid timestamp_format or timestamp_precision
      CROAK on an invalid rotate_size, rotate_interval or rotate_keep, and
        normalise rotate_size to bytes
      shallow-clone self merged with override args
      validate and store new level integer if level given in args
      copy message history list
      count the clone as a user of an open syslog connection
      RETURN clone

    IF syslog requested (top level or in a logger hash) and script_name
    not supplied:
      auto-detect script name via File::Basename
      CROAK if still undefined

    IF logger arg is a Log::Abstraction object:
      CROAK (would create a needless forwarding loop)

    IF no logger AND no file AND no fd AND no array:
      load Log::Log4perl, easy_init at DEBUG or ERROR per verbose flag
      store Log4perl logger as the backend

    Normalise and validate level:
      IF level is an arrayref, take first element
      lc() the level string
      CROAK if not in syslog_values lookup
      default to $DEFAULT_LEVEL if not supplied

    CROAK if max_messages is given and is not a non-negative integer
    CROAK if timestamp_format is empty or not a string, or
      timestamp_precision is not an integer 0-9
    CROAK if rotate_size is not a positive size, rotate_interval is not
      hourly/daily/weekly/monthly, or rotate_keep is not a non-negative
      integer; normalise rotate_size to bytes

    FOR each backend (top-level file/fd/array, and the logger hash's
    file/fd/array/syslog/sendmail/journald) given as a hash:
      CROAK if a file/fd/array hash lacks its destination key (its own name)
      CROAK if its 'level' is not a level name or 0-7
      CROAK if its 'format' is undef, empty or not a string

    IF logger is a hash:
      CROAK if a sendmail sub-hash has no 'to' address
      CROAK if an extra journald key is not a valid journald field name

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
			Carp::croak("$class: ", $args{'config_file'}, ': File not readable');
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
			Carp::croak("$class: Can't load configuration from ", $args{'config_file'});
		}
	}

	# Handle function-call form: Log::Abstraction::new() with no class
	if(!defined($class)) {
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# Called on an existing instance -- return a shallow clone
		_check_timestamp_args(ref($class), \%args);
		_check_rotate_args(ref($class), \%args);
		my $clone = bless { %{$class}, %args }, ref($class);
		if(my $level = $args{'level'}) {
			$level = lc($level);
			if(!defined($syslog_values{$level})) {
				Carp::croak("$class: invalid syslog level '$level'");
			}
			$clone->{level} = $syslog_values{$level};
		}
		# Copy the message history so parent and clone diverge independently
		$clone->{messages} = [ @{$class->{messages}} ];
		# The clone shares the parent's open syslog connection
		$syslog_open_count++ if($clone->{_syslog_opened});
		return $clone;
	}

	# Auto-detect script name when syslog backend is requested, either as a
	# top-level key or (the documented form) inside a HASH logger
	my $wants_syslog = $args{'syslog'}
		|| ((ref($args{'logger'}) eq 'HASH') && $args{'logger'}->{'syslog'});
	if($wants_syslog && !$args{'script_name'}) {
		require File::Basename;
		$args{'script_name'} = File::Basename::basename($ENV{'SCRIPT_NAME'} || $0);
		Carp::croak("$class: syslog needs to know the script name")
			if(!defined($args{'script_name'}));
	}

	# Reject attempts to use this module as its own logger backend
	if(defined(my $logger = $args{logger})) {
		if(Scalar::Util::blessed($logger) && (ref($logger) eq __PACKAGE__)) {
			Carp::croak(
				"$class: attempt to encapsulate ",
				__PACKAGE__,
				' as a logging class, that would add a needless indirection',
			);
		}
	} elsif(!$args{'file'} && !$args{'fd'} && !$args{'array'}) {
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

	# Cap on the in-memory message history (undef means unlimited)
	if(defined(my $max = $args{'max_messages'})) {
		if($max !~ /^\d+$/) {
			Carp::croak("$class: max_messages must be a non-negative integer, not '$max'");
		}
	}

	_check_timestamp_args($class, \%args);
	_check_rotate_args($class, \%args);

	# Validate the backends' own 'level' and 'format' keys now, rather than
	# have a bad value silently drop messages at log time: the top-level
	# file/fd/array and the HASH logger's sub-backends
	my @backends = map { [ $_, $args{$_} ] } grep { defined($args{$_}) } qw(file fd array);
	if(ref($args{'logger'}) eq 'HASH') {
		my $hash = $args{'logger'};
		push @backends, map { [ $_, $hash->{$_} ] }
			grep { defined($hash->{$_}) } qw(file fd array syslog sendmail journald);
	}
	for my $backend (@backends) {
		my ($name, $value) = @{$backend};
		next if(ref($value) ne 'HASH');
		if(($name =~ /^(?:file|fd|array)$/) && !$value->{$name}) {
			Carp::croak("$class: the $name hash needs a '$name' key");
		}
		my $sub_level = $value->{'level'};
		if(defined($sub_level) && !defined(_level_number($sub_level))) {
			Carp::croak("$class: invalid $name level '$sub_level'");
		}
		if(exists($value->{'format'})) {
			my $format = $value->{'format'};
			if(!defined($format) || ref($format) || ($format eq '')) {
				Carp::croak("$class: the $name format must be a non-empty string");
			}
		}
	}

	if(ref($args{'logger'}) eq 'HASH') {
		my $hash = $args{'logger'};

		if(exists($hash->{'sendmail'})
		   && ((ref($hash->{'sendmail'}) ne 'HASH') || !$hash->{'sendmail'}->{'to'})) {
			Carp::croak("$class: the sendmail backend needs a 'to' address");
		}

		if(ref($hash->{'journald'}) eq 'HASH') {
			for my $key (keys %{$hash->{'journald'}}) {
				next if(lc($key) =~ /^(?:socket|identifier|level|format)$/);
				if(uc($key) !~ $RE_JOURNALD_FIELD) {
					Carp::croak("$class: invalid journald field name '$key'");
				}
			}
		}
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
# _level_number -- convert a level name or number to its numeric threshold
#
# Purpose:      Let sub-backend 'level' keys (syslog, sendmail) be given
#               either as a name ('warning', case-insensitive) or as a syslog
#               number (0-7), and compare them consistently.
# Entry:        $value -- a level name or an integer.
# Exit:         Returns the integer threshold, or undef if $value is neither
#               a recognised level name nor an integer in 0-7.
# Notes:        A pure function (no $self), called as _level_number($value).
# ---------------------------------------------------------------------------
sub _level_number :Private {
	my ($value) = @_;

	return unless defined $value;

	if($value =~ /^\d+$/) {
		return ($value <= $DEBUG) ? $value + 0 : undef;
	}
	return $syslog_values{lc($value)};
}

# ---------------------------------------------------------------------------
# _wants -- does a backend's own level let a message through?
#
# Purpose:      One test for every sub-backend's 'level' key.
# Entry:        $level         -- the message's level name.
#               $backend_level -- the backend's 'level' (a name or 0-7), or
#                                 undef for none.
# Exit:         Returns true if the backend has no level, or the message is
#               at that level or more severe.
# Notes:        A pure function (no $self), called as _wants($level, $bl).
#               The logger's own level has already been applied by _log.
# ---------------------------------------------------------------------------
sub _wants :Private {
	my ($level, $backend_level) = @_;

	return 1 unless(defined($backend_level));
	return $syslog_values{$level} <= (_level_number($backend_level) // -1);
}

# ---------------------------------------------------------------------------
# _backend -- split a file, fd or array backend's value into its parts
#
# Purpose:      These backends take either their destination (a path, a
#               handle, an array ref) or a hash holding the destination under
#               the backend's own name plus optional 'level' and 'format'.
# Entry:        $name  -- 'file', 'fd' or 'array'.
#               $value -- the configured value.
# Exit:         Returns (destination, level, format); level and format are
#               undef for the plain form.
# Notes:        A pure function (no $self), called as _backend($name, $value).
#               Only an unblessed hash is the hash form, so a handle object
#               is still a destination.
# ---------------------------------------------------------------------------
sub _backend :Private {
	my ($name, $value) = @_;

	return ($value, undef, undef) unless(ref($value) eq 'HASH');
	return ($value->{$name}, $value->{'level'}, $value->{'format'});
}

# ---------------------------------------------------------------------------
# _to_json -- encode a data structure as a compact, canonical JSON string
#
# Purpose:      One place to build and use the cached JSON::PP encoder, for
#               format => 'json' lines and for reference-valued fields.
# Entry:        $data -- a reference to encode.
# Exit:         Returns a character string (not UTF-8 bytes).  Falls back to
#               Perl's stringification if the data can't be encoded (e.g. it
#               is nested too deeply), so logging never dies.
# Notes:        A pure function (no $self), called as _to_json($data).
#               Blessed objects and other values JSON can't represent are
#               encoded as null.
# ---------------------------------------------------------------------------
sub _to_json :Private {
	my ($data) = @_;

	require JSON::PP;
	$json_encoder ||= JSON::PP->new->canonical(1)->allow_blessed(1)->allow_unknown(1);
	my $json = eval { $json_encoder->encode($data) };
	return $json // "$data";
}

# ---------------------------------------------------------------------------
# _field_string -- turn one structured-field value into a plain string
#
# Purpose:      Text backends and journald need a string for each field.
# Entry:        $value -- the field value: a scalar, an object, or a reference.
# Exit:         Returns '' for undef, the stringified object for a blessed
#               value (so overloaded stringification is honoured), JSON for
#               any other reference, and the value itself otherwise.
# Notes:        A pure function (no $self), called as _field_string($value).
# ---------------------------------------------------------------------------
sub _field_string :Private {
	my ($value) = @_;

	return '' unless defined($value);
	return "$value" if(!ref($value) || Scalar::Util::blessed($value));
	return _to_json($value);
}

# ---------------------------------------------------------------------------
# _fields_text -- render structured fields as logfmt-style key=value pairs
#
# Purpose:      Text formats, syslog, email and object backends have no field
#               support, so the fields are appended to the message as text.
# Entry:        $fields -- a hashref of field names to values.
# Exit:         Returns 'key=value key2="value 2"', with keys in sorted order.
# Notes:        A pure function (no $self), called as _fields_text($fields).
#               Characters outside [\w.-] in a key become '_'.  A value that
#               is empty or contains white space, '"', '=' or '\' is quoted,
#               with '"' and '\' escaped and control characters written as
#               \n, \r, \t or \xNN, so a field can never contain a line break
#               and forge a log entry.
# ---------------------------------------------------------------------------
sub _fields_text :Private {
	my ($fields) = @_;

	my %escapes = ("\n" => '\n', "\r" => '\r', "\t" => '\t');
	my @pairs;
	for my $name (sort keys %{$fields}) {
		(my $key = $name) =~ s/[^\w.\-]/_/g;
		my $value = _field_string($fields->{$name});
		if(($value eq '') || ($value =~ /[\s"=\\\x00-\x1F\x7F]/)) {
			$value =~ s/(["\\])/\\$1/g;
			$value =~ s/([\x00-\x1F\x7F])/$escapes{$1} \/\/ sprintf('\\x%02x', ord($1))/ge;
			$value = qq{"$value"};
		}
		push @pairs, "$key=$value";
	}
	return join(' ', @pairs);
}

# ---------------------------------------------------------------------------
# _check_timestamp_args -- validate the timestamp options given to new()
#
# Purpose:      Croak in new() (and when cloning) on a bad timestamp_format
#               or timestamp_precision, rather than log a broken timestamp.
# Entry:        $class -- the class name, for the error message.
#               $args  -- hashref of constructor arguments.
# Exit:         Returns nothing; croaks on an invalid value.
# Notes:        A pure function (no $self), called as
#               _check_timestamp_args($class, \%args).
# ---------------------------------------------------------------------------
sub _check_timestamp_args :Private {
	my ($class, $args) = @_;

	if(exists($args->{'timestamp_format'})) {
		my $format = $args->{'timestamp_format'};
		if(!defined($format) || ref($format) || ($format eq '')) {
			Carp::croak("$class: timestamp_format must be a non-empty string");
		}
	}
	if(defined(my $precision = $args->{'timestamp_precision'})) {
		if(($precision !~ /^\d+$/) || ($precision > $MAX_TIMESTAMP_PRECISION)) {
			Carp::croak("$class: timestamp_precision must be an integer from 0 to $MAX_TIMESTAMP_PRECISION, not '$precision'");
		}
	}
	return;
}

# ---------------------------------------------------------------------------
# _utc_offset -- the local time zone's offset from UTC at a given time
#
# Purpose:      Portable %z/%:z, and local period boundaries for rotation.
# Entry:        $secs -- epoch seconds.
#               $utc  -- true to return 0 (timestamps are in UTC).
# Exit:         Returns the offset in seconds (negative west of Greenwich).
# Notes:        A pure function (no $self), called as _utc_offset($secs, $utc).
#               The offset is what the local broken-down time would be as
#               UTC, less the real time.  The year is passed in full so that
#               Time::Local doesn't guess a century.
# ---------------------------------------------------------------------------
sub _utc_offset :Private {
	my ($secs, $utc) = @_;

	return 0 if($utc);
	my @tm = localtime($secs);
	return Time::Local::timegm(@tm[0..4], $tm[5] + 1900) - $secs;
}

# ---------------------------------------------------------------------------
# _check_rotate_args -- validate and normalise the file-rotation options
#
# Purpose:      Croak in new() (and when cloning) on a bad rotate_size,
#               rotate_interval or rotate_keep, rather than fail at log time.
# Entry:        $class -- the class name, for the error message.
#               $args  -- hashref of constructor arguments; changed in place.
# Exit:         Returns nothing.  rotate_size becomes a number of bytes and
#               rotate_interval is lower-cased.  Croaks on an invalid value.
# Notes:        A pure function (no $self), called as
#               _check_rotate_args($class, \%args).
# ---------------------------------------------------------------------------
sub _check_rotate_args :Private {
	my ($class, $args) = @_;

	if(defined(my $size = $args->{'rotate_size'})) {
		if($size !~ /^\s*(\d+)\s*([kmg]?)b?\s*$/i || ($1 == 0)) {
			Carp::croak("$class: rotate_size must be a positive number of bytes, optionally with K, M or G, not '$size'");
		}
		$args->{'rotate_size'} = $1 * $SIZE_UNITS{lc($2)};
	}
	if(defined(my $interval = $args->{'rotate_interval'})) {
		if(!$ROTATE_PERIOD{lc($interval)}) {
			Carp::croak("$class: rotate_interval must be hourly, daily, weekly or monthly, not '$interval'");
		}
		$args->{'rotate_interval'} = lc($interval);
	}
	if(defined(my $keep = $args->{'rotate_keep'})) {
		if($keep !~ /^\d+$/) {
			Carp::croak("$class: rotate_keep must be a non-negative integer, not '$keep'");
		}
	}
	return;
}

# ---------------------------------------------------------------------------
# _rotate -- rotate a log file if it is too big or from an earlier period
#
# Purpose:      Size- and time-based rotation for the file backends.
# Entry:        $self -- the logger object (rotate_size, rotate_interval,
#                        rotate_keep and utc).
#               $path -- the validated log-file path, about to be appended to.
# Exit:         Returns nothing.  Croaks if a rename fails (autodie);
#               _write_line calls this in an eval of its own, so the line is
#               still written.
# Side effects: Renames FILE to FILE.1, FILE.1 to FILE.2 and so on, deleting
#               FILE.<rotate_keep>; with rotate_keep 0, deletes FILE.
# Notes:        Called before each write, so it costs one stat() per line.
#               Time-based rotation compares the file's last-modified time
#               with now, so a file not written to for a while rotates on the
#               next write.  Not safe for several processes rotating the same
#               file; use logrotate for that.
#
# Pseudocode:
#   FUNCTION _rotate(self, path)
#     RETURN unless stat(path) succeeds (no file yet)
#     due = rotate_size AND file size >= rotate_size
#     IF NOT due AND rotate_interval:
#       period = ROTATE_PERIOD{rotate_interval}
#       due = period(mtime) < period(now), each with its own UTC offset
#     RETURN unless due
#     keep = rotate_keep // 5
#     IF keep == 0: unlink path; RETURN
#     unlink path.keep if it exists
#     FOR i = keep-1 down to 1: rename path.i to path.(i+1) if it exists
#     rename path to path.1
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _rotate :Private {
	my ($self, $path) = @_;

	my @st = stat($path) or return;
	my ($size, $mtime) = @st[7, 9];

	my $due = $self->{'rotate_size'} && ($size >= $self->{'rotate_size'});
	if(!$due && (my $interval = $self->{'rotate_interval'})) {
		my $utc = $self->{'utc'};
		my $period = $ROTATE_PERIOD{$interval};
		my $now = time();
		$due = $period->($mtime, _utc_offset($mtime, $utc), $utc) < $period->($now, _utc_offset($now, $utc), $utc);
	}
	return unless($due);

	my $keep = $self->{'rotate_keep'} // $DEFAULT_ROTATE_KEEP;
	if($keep == 0) {
		unlink($path);
		return;
	}
	# Unlink before each rename: Windows can't rename onto an existing file
	unlink("$path.$keep") if(-e "$path.$keep");
	for my $i (reverse(1 .. $keep - 1)) {
		rename("$path.$i", "$path." . ($i + 1)) if(-e "$path.$i");
	}
	rename($path, "$path.1");
	return;
}

# ---------------------------------------------------------------------------
# _timestamp -- the time of a log call, formatted for log lines
#
# Purpose:      Single source of %timestamp% and the JSON 'timestamp' value,
#               honouring timestamp_format, utc and timestamp_precision.
# Entry:        $self -- the logger object.
#               $now  -- optional epoch seconds, possibly fractional
#                        (default: Time::HiRes::time()).
# Exit:         Returns the formatted timestamp string.
# Notes:        Extends strftime with %N (fractional seconds; %3N, %6N etc.
#               give that many digits, truncated, not rounded), %z (+hhmm)
#               and %:z (+hh:mm), computed here because Windows' strftime
#               gives a zone name for %z; and in UTC, %Z is 'UTC'.  A '%%'
#               is passed through, so '%%N' is a literal '%N'.
#
# Pseudocode:
#   FUNCTION _timestamp(self, now)
#     now  = now // Time::HiRes::time(); secs = int(now)
#     tm   = utc ? gmtime(secs) : localtime(secs)
#     format = timestamp_format, or the default
#       'iso8601'/'rfc3339' (any case) -> '%Y-%m-%dT%H:%M:%S' + ('Z' if utc, else '%:z')
#     IF timestamp_precision > 0: follow each %S with '.%<precision>N'
#     Replace, in one pass:
#       %%  -> %% (left for strftime)
#       %nN -> first n (default 9) digits of the fraction of now
#       %z  -> +hhmm, %:z -> +hh:mm (offset = timegm(tm) - secs; 0 in UTC)
#       %Z  -> 'UTC' if utc (else left for strftime)
#     RETURN strftime(format, tm)
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _timestamp :Private {
	my ($self, $now) = @_;

	$now //= Time::HiRes::time();
	my $secs = int($now);
	my $utc  = $self->{'utc'};
	my @tm   = $utc ? gmtime($secs) : localtime($secs);

	my $format = $self->{'timestamp_format'} // $DEFAULT_TIMESTAMP_FORMAT;
	if($format =~ /^(?:iso8601|rfc3339)$/i) {
		$format = $RFC3339_TIMESTAMP_FORMAT . ($utc ? 'Z' : '%:z');
	}
	if(my $precision = $self->{'timestamp_precision'}) {
		$format =~ s/%(%|S)/($1 eq 'S') ? "%S.%${precision}N" : '%%'/ge;
	}

	my $offset = sub {
		my ($colon) = @_;
		my $diff = _utc_offset($secs, $utc);
		my $sign = ($diff < 0) ? '-' : '+';
		$diff = abs($diff);
		return sprintf('%s%02d%s%02d', $sign, int($diff / 3600), $colon, int(($diff % 3600) / 60));
	};

	$format =~ s/%(%|([1-9]?)N|:z|z|Z)/
		($1 eq '%') ? '%%'
		: defined($2) ? substr(sprintf('%09d', int(($now - $secs) * 1e9)), 0, $2 || $MAX_TIMESTAMP_PRECISION)
		: ($1 eq ':z') ? $offset->(':')
		: ($1 eq 'z') ? $offset->('')
		: $utc ? 'UTC' : '%Z'/gex;

	return POSIX::strftime($format, @tm);
}

# ---------------------------------------------------------------------------
# _write_line -- append one formatted line to a file path or filehandle
#
# Purpose:      Single output path for the file, fd and scalar-path backends.
# Entry:        $self   -- the logger object.
#               $target -- a validated file path, or an open filehandle.
#               $line   -- the formatted line, without trailing newline.
# Exit:         Returns nothing.
# Side effects: Appends to the file or prints to the handle.  A file path
#               is rotated first if rotate_size or rotate_interval says so.
# Notes:        Character strings are encoded to UTF-8, avoiding "Wide
#               character" warnings, unless the handle already has a
#               :utf8 or :encoding layer.  File I/O failures are silent by
#               design: an I/O error must never crash the application.
# ---------------------------------------------------------------------------
sub _write_line :Private {
	my ($self, $target, $line) = @_;

	if(ref($target)) {
		if(utf8::is_utf8($line)
		   && !grep { /^(?:utf8|encoding)/ } PerlIO::get_layers($target)) {
			utf8::encode($line);
		}
		print $target "$line\n";
		return;
	}

	utf8::encode($line) if(utf8::is_utf8($line));

	# Rotate in its own eval: if a rename fails (autodie), still write the line
	if($self->{'rotate_size'} || $self->{'rotate_interval'}) {
		eval { $self->_rotate($target) };
	}
	eval {
		open(my $fout, '>>', $target);
		print $fout "$line\n";
		close $fout;
	};
	return;
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
#               text format.  The send buffer, and so the largest datagram,
#               varies between systems: a send failing with EMSGSIZE is
#               retried with MESSAGE truncated to half the size, down to
#               $JOURNALD_MIN_PAYLOAD.
# ---------------------------------------------------------------------------
sub _journald_send :Private {
	my ($self, $socket_path, %fields) = @_;

	# The protocol carries bytes, and binary framing declares a byte length,
	# so encode character strings to UTF-8 first
	for my $key (keys %fields) {
		my $value = defined($fields{$key}) ? "$fields{$key}" : '';
		utf8::encode($value) if(utf8::is_utf8($value));
		$fields{$key} = $value;
	}

	# Build the datagram payload from all supplied fields
	my $build = sub {
		my $payload = '';
		for my $key (sort keys %fields) {
			my $value = $fields{$key};
			if($value =~ /[\n\0]/) {
				# Binary framing: field-name LF uint64LE-length value LF.
				# The length is packed as two 32-bit little-endian words
				# because pack('Q') dies on perls without 64-bit integers
				my $len = length($value);
				$payload .= $key . "\n"
					. pack('VV', $len % 2**32, int($len / 2**32))
					. $value . "\n";
			} else {
				$payload .= "$key=$value\n";
			}
		}
		return $payload;
	};
	my $full = $build->();
	my $message = $fields{'MESSAGE'};

	# A datagram bigger than the socket send buffer fails outright, so
	# truncate MESSAGE to fit in $limit bytes.  The extra 8 bytes allow for
	# the message switching from text to binary framing.
	my $fit = sub {
		my $limit = shift;
		my $excess = length($full) - $limit;
		return $full if(($excess <= 0) || !defined($message));
		my $keep = length($message) - $excess - length($TRUNCATED_MARKER) - 8;
		my $cut = substr($message, 0, ($keep > 0) ? $keep : 0);
		# Don't leave a partial UTF-8 sequence at the cut
		$cut =~ s/[\xC0-\xFF][\x80-\xBF]*\z//;
		$fields{'MESSAGE'} = $cut . $TRUNCATED_MARKER;
		return $build->();
	};

	# Open a Unix-domain datagram socket, send, and close
	require Socket;
	socket(my $sock, Socket::AF_UNIX(), Socket::SOCK_DGRAM(), 0);
	my $dest = Socket::sockaddr_un($socket_path);

	{
		# send() is checked by hand: EMSGSIZE means retry smaller
		no autodie qw(send setsockopt);

		# Ask for a send buffer big enough for the largest datagram; the
		# kernel may cap it (net.core.wmem_max), which the retry handles
		setsockopt($sock, Socket::SOL_SOCKET(), Socket::SO_SNDBUF(), $JOURNALD_MAX_PAYLOAD + 1024);

		my $limit = $JOURNALD_MAX_PAYLOAD;
		while(1) {
			last if(defined(send($sock, $fit->($limit), 0, $dest)));
			my $err = $!;
			if(($err == POSIX::EMSGSIZE()) && ($limit > $JOURNALD_MIN_PAYLOAD)) {
				$limit = int($limit / 2);
				next;
			}
			close $sock;
			Carp::croak("Can't send to $socket_path: $err");
		}
	}
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
#               $fields      -- optional hashref of structured fields.
#               $timestamp   -- the formatted time of the log call, from
#                               _timestamp (computed here if undef).
#               $format      -- the backend's own format, or undef for the
#                               logger's 'format' (or the default).
# Exit:         Returns the formatted log line (without trailing newline).
# Notes:        %env_FOO% tokens are expanded with a // '' fallback so that
#               missing environment variables expand silently to empty string.
#               caller_file/caller_line are computed by _log at the correct
#               stack depth (adjusted for the extra _high_priority frame on
#               warn/error calls) so the reported location is always the
#               caller's code, not an internal dispatch frame.
#
# Pseudocode:
#   FUNCTION _format_message(self, level, str, use_class, caller_file, caller_line, fields, timestamp, format)
#     timestamp = timestamp // _timestamp()
#     format    = format // self->{'format'}
#     IF format eq 'json':
#       Build hash: timestamp, level, message, file=caller_file, line=caller_line
#                   (+ class if subclass)
#                   (+ fields, with blessed values stringified, if any)
#       RETURN _to_json(\%hash)
#              [single compact line, character string, sorted keys]
#
#     Choose default format template:
#       use_class=1 → DEFAULT_FORMAT (includes %class%)
#       use_class=0 → DEFAULT_FORMAT_NOCLASS
#     Override with format if one was supplied (non-empty)
#
#     Compute token values:
#       message   = str, plus the fields as logfmt key=value pairs if any,
#                   with each embedded line break followed by a tab, so
#                   continuation lines can't pass as new log entries
#       ulevel    = uc(level)
#       class     = blessed class if it is a subclass, else '' (base package)
#       callstack = caller_file and caller_line
#       timestamp = the timestamp argument
#
#     Expand tokens in format string in a single pass (substituted values,
#     including the message, are never rescanned for further tokens):
#       %level%       → ulevel
#       %class%       → class (may be empty)
#       %message%     → message
#       %callstack%   → callstack
#       %timestamp%   → timestamp
#       %env_FOO%     → $ENV{FOO} // '' (silent if env var unset)
#
#     RETURN formatted line string
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _format_message :Private {
	my ($self, $level, $str, $use_class, $caller_file, $caller_line, $fields, $timestamp, $format) = @_;

	$timestamp //= $self->_timestamp();
	$format //= $self->{'format'};

	# 'json' is a magic format value: emit a compact JSON object per line
	if(defined($format) && ($format eq 'json')) {
		my $bclass = Scalar::Util::blessed($self);
		my $class  = ($bclass && $bclass ne __PACKAGE__) ? $bclass : undef;
		my %obj = (
			timestamp => $timestamp,
			level     => $level,
			message   => $str,
			file      => $caller_file,
			line      => $caller_line + 0,
		);
		$obj{class} = $class if defined($class);
		if($fields) {
			# Stringify objects, which would otherwise be encoded as null
			$obj{fields} = {
				map { $_ => (Scalar::Util::blessed($fields->{$_}) ? "$fields->{$_}" : $fields->{$_}) } keys %{$fields}
			};
		}
		# Characters out (not UTF-8 bytes): _write_line does the encoding
		return _to_json(\%obj);
	}

	# Select the appropriate default when no custom format is configured ('' is falsy)
	my $default = $use_class ? $DEFAULT_FORMAT : $DEFAULT_FORMAT_NOCLASS;
	$format = $format || $default;

	my $ulevel = uc($level);

	# Suppress the class name for the base package (only show for subclasses)
	my $bclass = Scalar::Util::blessed($self);
	my $class  = ($bclass && $bclass ne __PACKAGE__) ? $bclass : '';

	# Indent continuation lines so that a message such as
	# "a\nERROR> [...] forged" can't pass as a separate log entry
	my $message = $fields ? join(' ', grep { length } $str, _fields_text($fields)) : $str;
	$message =~ s/\r\n?|\n/\n\t/g;

	my $callstack = "$caller_file $caller_line";

	my %tokens = (
		level     => $ulevel,
		class     => $class,
		message   => $message,
		callstack => $callstack,
		timestamp => $timestamp,
	);

	# Expand all tokens in one pass so substituted text (notably the message)
	# is never rescanned; otherwise a message containing "%env_SECRET%" would
	# leak the environment variable into the log
	$format =~ s/%(?:(level|class|message|callstack|timestamp)|env_(\w+))%/
		defined($1) ? $tokens{$1} : ($ENV{$2} \/\/ '')/gex;

	return $format;
}

# ---------------------------------------------------------------------------
# _log -- central dispatcher that routes a message to all active backends
#
# Purpose:      Every public logging method ultimately calls _log.  It checks
#               the current level threshold, records the message in the
#               internal history, then dispatches to the configured backend(s).
# Entry:        $self    -- the logger object.
#               $level   -- one of trace/debug/info/notice/warn/error/
#                           critical/alert/emergency.
#               @messages -- one or more message strings (or a single arrayref),
#                           optionally followed by a hashref of structured fields.
# Exit:         Returns nothing (void).  Croaks on configuration errors.
# Side effects: Appends to $self->{messages}.  May write to a file, fd,
#               array, syslog, or email backend.  May load Email::* modules.
# Notes:        Enforced private: croaks if called from outside this package.
#               The caller file/line is resolved past the _high_priority frame
#               (warn/error) and any Log::Any frames, so it is the user's code.
#
# Pseudocode:
#   FUNCTION _log(self, level, messages...)
#     CROAK if caller package is not this package (private method guard)
#     CROAK if level is not a recognised syslog level name
#     RETURN early if syslog_values{level} > self->{'level'} (below threshold)
#
#     IF more than one argument AND the last is an unblessed hashref:
#       Pop it as the structured fields (a shallow copy; undef if empty)
#     Flatten single-arrayref argument to a list; filter out undefs; join to $str
#     $text = $str plus the fields as logfmt key=value pairs (for backends
#       with no field support: syslog, email, objects)
#     Push { level, message, fields? } onto self->{messages} (always recorded);
#       drop the oldest entries beyond max_messages
#     Set $class = '' for base package, else the blessed class name
#     Resolve caller file/line; format the timestamp once (_timestamp),
#       shared by every file/fd backend
#     render(format) = _format_message(..., format), cached per format;
#       undef format means the logger's own
#     Every backend below is skipped unless _wants(level, its own level);
#       file/fd/array may be the hash form { <name> => destination, level, format }
#       (split by _backend)
#
#     IF self->{'logger'} is a CODE ref:
#       Build args hashref { class, file, line, level, message, ctx?, fields? }
#       Call logger->( args )
#
#     ELSIF self->{'logger'} is an ARRAY ref:
#       Push { level, message, fields? }
#
#     ELSIF self->{'logger'} is a HASH ref:
#       IF 'file' key present:
#         validate path; write render(its format) via _write_line
#       IF 'array' key present:
#         push { level, message, fields? }, message = render(its format)
#           if it has one
#       IF 'sendmail' key present with a 'to' address:
#         IF level passes threshold AND not throttled:
#           CROAK if host contains unsafe characters
#           CROAK if port is out of 1-65535 range
#           (eval) load Email::* modules; build email with sanitised headers
#                  and as the body render(its format) if it has one,
#                  else $text; send via SMTP transport
#           Record timestamp for throttle on success; a failure is carped
#           and the remaining backends still run
#       IF 'syslog' key present:
#         IF level passes threshold:
#           Open syslog connection on first use (setlogsock, openlog)
#           (eval) map level to syslog priority; call Sys::Syslog::syslog
#                  with a '%s' format and render(its format) or $text;
#                  carp on failure
#       IF 'journald' key present:
#         Map level to syslog PRIORITY integer
#         Build fields: MESSAGE (render(its format), or $str), PRIORITY,
#           SYSLOG_IDENTIFIER, plus any extra from the config hash (but not
#           socket/identifier/level/format), plus the structured fields (names
#           upper-cased and sanitised; they can't replace the first three)
#         (eval) _journald_send(socket_path, %fields); carp on the first
#                failure only, until a send succeeds again
#       IF 'fd' key present:
#         write render(its format) to the handle via _write_line
#       ELSIF no actionable key (no file/array/syslog/sendmail/journald/fd):
#         CROAK (configuration error)
#     (file and fd writes go through _write_line, which UTF-8 encodes
#      character strings and never lets an I/O error escape)
#
#     ELSIF self->{'logger'} is an unblessed scalar (file path):
#       Validate path; format line; (eval) open>>file, print, close
#
#     ELSIF self->{'logger'} is a blessed object:
#       Map 'notice' to 'info', and critical/alert/emergency to 'fatal' or
#         else 'error', for backends without them (e.g. Log::Log4perl)
#       CROAK if object cannot handle the level
#       Call $logger->$level(@messages), plus the fields as logfmt text
#
#     ELSIF self->{'array'} top-level key:
#       Push { level, message, fields? }, as for the 'array' sub-backend
#
#     IF self->{'file'} top-level key (and its own level lets it through):
#       Validate path; write render(its format) via _write_line
#     IF self->{'fd'} top-level key (and its own level lets it through):
#       write render(its format) to the handle via _write_line
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _log :Private {
	my ($self, $level, @messages) = @_;

	# Reject direct calls from outside this package (also enforced by :Private)
	if(!(caller)[0]->isa(__PACKAGE__)) {
		Carp::croak('Illegal Operation: _log is a private method');
	}

	# Logging must not disturb the caller's error state: code such as
	# eval { ... }; if($@) { $log->debug(...); die $@ } relies on it, and
	# the backends' own evals and I/O would otherwise reset $@ and $!
	local ($@, $!);

	# Sanity-check the level (should not be reachable in normal use)
	if(!defined($syslog_values{$level})) {
		Carp::croak(ref($self), ": Invalid level '$level'");
	}

	# Drop messages that fall below the configured threshold
	if($syslog_values{$level} > $self->{'level'}) {
		return;
	}

	# A trailing hashref after the message holds structured fields, e.g.
	# $log->info('login', { user_id => 42 }).  Copy it so that the caller
	# changing it later doesn't rewrite the history
	my $fields;
	if((scalar(@messages) > 1) && (ref($messages[-1]) eq 'HASH')) {
		$fields = pop @messages;
		$fields = %{$fields} ? { %{$fields} } : undef;
	}

	# Flatten a single arrayref argument to a plain list
	if((scalar(@messages) == 1) && (ref($messages[0]) eq 'ARRAY')) {
		@messages = @{$messages[0]};
	}

	# Remove any undef elements before joining
	@messages = grep { defined } @messages;
	my $str = join('', @messages);
	chomp($str);

	# Backends with no notion of fields get them appended as text
	my $fields_text = $fields ? _fields_text($fields) : undef;
	my $text = $fields ? join(' ', grep { length } $str, $fields_text) : $str;

	# The entry recorded by the history and the array backends
	my @entry = (level => $level, message => $str, ($fields ? (fields => $fields) : ()));

	# Record in the internal message history regardless of backend,
	# discarding the oldest entries beyond max_messages
	my $history = $self->{messages};
	push @{$history}, { @entry };
	if(defined(my $max = $self->{'max_messages'})) {
		splice(@{$history}, 0, scalar(@{$history}) - $max) if(scalar(@{$history}) > $max);
	}

	# Compute class once; suppress the package name for base-class instances
	my $class = Scalar::Util::blessed($self) || $self;
	if($class eq __PACKAGE__) {
		$class = '';
	}

	# Resolve caller file/line at the correct stack depth.
	# For trace/debug/info/notice: _log ← public_method ← user → depth=1
	# For warn/error: _log ← _high_priority ← public_method ← user → depth=2
	# Frames inside Log::Any (its proxy and our adapter) are skipped too, so
	# messages routed through Log::Any report the user's code
	my $depth = ((caller(1))[3] // '') =~ /::_high_priority$/ ? 2 : 1;
	while((caller($depth + 1))[0] && (((caller($depth))[0] // '') =~ /^Log::Any(?:::|$)/)) {
		$depth++;
	}
	my $caller_file = (caller($depth))[1];
	my $caller_line = (caller($depth))[2];

	# One timestamp per message, so that every backend shows the same time
	my $timestamp = $self->_timestamp();

	# Format the message for a backend: $format is its own format, or undef
	# for the logger's.  Each format is only rendered once per message
	my $use_class = ($class ne '') ? 1 : 0;
	my %rendered;
	my $render = sub {
		my ($format) = @_;
		return $rendered{$format // ''} //= $self->_format_message(
			$level, $str, $use_class, $caller_file, $caller_line, $fields, $timestamp, $format,
		);
	};

	# -----------------------------------------------------------------------
	# Dispatch to the configured backend(s)
	# -----------------------------------------------------------------------
	if(my $logger = $self->{'logger'}) {
		if(ref($logger) eq 'CODE') {
			# CODE-ref backend: build the args hashref and invoke the callback
			my $args = {
				class   => Scalar::Util::blessed($self) || __PACKAGE__,
				file    => $caller_file,
				line    => $caller_line,
				level   => $level,
				message => \@messages,
			};
			if(my $ctx = $self->{ctx}) {
				$args->{ctx} = $ctx;
			}
			$args->{fields} = $fields if($fields);
			$logger->($args);
		} elsif(ref($logger) eq 'ARRAY') {
			# ARRAY-ref backend: push a simple hashref
			push @{$logger}, { @entry };
		} elsif(ref($logger) eq 'HASH') {
			# HASH backend: route to whichever sub-keys are present

			# Each sub-backend may have its own 'level' and 'format' (file,
			# fd and array in their hash form; see _backend)

			# -- file sub-backend -------------------------------------------
			my ($raw_file, $file_level, $file_format) = _backend('file', $logger->{'file'});
			if($raw_file && _wants($level, $file_level)) {
				my $file = $self->_validate_file_path($raw_file);
				$self->_write_line($file, $render->($file_format));
			}

			# -- array sub-backend ------------------------------------------
			# With a format, the entry's message is the formatted line
			my ($array, $array_level, $array_format) = _backend('array', $logger->{'array'});
			if($array && _wants($level, $array_level)) {
				push @{$array}, { @entry, (defined($array_format) ? (message => $render->($array_format)) : ()) };
			}

			# -- sendmail sub-backend ---------------------------------------
			# ('to' and 'level' have been validated by new())
			if(exists($logger->{'sendmail'}) && exists($logger->{'sendmail'}->{'to'})) {
				my $sm = $logger->{'sendmail'};

				# Check the level threshold for email (undef means send always)
				if(_wants($level, $sm->{'level'})) {

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
							$email->body_set(defined($sm->{'format'}) ? $render->($sm->{'format'}) : $text);

							my $transport = Email::Sender::Transport::SMTP->new({
								host => $host,
								port => $port,
							});
							# A class method, rather than the exported sendmail(),
							# so that nothing is imported into this package
							Email::Sender::Simple->send($email, { transport => $transport });
						};

						# A delivery failure must not stop the remaining backends
						# from receiving this message
						if($@) {
							Carp::carp("Failed to send email: $@");
						} else {
							# Record send time for the throttle on success
							$self->{_last_email_sent} = time();
						}
					}
				}
			}

			# -- syslog sub-backend -----------------------------------------
			if(my $syslog = $logger->{'syslog'}) {
				if(_wants($level, $syslog->{'level'})) {

					# Open the persistent syslog connection on first use
					if(!$self->{_syslog_opened}) {
						my $facility = delete $syslog->{'facility'} || $DEFAULT_SYSLOG_FACILITY;
						my $min_level = delete $syslog->{'level'};
						my $format = delete $syslog->{'format'};

						# Accept 'server' as an alias for 'host' (CHI convention)
						if($syslog->{'server'}) {
							$syslog->{'host'} = delete $syslog->{'server'};
						}
						Sys::Syslog::setlogsock($syslog) if(scalar keys %{$syslog});
						$syslog->{'facility'} = $facility;
						$syslog->{'level'}    = $min_level if(defined($min_level));
						$syslog->{'format'}   = $format if(defined($format));

						Sys::Syslog::openlog($self->{script_name}, $DEFAULT_SYSLOG_OPTIONS, $DEFAULT_SYSLOG_IDENTITY);
						$self->{_syslog_opened} = 1;
						$syslog_open_count++;
					}

					# Map internal level names to syslog priority strings.  The
					# message is passed through '%s' so that a '%m' (or any other
					# '%' sequence) in it is logged literally.
					eval {
						my $priority = $LEVEL_TO_SYSLOG_PRIORITY{$level};
						my $facility = $syslog->{'facility'};
						my $message = defined($syslog->{'format'}) ? $render->($syslog->{'format'}) : $text;
						Sys::Syslog::syslog("$priority|$facility", '%s', $message);
					};
					if($@) {
						Carp::carp(ref($self), ": syslog failed: $@");
					}
				}
			}

			# -- journald sub-backend --------------------------------------
			# (extra field names have been validated by new())
			my $jd = $logger->{'journald'};
			if($jd && _wants($level, $jd->{'level'})) {
				# Map internal level name to journald/syslog PRIORITY integer (0=emerg, 7=debug)
				my $priority  = $syslog_values{$level};
				my $sock_path = $jd->{'socket'} || $DEFAULT_JOURNALD_SOCKET;

				# Determine the syslog identifier (script name or basename of $0)
				my $ident = $jd->{'identifier'} || $self->{'script_name'} || do {
					require File::Basename;
					File::Basename::basename($0);
				};

				# Mandatory journald fields
				my %entry = (
					MESSAGE           => defined($jd->{'format'}) ? $render->($jd->{'format'}) : $str,
					PRIORITY          => $priority,
					SYSLOG_IDENTIFIER => $ident,
				);

				# Include any extra fields from the journald config hash
				for my $key (keys %{$jd}) {
					next if lc($key) =~ /^(?:socket|identifier|level|format)$/;
					$entry{uc($key)} = $jd->{$key};
				}

				# Then the structured fields.  These weren't checked by new(),
				# so make each name valid rather than reject it: upper-case,
				# other characters to '_', no leading '_' (journald reserves
				# those for trusted fields) and at most 64 characters
				for my $key (keys %{$fields || {}}) {
					(my $name = uc($key)) =~ s/[^A-Z0-9_]/_/g;
					$name =~ s/^_+//;
					$name = substr($name, 0, $JOURNALD_MAX_FIELD_NAME);
					next if(($name eq '') || $name =~ /^(?:MESSAGE|PRIORITY|SYSLOG_IDENTIFIER)$/);
					$entry{$name} = _field_string($fields->{$key});
				}

				# Delivery failures are silent; the app must not crash on log
				# errors.  Carp only on the first failure, so that a system
				# without journald (FreeBSD, macOS) isn't flooded with warnings;
				# a later success re-arms the warning.
				if(eval { $self->_journald_send($sock_path, %entry); 1 }) {
					delete $self->{_journald_failed};
				} elsif(!$self->{_journald_failed}++) {
					Carp::carp(ref($self), ": journald send failed: $@");
				}
			}

			# -- fd sub-backend ---------------------------------------------
			if($logger->{'fd'}) {
				my ($fout, $fd_level, $fd_format) = _backend('fd', $logger->{'fd'});
				$self->_write_line($fout, $render->($fd_format)) if(_wants($level, $fd_level));

			} elsif(!$logger->{'file'} && !$logger->{'array'}
					&& !$logger->{'syslog'} && !exists($logger->{'sendmail'})
					&& !$logger->{'fd'} && !$logger->{'journald'}) {
				# Hash logger with no recognised sub-key -- configuration error
				Carp::croak(ref($self), ": Don't know how to deal with the $level message");
			}

		} elsif(!ref($logger)) {
			# Scalar-path backend: validate path then append to the file
			my $safe_path = $self->_validate_file_path($logger);
			$self->_write_line($safe_path, $render->());

		} elsif(Scalar::Util::blessed($logger)) {
			# Object backend: delegate to the method matching the level name
			if(!$logger->can($level)) {
				# Log::Log4perl has no notice(), critical(), alert() or
				# emergency(); use the nearest method it does have
				my @fallbacks = ($level eq 'notice') ? ('info')
					: ($level =~ /^(?:critical|alert|emergency)$/) ? ('fatal', 'error')
					: ();
				if(my ($method) = grep { $logger->can($_) } @fallbacks) {
					$level = $method;
				} else {
					Carp::croak(
						ref($self), ': ', ref($logger),
						" doesn't know how to deal with the $level message",
					);
				}
			}
			$logger->$level(@messages, ($fields ? ((length($str) ? ' ' : '') . $fields_text) : ()));

		} else {
			Carp::croak(ref($self),
				": configuration error, no handler written for the $level message");
		}

	} elsif($self->{'array'}) {
		# Top-level 'array' key (not nested inside logger hash)
		my ($array, $array_level, $array_format) = _backend('array', $self->{'array'});
		if(_wants($level, $array_level)) {
			push @{$array}, { @entry, (defined($array_format) ? (message => $render->($array_format)) : ()) };
		}
	}

	# -----------------------------------------------------------------------
	# Top-level 'file' and 'fd' keys (parallel to 'logger'), which may also
	# have their own level and format
	# -----------------------------------------------------------------------
	my ($top_file, $top_file_level, $top_file_format) = _backend('file', $self->{'file'});
	if($top_file && _wants($level, $top_file_level)) {
		my $file = $self->_validate_file_path($top_file);
		$self->_write_line($file, $render->($top_file_format));
	}

	my ($top_fd, $top_fd_level, $top_fd_format) = _backend('fd', $self->{'fd'});
	if($top_fd && _wants($level, $top_fd_level)) {
		$self->_write_line($top_fd, $render->($top_fd_format));
	}
}

# ---------------------------------------------------------------------------
# _high_priority -- common handler for warn(), error() and the levels above
#
# Purpose:      Extracts the warning/error text from a variety of argument
#               forms (plain list, named 'warning' key, or arrayref value),
#               then dispatches to _log and optionally to Carp.
# Entry:        $self    -- the logger object.
#               $level   -- 'warn', 'error', 'critical', 'alert' or 'emergency'.
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
#
#     IF more than one arg AND the last is an unblessed hashref:
#       Pop it as the structured fields
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
#     IF called as a class method (self is a package name, not an object):
#       IF error level or above: CROAK with warning text; RETURN
#       CARP with warning text; RETURN
#
#     Call self->_log(level, warning, fields?)
#
#     no_backend = no logger, array, file or fd configured
#
#     IF error level or above:
#       IF croak_on_error flag set OR no_backend:
#         CROAK with warning text
#
#     IF (carp_on_warn flag set OR no_backend) AND level passes threshold:
#       CARP with warning text
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _high_priority :Private {
	my $self  = shift;
	my $level = shift;    # 'warn', 'error', 'critical', 'alert' or 'emergency'

	# Preserve the caller's $@ and $! (see _log); a croak from here still
	# reaches the caller, as die sets $@ after the stack has unwound
	local ($@, $!);

	# Nothing to log if no arguments supplied
	return if(scalar(@_) == 0);

	# A trailing hashref after the message holds structured fields.  A lone
	# hashref is the warn({ warning => ... }) form, not fields
	my @fields;
	if((scalar(@_) > 1) && (ref($_[-1]) eq 'HASH')) {
		@fields = (pop @_);
	}

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

	# If called as a class method (on this package or a subclass) rather
	# than on an instance, use Carp directly
	if(!ref($self)) {
		if($syslog_values{$level} <= $ERROR) {
			Carp::croak($warning);
		}
		Carp::carp($warning);
		return;
	}

	# Log the message through the normal dispatch path
	$self->_log($level, $warning, @fields);

	# A top-level file or fd counts as a backend, as do logger and array
	my $no_backend = !defined($self->{'logger'}) && !defined($self->{'array'})
		&& !$self->{'file'} && !$self->{'fd'};

	# Optionally escalate to Carp for error-level messages
	if($syslog_values{$level} <= $ERROR) {
		if($self->{'croak_on_error'} || $no_backend) {
			Carp::croak($warning);
		}
	}

	# Optionally also emit a Carp::carp, but only for a message that passed
	# the level threshold
	if(($self->{'carp_on_warn'} || $no_backend)
	   && ($syslog_values{$level} <= $self->{'level'})) {
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

In setter mode: C<$self> (to allow chaining), or C<undef>, after a
C<Carp::carp>, if the level name is not recognised; the level is then
unchanged.  A false argument (C<undef>, C<''> or C<0>) is a get, not a set,
so levels are set by name.

=head3 Side Effects

When setting, updates C<$self-E<gt>{level}>.

=head3 Example

  $logger->level('debug');
  my $n = $logger->level();   # e.g. 7

  # Method chaining
  $logger->level('info')->info('Now at info level');

=head3 API SPECIFICATION

=head4 Input

  {
      level => { type => 'string', regex => qr/^(trace|debug|info(?:rmational)?|notice|warn(?:ing)?|err(?:or)?|crit(?:ical)?|fatal|alert|emerg(?:ency)?|panic)$/i, optional => 1 },
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
		# Setter path: validate, store and return $self for chaining.
		# Names are case-insensitive, as in new()
		if(!defined($syslog_values{lc($level)})) {
			Carp::carp(ref($self), ": invalid syslog level '$level'");
			return;    # undef signals the caller that validation failed
		}
		$self->{'level'} = $syslog_values{lc($level)};
		return $self;
	}

	# Getter path: return the numeric threshold
	return Return::Set::set_return(
		$self->{'level'},
		{ 'type' => 'integer', 'min' => 0, 'max' => 7 },
	);
}

=head2 Level detection methods

=over 4

=item is_trace

=item is_debug

=item is_info

=item is_notice

=item is_warn

=item is_error

=item is_critical

=item is_alert

=item is_emergency

=back

  if($logger->is_debug()) { ... }

Each returns a true value when a message logged with the method of the same
name (C<is_warn> for C<warn()>) would pass the logger's level threshold, so
that expensive message-building can be skipped.  They follow the current
threshold, including changes made with L</level>.  As with the levels
themselves, C<is_trace> equals C<is_debug>.  Provided for compatibility with
L<Log::Any>.

=head3 Arguments

None.

=head3 Returns

C<1> if messages at that level would be emitted; C<0> otherwise.

=head3 Example

  if($logger->is_debug()) {
      $logger->debug('Expensive diagnostic: ' . Dumper(\%state));
  }

  $logger->level('warning');
  $logger->is_warn();    # 1
  $logger->is_info();    # 0

=head3 API SPECIFICATION

=head4 Input

  {} (no arguments)

=head4 Output

  { type => 'boolean' }

=cut

# Build is_trace, is_debug, ... is_emergency.  Each is true when its level's
# syslog number is within the threshold (a lower number is more severe)
for my $level (qw(trace debug info notice warn error critical alert emergency)) {
	my $threshold = $syslog_values{$level};
	no strict 'refs';
	*{"is_$level"} = sub {
		my $self = $_[0];
		return (defined($self->{'level'}) && ($self->{'level'} >= $threshold)) ? 1 : 0;
	};
}

=head2 messages

  my $aref = $logger->messages();

Returns a reference to a shallow copy of all messages emitted through this
logger since it was created (or since the last clone).

=head3 Arguments

None.

=head3 Returns

An array reference of hashrefs, each with keys C<level> (string) and
C<message> (string), and C<fields> (hashref) when the message was logged with
L</Structured fields>.

=head3 Side Effects

None.  The returned array is a copy; modifying it does not affect the
internal history.

=head3 Example

  $logger->info('hello');
  my $msgs = $logger->messages();
  # $msgs->[0] = { level => 'info', message => 'hello' }

=head3 API SPECIFICATION

=head4 Input

  {} (no arguments)

=head4 Output

  { type => 'arrayref', element_type => { level => 'string', message => 'string', fields => 'hashref?' } }

=cut

sub messages {
	my $self = $_[0];

	return [ @{$self->{messages}} ];
}

=head2 trace

  $logger->trace(@messages);
  $logger->trace(\@messages);

Logs a message at C<trace> level.  syslog has no priority below debug, so
C<trace> shares C<debug>'s threshold: trace messages are emitted whenever
debug messages are, and are sent to syslog and journald as debug.  The
message is dropped silently when the configured level is above C<debug>.

=head3 Arguments

=over 4

=item * C<@messages>

One or more strings, or a single array reference.  All elements are joined
without a separator before storage.  May be followed by a hashref of
L</Structured fields>.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->trace('entering sub foo, args=', join(',', @args));

  # Chaining
  $logger->trace('start')->debug('details')->info('summary');

=head3 API SPECIFICATION

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under L</new>'s MESSAGES.

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

One or more strings, or a single array reference, optionally followed by
a hashref of L</Structured fields>.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->debug('Query took ', $elapsed, 'ms');

=head3 API SPECIFICATION

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under L</new>'s MESSAGES.

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

One or more strings, or a single array reference, optionally followed by
a hashref of L</Structured fields>.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->info('Server started on port ', $port);

=head3 API SPECIFICATION

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under L</new>'s MESSAGES.

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

One or more strings, or a single array reference, optionally followed by
a hashref of L</Structured fields>.

=back

=head3 Returns

C<$self>, to allow method chaining.

=head3 Side Effects

Appends to the internal message history and dispatches to configured backends.

=head3 Example

  $logger->notice('Configuration reloaded');

=head3 API SPECIFICATION

=head4 Input

  { messages => { type => [ 'arrayref', 'scalar' ] } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under L</new>'s MESSAGES.

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
  $logger->warn($text, \%fields);

Logs a warning message.  Also dispatches to syslog and/or email backends
when those are configured.  Falls back to C<Carp::carp> when no backend
(C<logger>, C<array>, C<file> or C<fd>) is set.  The C<Carp::carp> (whether
from C<carp_on_warn> or the fallback) only happens when the message passes
the level threshold.

Called as a class method (C<Log::Abstraction-E<gt>warn(...)>, or on a
subclass), it calls C<Carp::carp> directly.

A C<warn()> call with an empty or all-undef argument list is a silent no-op.

=head3 Arguments

=over 4

=item * C<@messages>

A plain list of strings joined without separator, B<or> a named C<warning>
parameter whose value may be a string or an array reference of strings.
Either form may be followed by a hashref of L</Structured fields>, e.g.
C<warn('Slow query', { ms =E<gt> 1250 })>.

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

=head3 API SPECIFICATION

=head4 Input

  # Named form
  { warning => { type => [ 'scalar', 'arrayref' ] } }
  # Plain-list form
  { messages => { type => 'arrayref' } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

  (the warning text itself)                 Carped if carp_on_warn is set, or if no
                                            backend (logger, array, file or fd) is
                                            configured, provided the warning passes
                                            the level threshold.  Also carped when
                                            called as a class method.

Backend misconfiguration and delivery failures are reported as described
in the second table under L</new>'s MESSAGES.

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
  $logger->error($text, \%fields);

Logs an error-level message.  Behaves identically to C<warn()> but at the
C<error> level, which triggers C<Carp::croak> if C<croak_on_error> is set
or no backend (C<logger>, C<array>, C<file> or C<fd>) is set.  Called as a
class method, it calls C<Carp::croak> directly.

=head3 Arguments

Same argument forms as C<warn()>.

=head3 Returns

C<$self>, to allow method chaining.  Note: if C<croak_on_error> is set, the
method never returns -- execution unwinds via C<Carp::croak>.

=head3 Side Effects

Same as C<warn()> plus optional C<Carp::croak> escalation.

=head3 Example

  $logger->error('Fatal: database unavailable');

=head3 API SPECIFICATION

=head4 Input

  { warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

  Croak                                     Meaning / Action
  ----------------------------------------  ------------------------------------------
  (the error message text itself)           croak_on_error is set, or no backend
                                            (logger, array, file or fd) is
                                            configured, or error() was called as a
                                            class method.  The call stack is unwound.
  (the error message text itself), as a     carp_on_warn is set and croak_on_error
    carp                                    is not.

Backend misconfiguration and delivery failures are reported as described
in the second table under L</new>'s MESSAGES.

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

=head3 API SPECIFICATION

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

=head2 Methods above error

=over 4

=item critical

=item alert

=item emergency

=back

  $logger->critical(@messages);
  $logger->alert(warning => $text);
  $logger->emergency($text, \%fields);

Log a message at a level more severe than C<error>:

  Method      Level       syslog   Priority
  ----------  ----------  -------  --------
  critical    critical    crit     2
  alert       alert       alert    1
  emergency   emergency   emerg    0

=head3 Arguments

C<critical>, C<alert> and C<emergency> take the same argument forms as
C<warn()>.

=head3 Returns

C<$self>, to allow method chaining (unless they croak; see below).

=head3 Side Effects

These behave like C<error()>, at a more severe level: C<croak_on_error>, or
having no backend, makes them C<Carp::croak>, and C<carp_on_warn> makes them
C<Carp::carp>.  The level string passed to backends is the method name
(C<critical>, C<alert> or C<emergency>, upper-cased in text formats); syslog
gets C<crit>, C<alert> or C<emerg>, and journald C<PRIORITY> 2, 1 or 0.  An
object logger without the method (such as L<Log::Log4perl>) is called with
C<fatal>, or C<error> if it has no C<fatal> either.

=head3 Example

  $logger->critical('Disk 95% full', { mount => '/var' });
  $logger->alert('Primary database unreachable');
  $logger->emergency('Data corruption detected; shutting down');

=head3 API SPECIFICATION

=head4 Input

  { warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=head3 MESSAGES

Same as C<error()>.

=cut

sub critical {
	my $self = shift;
	$self->_high_priority('critical', @_);
	return $self;
}

sub alert {
	my $self = shift;
	$self->_high_priority('alert', @_);
	return $self;
}

sub emergency {
	my $self = shift;
	$self->_high_priority('emergency', @_);
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
# Side effects: Removes the _syslog_opened flag, and calls
#               Sys::Syslog::closelog() if no other instance still uses it.
# Notes:        Uses fully-qualified Sys::Syslog::closelog() so that
#               Test::Mockingbird can intercept the call in tests.
# ---------------------------------------------------------------------------
sub DESTROY {
	my $self = $_[0];

	# Destructors run at unpredictable times, e.g. while an exception is
	# propagating, so don't let closelog() change the error variables
	local ($@, $!, $?);

	# openlog/closelog are process-global, so only close the connection
	# when the last instance using it goes away
	if($self->{_syslog_opened}) {
		delete $self->{_syslog_opened};
		$syslog_open_count-- if($syslog_open_count > 0);
		Sys::Syslog::closelog() if($syslog_open_count == 0);
	}
}

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
log call: C<facility>, C<level> and C<format> are temporarily removed before
C<setlogsock()> is called, then restored; C<server> is permanently renamed
to C<host>.  Sharing a syslog hashref between two C<Log::Abstraction>
instances is not supported and produces undefined behaviour on the second
instance.

=item B<trace is the same threshold as debug>

syslog has no priority below debug, so C<trace> and C<debug> share one
threshold: a logger at C<debug> level also emits C<trace> messages, and
C<trace> can't be filtered separately.

=item B<Unbounded message history by default>

Every logged message is kept in the history returned by L</messages>.  In a
long-running process (a daemon, or under mod_perl) set C<max_messages> to
stop it growing without bound.

=item B<syslog connection is shared>

C<openlog()> and C<closelog()> act on the whole process, so every instance
logging to syslog shares one connection, opened with the C<script_name> of
the first.  It is closed when the last such instance is destroyed.

=item B<Structured fields are text in most backends>

Only the history, array, CODE-ref, JSON and journald backends keep
L</Structured fields> as data.  Text formats, syslog, email and object
loggers get them as C<key=value> text appended to the message, and a custom
C<format> has no token for them on their own.

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

When no C<logger>, C<file>, C<fd> or C<array> backend is configured, C<new()>
loads L<Log::Log4perl> and uses it as the default backend, so it is a
required dependency even for applications that never use it.

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

=encoding utf-8

=head1 FORMAL SPECIFICATION

=head2 new

  FIELDS == STRING ⇸ VALUE          structured fields (see Structured fields)
  ENTRY  == { level : STRING; message : STRING; fields : FIELDS }

  entry(l, m, f) == {level ↦ l, message ↦ m} ∪ (if f = ∅ then ∅ else {fields ↦ f})

  ┌─ LogState ──────────────────────────────────────────────────
  │ level        : ℤ
  │ messages     : seq ENTRY
  │ max_messages : ℕ ∪ {∞}
  │ logger       : LOGGER
  ├─────────────────────────────────────────────────────────────
  │ 0 ≤ level ≤ 7
  │ #messages ≤ max_messages
  └─────────────────────────────────────────────────────────────

  ┌─ New ───────────────────────────────────────────────────────
  │ args? : Args
  │ result! : LogState
  ├─────────────────────────────────────────────────────────────
  │ result!.level = syslog_values(args?.level ∨ 'warning')
  │ result!.messages = ⟨⟩
  │ result!.max_messages = args?.max_messages ∨ ∞
  │ args?.logger ≠ ∅ ⟹ result!.logger = args?.logger
  │ args?.logger = ∅ ∧ args?.file = ∅ ∧ args?.fd = ∅ ∧ args?.array = ∅
  │   ⟹ result!.logger = Log4perl
  └─────────────────────────────────────────────────────────────

  Clone operation (called on an existing object):

  ┌─ Clone ─────────────────────────────────────────────────────
  │ ΔLogState
  │ overrides? : Args
  ├─────────────────────────────────────────────────────────────
  │ result!.level    = syslog_values(overrides?.level ∨ level)
  │ result!.messages = messages   {new sequence; entries shared}
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

  ┌─ LevelSetInvalid ──────────────────────────────────────────
  │ ΞLogState
  │ new_level? : STRING
  │ result! : undef
  ├─────────────────────────────────────────────────────────────
  │ new_level? ≠ ''
  │ new_level? ∉ dom(syslog_values)
  │ carp("invalid syslog level")
  └─────────────────────────────────────────────────────────────

  level(new_level?) ≡ LevelSet ∨ LevelSetInvalid

=head2 is_trace, is_debug, is_info, is_notice, is_warn, is_error, is_critical, is_alert, is_emergency

  ┌─ IsLevel ──────────────────────────────────────────────────
  │ ΞLogState
  │ lvl? : LEVEL
  │ result! : BOOLEAN
  ├─────────────────────────────────────────────────────────────
  │ result! = (level ≥ syslog_values(lvl?))
  └─────────────────────────────────────────────────────────────

  is_<lvl> ≡ IsLevel[lvl? := lvl]

=head2 messages

  ┌─ Messages ─────────────────────────────────────────────────
  │ ΞLogState
  │ result! : seq ENTRY
  ├─────────────────────────────────────────────────────────────
  │ result! = messages
  └─────────────────────────────────────────────────────────────

=head2 trace

  ┌─ Trace ────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  │ fields? : FIELDS
  ├─────────────────────────────────────────────────────────────
  │ syslog_values('trace') ≤ level
  │ messages' = messages ⌢ ⟨entry('trace', ⊕(msg?), fields?)⟩
  └─────────────────────────────────────────────────────────────

=head2 debug

  ┌─ Debug ────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  │ fields? : FIELDS
  ├─────────────────────────────────────────────────────────────
  │ syslog_values('debug') ≤ level
  │ messages' = messages ⌢ ⟨entry('debug', ⊕(msg?), fields?)⟩
  └─────────────────────────────────────────────────────────────

=head2 info

  ┌─ Info ─────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  │ fields? : FIELDS
  ├─────────────────────────────────────────────────────────────
  │ syslog_values('info') ≤ level
  │ messages' = messages ⌢ ⟨entry('info', ⊕(msg?), fields?)⟩
  └─────────────────────────────────────────────────────────────

=head2 notice

  ┌─ Notice ───────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING
  │ fields? : FIELDS
  ├─────────────────────────────────────────────────────────────
  │ syslog_values('notice') ≤ level
  │ messages' = messages ⌢ ⟨entry('notice', ⊕(msg?), fields?)⟩
  └─────────────────────────────────────────────────────────────

=head2 warn

  ┌─ Warn ─────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING | { warning : STRING | seq STRING }
  │ fields? : FIELDS
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ∅ ∧ join(msg?) ≠ ''
  │ syslog_values('warn') ≤ level
  │ messages' = messages ⌢ ⟨entry('warn', join(msg?), fields?)⟩
  │ (carp_on_warn ∨ no_backend) ⟹ carp(join(msg?))
  └─────────────────────────────────────────────────────────────

  no_backend ≡ logger = ∅ ∧ array = ∅ ∧ file = ∅ ∧ fd = ∅

  Called as a class method (no LogState): carp(join(msg?)), and
  messages is not touched.

=head2 error

  ┌─ Error ────────────────────────────────────────────────────
  │ ΔLogState
  │ msg? : seq STRING | { warning : STRING | seq STRING }
  │ fields? : FIELDS
  ├─────────────────────────────────────────────────────────────
  │ msg? ≠ ∅ ∧ join(msg?) ≠ ''
  │ syslog_values('error') ≤ level
  │ messages' = messages ⌢ ⟨entry('error', join(msg?), fields?)⟩
  │ (croak_on_error ∨ no_backend) ⟹ execution_continues = false
  └─────────────────────────────────────────────────────────────

  Called as a class method (no LogState): croak(join(msg?)).

=head2 fatal

  fatal ≡ error   (identical operation schema)

=head2 critical, alert, emergency

  The Error schema, with 'error' replaced by 'critical', 'alert' or
  'emergency' respectively.

  In every logging schema, when #messages' would exceed max_messages
  the oldest entries are dropped: messages' = the last max_messages
  entries.  fields? is a hashref given after the message (see
  Structured fields); fields? = ∅ when there is none.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
