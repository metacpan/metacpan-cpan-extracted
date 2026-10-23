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

# Automatically throw exceptions on failed built-ins (open, close, socket,
# send...).  Not ':all': that adds system()/exec(), which this module never
# calls, and which would make IPC::System::Simple a hidden dependency
use autodie qw(:default);

# Core and CPAN dependencies.  Functions are called by their full names
# and nothing is imported, so that they can't be called as methods on a
# logger ($log->croak, $log->syslog ...).  Readonly::Values::Syslog only
# exports variables (%syslog_values, $DEBUG ...)
use Carp ();
use IO::Handle ();
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
# make test so white-box tests can still reach private methods.  0.06 also
# enforces when this module is loaded at run time (require, Log::Any).  The
# mode is set for this package only (0.07), not in $Sub::Private::config,
# which would change it for every other module using Sub::Private.
use Sub::Private 0.07 { mode => 'enforce' };

# The backends, one object per destination, built by new() (see
# _build_backends).  Loaded now rather than on demand, so that they are
# compiled with the rest of the module
use Log::Abstraction::Backend;
use Log::Abstraction::Backend::Array;
use Log::Abstraction::Backend::Code;
use Log::Abstraction::Backend::Fd;
use Log::Abstraction::Backend::File;
use Log::Abstraction::Backend::Journald;
use Log::Abstraction::Backend::LogAny;
use Log::Abstraction::Backend::LogDispatch;
use Log::Abstraction::Backend::Object;
use Log::Abstraction::Backend::Sendmail;
use Log::Abstraction::Backend::Syslog;

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

# Seconds after which an open log file is closed and opened again, when
# reopen_interval isn't given, in case a rotation tool doesn't send SIGHUP
Readonly::Scalar my $DEFAULT_REOPEN_INTERVAL => 300;

# reopen_interval values that aren't a number of seconds
Readonly::Scalar my $REOPEN_EVERY_WRITE => 0;     # close after every line
Readonly::Scalar my $REOPEN_ON_SIGHUP   => -1;    # only when told to

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

# The backend class for each key of a logger hash, in the order they are
# given a message
Readonly::Array my @HASH_BACKENDS => qw(file array sendmail syslog journald log_any log_dispatch fd);
Readonly::Hash my %BACKEND_CLASS => (
	array        => 'Log::Abstraction::Backend::Array',
	fd           => 'Log::Abstraction::Backend::Fd',
	file         => 'Log::Abstraction::Backend::File',
	journald     => 'Log::Abstraction::Backend::Journald',
	log_any      => 'Log::Abstraction::Backend::LogAny',
	log_dispatch => 'Log::Abstraction::Backend::LogDispatch',
	sendmail     => 'Log::Abstraction::Backend::Sendmail',
	syslog       => 'Log::Abstraction::Backend::Syslog',
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

# Regex: a valid journald field name (uppercase ASCII, digits and underscore,
# not starting with an underscore, which journald reserves for trusted fields)
Readonly::Scalar my $RE_JOURNALD_FIELD => qr/^[A-Z0-9][A-Z0-9_]*$/;

# Most messages a sendmail digest holds, unless digest_max says otherwise;
# beyond it they are only counted
Readonly::Scalar my $DEFAULT_DIGEST_MAX => 100;

# Exit status of an async sendmail child (see _send_email)
Readonly::Scalar my $EXIT_SENT   => 0;
Readonly::Scalar my $EXIT_FAILED => 1;

# What each match of a redact pattern is replaced with
Readonly::Scalar my $REDACTED_MARKER => '[REDACTED]';

# Single JSON encoder for format => 'json', built on first use.  It returns
# a character string so that all backends share one output-encoding path
my $json_encoder;

# How many SIGHUP signals the process has had.  Each open log file remembers the
# count when it was opened, and is opened again on the next write once the
# count has changed.  The handler only counts: closing a handle there could
# close it between _file_handle returning it and the print
my $sighup_count = 0;

# The SIGHUP handler that _catch_sighup installed, if it is installed; the
# $SIG{HUP} it replaced, put back by _release_sighup; and how many loggers
# use it (each has _sighup set)
my $sighup_handler;
my $sighup_previous;
my $sighup_users = 0;

# Process IDs of the children sending emails for sendmail's async option,
# not yet reaped (by _reap_email_children)
my @email_children;

=head1 NAME

Log::Abstraction - Logging Abstraction Layer

=head1 VERSION

0.41

=cut

our $VERSION = '0.41';

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

=head2 Redaction

The C<redact> option removes secrets before a message reaches the history
or any backend.  Each match of any of its patterns is replaced with
C<[REDACTED]>:

  my $log = Log::Abstraction->new(
      logger => '/var/log/myapp.log',
      redact => [qr/password=\S+/, qr/\b\d{4}(?:[ -]?\d{4}){3}\b/],
  );
  $log->warn('Login failed: user=fred password=hunter2');
  # Login failed: user=fred [REDACTED]

To keep the start of a match, end it with C<\K>: C<qr/password=\K\S+/> logs
C<password=[REDACTED]>.  The patterns run over the whole message, after its
arguments are joined, so a match may span them, as in
C<$log-E<gt>info('password=', $password)>; a CODE or object logger then gets
the joined message as one argument.  The text given to C<carp> or C<croak>
(see L</warn> and L</error>) is redacted too.

L</Structured fields> are redacted as well: string values, including those
inside plain hashes and arrays, and objects whose stringification matches
(they become the redacted string).  Field names aren't redacted, nor are
the format string, C<%env_*%> values or C<ctx>.

Redaction is applied only to messages that pass the logger's C<level>, so
it costs nothing for messages that are dropped.  A pattern that can match
the empty string, such as C<qr/x*/>, is rejected by L</new>.

=head2 Email digests

C<min_interval> limits the C<sendmail> backend to one email per interval,
dropping the messages in between.  With C<digest>, they are held instead,
and sent ahead of the next message in the first email after the interval:

  my $log = Log::Abstraction->new(
      logger => {
          file     => '/var/log/myapp.log',
          sendmail => {
              to           => 'ops@example.com',
              level        => 'error',
              min_interval => 300,
              digest       => 1,
              format       => '%level%> [%timestamp%] %message%',
          },
      },
  );

Each message is one line of the email, oldest first, as its own email body
would be: formatted with the C<sendmail> C<format> if there is one (as
above, so that each line has its time), else the message.  At most
C<digest_max> messages (default 100) are held; later ones are only
counted, and the email says C<... and N more messages> after the held ones.
Messages held when an email fails to send stay held, and the new one is
held with them.

Nothing is sent on a timer: held messages go out with the next email,
when L</flush> is called, or when the logger is destroyed (which calls
L</flush>).  A clone made with L</new> starts with none held.

=head2 Per-backend level and format

Every backend can have its own C<level> and C<format>, as well as the
logger's.  C<syslog>, C<journald> and C<sendmail> are hashes already, so
they take them as keys.  C<file>, C<fd> and C<array>, inside a C<logger> hash
or at the top level, and C<log_any> and C<log_dispatch>, may be given as a
hash holding the destination under the backend's own name:

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
syslog, Log::Any or Log::Dispatch, the journal's C<MESSAGE> field and the
email body.

=back

The plain forms (C<file =E<gt> $path>, C<fd =E<gt> $handle>,
C<array =E<gt> \@array>, C<log_any =E<gt> $category>,
C<log_dispatch =E<gt> $dispatcher>) still work and have no level or format of their
own.  A blessed handle object is a destination, not the hash form.

=head2 Forwarding to Log::Any and Log::Dispatch

L<Log::Any::Adapter::Abstraction> brings messages from L<Log::Any> into
C<Log::Abstraction>.  The C<log_any> and C<log_dispatch> backends go the
other way, sending messages on to an application's existing L<Log::Any> or
L<Log::Dispatch> set-up, alongside any other backends:

  my $log = Log::Abstraction->new(
      level  => 'debug',
      logger => {
          log_any      => 'MyApp',          # a category, or a Log::Any logger
          log_dispatch => $dispatcher,      # a Log::Dispatch object
          file         => '/var/log/myapp.log',
      },
  );

Levels keep their names, except that C<warn> becomes C<warning>, and
Log::Dispatch, which has nothing below C<debug>, gets C<trace> messages as
C<debug>.  Log::Any gets L</Structured fields> as its trailing hashref, so a
structured adapter receives them as data; Log::Dispatch has no fields, so
they are appended to the message as text.  With its own C<format> (see
L</Per-backend level and format>) a backend gets the formatted line instead.

A C<Log::Any> category name is looked up with
C<Log::Any-E<gt>get_logger(category =E<gt> $name)> (which needs L<Log::Any>
installed) when the first message is sent, and follows later
C<Log::Any::Adapter-E<gt>set()> calls.  If Log::Any or Log::Dispatch dies,
C<Carp::carp> is called and the other backends still get the message.

A C<Log::Any::Proxy> or C<Log::Dispatch> object given as the C<logger>
itself is used in the same way, rather than as an object whose method is
called for each level: neither has a method for every level, and both
would join the arguments with spaces.

A message that reaches a C<Log::Abstraction> while it is being forwarded
(e.g. through L<Log::Any::Adapter::Abstraction>) is logged by that logger's
other backends but not forwarded again, so a set-up that points back at
itself doesn't loop.

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

The file is kept open between messages, but before each write the logger
checks that the path still names the same file (device and inode), so
B<logrotate>'s default (rename the file and let the application create a new
one) works without C<copytruncate>, and without sending the process a
C<SIGHUP>: the next message is written to a new file.

A C<postrotate> script that sends the process a C<SIGHUP> works too: except
on Windows, the first time a logger opens a file, C<Log::Abstraction> sets
C<$SIG{HUP}> to a handler that makes every logger open its files again on
the next write.  A handler that was already set (a code reference or a sub
name) is called after it.  This means a C<SIGHUP> no longer ends the
program, as it does by default, while a logger that has opened a file
exists.  When the last of them is destroyed, the handler that was there
before is put back.  A handler that the program sets later replaces
C<Log::Abstraction>'s (and isn't changed when the loggers are destroyed);
it can call L</reopen> itself.

In case a C<SIGHUP> isn't sent, every file is also closed and opened again
every 5 minutes, by default.  C<reopen_interval> changes how often, makes
C<SIGHUP> the only way (C<-1>), or closes the file after every message
(C<0>), as before version 0.40.

On Windows an open file can't be renamed or deleted, so a file the logger is
writing can only be rotated by the logger itself (which closes it first), or
after calling L</reopen>, and then only until the next message.

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

=item * An object -- method matching the level name is called on it; a
L<Log::Any> logger or a L<Log::Dispatch> object is used as the C<log_any> or
C<log_dispatch> backend (see L</Forwarding to Log::Any and Log::Dispatch>)

=item * A hash reference -- may contain C<file>, C<array>, C<fd>, C<syslog>, C<journald>, C<sendmail>,
C<log_any> and/or C<log_dispatch> keys,
each of which may have its own C<level> and C<format> (see L</Per-backend level and format>)

=item * An array reference -- C<{ level, message }> hashrefs are pushed onto it, with a
C<fields> key when the call has L</Structured fields>

=item * A scalar string -- treated as a file path to append to

=back

When not supplied, L<Log::Log4perl> is initialised as the default backend.

The C<sendmail> sub-hash supports:
C<host>, C<port>, C<to>, C<from>, C<subject>, C<level>, C<format>,
C<min_interval>, C<digest>, C<digest_max>, C<async>.  C<to> is required.  With C<format>, the email body is the
formatted line rather than the message.  C<level> may be a level name or a syslog number (0-7);
without it, every message is emailed.
At most one email is sent per C<min_interval> seconds per instance; the
messages in between are dropped, unless C<digest> is set, which sends them
with the next email (see L</Email digests>).  If delivery fails,
C<Carp::carp> is called and the other backends still receive the message.

Sending an email waits for the SMTP server, which can take seconds.  With
C<async =E<gt> 1>, the email is sent by a child process (made with
C<fork>), and the log call returns at once.  The C<host> and C<port> are
still checked first.  The logger can't know whether the child succeeded:
the child carps a failure itself, and the message (and any digest sent
with it) is lost rather than held.  Emails sent close together are sent at
the same time, so they may arrive in any order.  The finished children are
reaped the next time an email is sent and when a logger is destroyed; a program that
reaps every child itself (e.g. C<waitpid(-1, ...)> in a C<$SIG{CHLD}>
handler) may see them.  On Windows, whose C<fork> is emulated with threads,
when C<fork> fails, and for the email sent when perl exits, the email is
sent in the log call as without C<async>.

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
journald error.  The socket is opened for the first message and reused for
the next ones; after a failed send it is closed, and the next message opens a
new one.  Each datagram is addressed to the socket path, so delivery
continues after journald restarts.

=item * C<redact>

Patterns to remove from every message before it is logged: a C<qr//>, a
string (compiled as a regular expression; a config file can't hold a
C<qr//>), or an array reference of them.  See L</Redaction>.

=item * C<reopen_interval>

Log files written by path are kept open between messages.  Every this many
seconds (default 300, i.e. 5 minutes) each one is closed and opened again on
its next write, in case a rotation tool changed the file without renaming it
and without sending a C<SIGHUP> (see L</logrotate>).

C<0> closes the file after every message, so it is never held open, and no
C<SIGHUP> handler is installed for it.  C<-1> never reopens the file because
of time: only a C<SIGHUP>, L</reopen>, or the file being renamed or deleted
does.  (Windows has no C<SIGHUP>.)

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

Builds one L<Log::Abstraction::Backend> object for each place messages go
to.  The arguments are not changed: in particular, the C<syslog> hash keeps
its C<facility>, C<level> and C<format> keys, and a C<server> key is not
renamed C<host> (before 0.40, the first message did both).

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
      redact         => { optional => 1 },    # regex, string, or arrayref of them
      reopen_interval => { type => 'integer', min => -1, optional => 1 },
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
  "<class>: reopen_interval must be a       reopen_interval is not a whole number
    number of seconds, 0 or -1, not '<v>'"  of seconds, 0 (close after every
                                            message) or -1 (only on SIGHUP).
  "<class>: timestamp_format must be a      timestamp_format is undef, empty or a
    non-empty string"                       reference.
  "<class>: timestamp_precision must be     timestamp_precision is not a whole
    an integer from 0 to 9, not '<v>'"      number of digits from 0 to 9.
  "<class>: redact patterns must be         A redact entry is a reference other than
    regular expressions or non-empty        a qr//, or an empty string.
    strings"
  "<class>: invalid redact pattern '<p>':   A redact string is not a valid regular
    <error>"                                expression.
  "<class>: redact pattern <p> matches the  The pattern can match nothing at all
    empty string"                           (e.g. qr/x*/), which would put a marker
                                            between every character.
  "<class>: invalid <backend> level '<l>'"  A backend's 'level' (file, fd, array,
                                            sendmail, journald) is neither a level
                                            name nor 0-7.  (A bad syslog 'level'
                                            gives "invalid syslog level", as above.)
  "<class>: the <backend> format must be   A backend's 'format' is undef, empty or
    a non-empty string"                     a reference.
  "<class>: the <backend> hash needs a      The hash form of file, fd, array, log_any
    '<backend>' key"                        or log_dispatch has no destination (e.g.
                                            file => { level => 'info' } without a
                                            'file' key).
  "<class>: the sendmail backend needs      The sendmail sub-hash has no 'to' key.
    a 'to' address"
  "<class>: sendmail digest_max must be a   digest_max is zero, negative or not a
    positive integer, not '<v>'"            number.
  "<class>: invalid journald field name     An extra journald key, upper-cased, is not
    '<k>'"                                  [A-Z0-9_] or starts with '_'.
  "<class>: the logger hash has none of     The logger hash has nowhere to send
    the keys array, fd, file, journald,     messages.  (Before 0.40, the first
    log_any, log_dispatch, sendmail,        message croaked "Don't know how to deal
    syslog"                                 with the <level> message".)
  "<class>: the logger can't be a <TYPE>    logger is a reference of an unsupported
    reference"                              type, e.g. a SCALAR or GLOB reference.
  "<class>: log_any must be a Log::Any      log_any is neither a Log::Any logger
    logger or a category name"              (Log::Any::Proxy) nor a non-empty string.
  "<class>: log_any needs Log::Any to be    log_any is a category name but Log::Any
    installed"                              can't be loaded.
  "<class>: log_dispatch must be a          log_dispatch is not an object with a
    Log::Dispatch object"                   log() method.

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
  "<class>: <object class> doesn't know     An object logger has no method for this
    how to deal with the <level> message"   level.  (notice falls back to info.)

  Carp                                      Meaning / Action
  ----------------------------------------  -----------------------------------------
  "Failed to send email: <error>"           SMTP delivery failed.  The other backends
                                            still receive the message.
  "<class>: syslog failed: <error>"         Sys::Syslog::syslog() died.
  "<class>: journald send failed: <error>"  The journald socket could not be reached.
                                            Given once, then not again until a send
                                            succeeds.
  "<class>: Log::Any failed: <error>"       Log::Any (or its adapter) died.  The other
  "<class>: Log::Dispatch failed: <error>"  backends still receive the message.

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
      CROAK on an invalid rotate_size, rotate_interval, rotate_keep or
        reopen_interval, and normalise rotate_size to bytes
      CROAK on an invalid redact pattern; compile redact to one regex
      shallow-clone self merged with override args
      validate and store new level integer if level given in args
      copy message history list
      start the clone with no held email digest, no open files, and not
        counted as a user of the SIGHUP handler
      count the clone as a user of an open syslog connection
      build the clone's own backends
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
      hourly/daily/weekly/monthly, or rotate_keep or reopen_interval is not
      a non-negative integer; normalise rotate_size to bytes
    CROAK if a redact pattern is not a regex or non-empty string, doesn't
      compile, or matches the empty string; compile redact to one regex

    FOR each backend (top-level file/fd/array, and the logger hash's
    file/fd/array/syslog/sendmail/journald/log_any/log_dispatch):
      IF log_any: CROAK unless a Log::Any::Proxy, or a category name with
        Log::Any installed
      IF log_dispatch: CROAK unless an object with a log() method
      SKIP the rest unless given as a hash
      CROAK if a file/fd/array/log_any/log_dispatch hash lacks its
        destination key (its own name)
      CROAK if its 'level' is not a level name or 0-7
      CROAK if its 'format' is undef, empty or not a string

    IF logger is a hash:
      CROAK if a sendmail sub-hash has no 'to' address, or a digest_max
        that isn't a positive integer
      CROAK if an extra journald key is not a valid journald field name
      CROAK if it has none of the backend keys

    self = bless { messages => [], merged args, level => numeric } as class
    self->{_backends} = _build_backends()  (CROAK on an unsupported logger)
    RETURN self

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
		_check_redact_args(ref($class), \%args);
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
		# A clone has its own digest, or held messages would be sent twice
		delete @{$clone}{qw(_email_digest _email_digest_dropped)};
		# and opens its own files, so that closing them doesn't affect the parent
		delete @{$clone}{qw(_handles _sighup)};
		# The clone shares the parent's open syslog connection
		Log::Abstraction::Backend::Syslog->retain_connection() if($clone->{_syslog_opened});
		# and has its own backends, as the overrides may change them
		$clone->{_backends} = $clone->_build_backends();
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
	_check_redact_args($class, \%args);

	# Validate the backends' own 'level' and 'format' keys now, rather than
	# have a bad value silently drop messages at log time: the top-level
	# file/fd/array and the HASH logger's sub-backends
	my @backends = map { [ $_, $args{$_} ] } grep { defined($args{$_}) } qw(file fd array);
	if(ref($args{'logger'}) eq 'HASH') {
		my $hash = $args{'logger'};
		push @backends, map { [ $_, $hash->{$_} ] }
			grep { defined($hash->{$_}) } qw(file fd array syslog sendmail journald log_any log_dispatch);
	}
	for my $backend (@backends) {
		my ($name, $value) = @{$backend};
		_check_producer($class, $name, $value) if($name =~ /^log_(?:any|dispatch)$/);
		next if(ref($value) ne 'HASH');
		if(($name =~ /^(?:file|fd|array|log_any|log_dispatch)$/) && !$value->{$name}) {
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
		if((ref($hash->{'sendmail'}) eq 'HASH') && defined(my $max = $hash->{'sendmail'}->{'digest_max'})) {
			if($max !~ /^[1-9]\d*$/) {
				Carp::croak("$class: sendmail digest_max must be a positive integer, not '$max'");
			}
		}

		if(ref($hash->{'journald'}) eq 'HASH') {
			for my $key (keys %{$hash->{'journald'}}) {
				next if(lc($key) =~ /^(?:socket|identifier|level|format)$/);
				if(uc($key) !~ $RE_JOURNALD_FIELD) {
					Carp::croak("$class: invalid journald field name '$key'");
				}
			}
		}

		# A hash with nowhere to send messages is a mistake
		if(!grep { $hash->{$_} } @HASH_BACKENDS) {
			Carp::croak("$class: the logger hash has none of the keys ", join(', ', sort @HASH_BACKENDS));
		}
	}

	# Construct the object, and the backends that messages go to
	my $self = bless {
		messages => [],
		%args,
		level => $syslog_values{ $args{'level'} },
	}, $class;
	$self->{_backends} = $self->_build_backends();
	return $self;
}

# ---------------------------------------------------------------------------
# _build_backends -- one Log::Abstraction::Backend object per destination
#
# Purpose:      Turn the logger, array, file and fd arguments into the
#               objects that _log passes each message to, once, rather than
#               working them out again for every message.
# Entry:        $self -- the logger object, whose arguments new() has checked.
# Exit:         Returns an array reference of backends, in the order they
#               get a message: the logger (or the logger hash's file, array,
#               sendmail, syslog, journald, log_any, log_dispatch and fd),
#               or the top-level array if there is no logger; then the
#               top-level file and fd.
# Side effects: None.  The caller's hashes are not changed (the syslog
#               backend works on a copy).
# Notes:        Each backend's own 'level' is converted to a number here.
#               Croaks if the logger is a reference of an unsupported type.
#
# Pseudocode:
#   FUNCTION _build_backends(self)
#     backends = []
#     IF logger is set:
#       CODE ref     -> Code
#       ARRAY ref    -> Array
#       HASH ref     -> for each key of HASH_BACKENDS that is set, its
#                       class, with destination, level and format from
#                       _backend (syslog, sendmail and journald are hashes
#                       holding level and format)
#       plain string -> File (the path)
#       Log::Any::Proxy -> LogAny;  Log::Dispatch -> LogDispatch
#       other object -> Object
#       other ref    -> CROAK
#     ELSE IF array: Array
#     IF top-level file: File;  IF top-level fd: Fd
#     RETURN backends
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _build_backends :Private {
	my $self = shift;

	my $class = Scalar::Util::blessed($self);
	my @backends;

	# Build one backend from a key's value: the destination under the
	# backend's own name, plus its level (as a number) and format
	my $build = sub {
		my ($name, $value) = @_;
		my ($dest, $level, $format);
		if($name =~ /^(?:syslog|sendmail|journald)$/) {
			# These are hashes already, holding their own level and format
			$dest = (ref($value) eq 'HASH') ? $value : {};
			($level, $format) = @{$dest}{qw(level format)};
		} else {
			($dest, $level, $format) = _backend($name, $value);
		}
		return $BACKEND_CLASS{$name}->new(
			$name  => $dest,
			level  => scalar(_level_number($level)),
			format => $format,
		);
	};

	if(my $logger = $self->{'logger'}) {
		my $type = ref($logger);
		if($type eq 'CODE') {
			push @backends, Log::Abstraction::Backend::Code->new(code => $logger);
		} elsif($type eq 'ARRAY') {
			push @backends, Log::Abstraction::Backend::Array->new(array => $logger);
		} elsif($type eq 'HASH') {
			push @backends, map { $build->($_, $logger->{$_}) } grep { $logger->{$_} } @HASH_BACKENDS;
		} elsif(!$type) {
			push @backends, Log::Abstraction::Backend::File->new(file => $logger);
		} elsif(Scalar::Util::blessed($logger) && $logger->isa('Log::Any::Proxy')) {
			# Neither has a method for every level, and both would join
			# the arguments with spaces, so they aren't plain objects
			push @backends, Log::Abstraction::Backend::LogAny->new(log_any => $logger);
		} elsif(Scalar::Util::blessed($logger) && $logger->isa('Log::Dispatch')) {
			push @backends, Log::Abstraction::Backend::LogDispatch->new(log_dispatch => $logger);
		} elsif(Scalar::Util::blessed($logger)) {
			push @backends, Log::Abstraction::Backend::Object->new(object => $logger);
		} else {
			Carp::croak("$class: the logger can't be a $type reference");
		}
	} elsif($self->{'array'}) {
		# A top-level array is only used when there's no logger
		push @backends, $build->('array', $self->{'array'});
	}

	# Top-level file and fd keys (parallel to 'logger')
	for my $name (qw(file fd)) {
		push @backends, $build->($name, $self->{$name}) if($self->{$name});
	}

	return \@backends;
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
# _check_producer -- validate a log_any or log_dispatch backend in new()
#
# Purpose:      Catch a wrong destination when the logger is built rather
#               than at the first message.
# Entry:        $class -- the class name, for messages.
#               $name  -- 'log_any' or 'log_dispatch'.
#               $value -- the configured value, plain or hash form.
# Exit:         Returns nothing; croaks on an invalid destination.
# Notes:        A pure function (no $self).  log_any takes a Log::Any::Proxy
#               or a category name, which needs Log::Any installed;
#               log_dispatch takes a Log::Dispatch (or anything with a
#               Log::Dispatch-style log() method).
# ---------------------------------------------------------------------------
sub _check_producer :Private {
	my ($class, $name, $value) = @_;

	my ($dest) = _backend($name, $value);
	return if(!defined($dest));    # a hash form without one croaks later

	if($name eq 'log_any') {
		if(Scalar::Util::blessed($dest)) {
			return if($dest->isa('Log::Any::Proxy'));
		} elsif(!ref($dest) && length($dest)) {
			return if(eval { require Log::Any; 1 });
			Carp::croak("$class: log_any needs Log::Any to be installed");
		}
		Carp::croak("$class: log_any must be a Log::Any logger or a category name");
	}
	if(!Scalar::Util::blessed($dest) || !$dest->can('log')) {
		Carp::croak("$class: log_dispatch must be a Log::Dispatch object");
	}
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
	if(defined(my $interval = $args->{'reopen_interval'})) {
		if($interval !~ /^(?:\d+|-1)\z/) {
			Carp::croak("$class: reopen_interval must be a number of seconds, 0 or -1, not '$interval'");
		}
	}
	return;
}

# ---------------------------------------------------------------------------
# _check_redact_args -- validate the redact option and compile it
#
# Purpose:      Croak in new() (and when cloning) on a bad redact pattern,
#               rather than leave a secret in the log.
# Entry:        $class -- the class name, for the error message.
#               $args  -- hashref of constructor arguments; changed in place.
# Exit:         Returns nothing.  redact, a regex, a string or an arrayref of
#               them, becomes one regex that matches any of them, or undef
#               when there are none.  Croaks on a pattern that isn't a regex
#               or non-empty string, doesn't compile, or matches ''.
# Notes:        A pure function (no $self), called as
#               _check_redact_args($class, \%args).  Strings are allowed
#               because a config file can't hold a qr//.  One combined regex
#               means one pass, so a replacement is never matched again.
#
# Pseudocode:
#   FUNCTION _check_redact_args(class, args)
#     RETURN unless args has a redact key
#     patterns = the defined elements of redact (an arrayref) or redact itself
#     FOR each pattern that isn't already a regex:
#       CROAK if it is a reference or ''
#       compile it (in eval); CROAK with the error, less its location, if
#         it doesn't compile
#     IF no patterns: set redact to undef; RETURN
#     CROAK if any pattern matches ''
#     set redact to qr/(?:p1)|(?:p2)|.../
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _check_redact_args :Private {
	my ($class, $args) = @_;

	return if(!exists($args->{'redact'}));
	my $redact = $args->{'redact'};
	my @patterns = grep { defined } ((ref($redact) eq 'ARRAY') ? @{$redact} : ($redact));
	for my $pattern (@patterns) {
		next if(re::is_regexp($pattern));
		if(ref($pattern) || ($pattern eq '')) {
			Carp::croak("$class: redact patterns must be regular expressions or non-empty strings");
		}
		my $re = eval { qr/$pattern/ };
		if(!$re) {
			(my $error = $@) =~ s/ at \S+ line \d+\.?\n\z//;
			Carp::croak("$class: invalid redact pattern '$pattern': $error");
		}
		$pattern = $re;
	}
	if(!@patterns) {
		$args->{'redact'} = undef;
		return;
	}
	for my $pattern (@patterns) {
		# It would put a marker between every character
		if('' =~ $pattern) {
			Carp::croak("$class: redact pattern $pattern matches the empty string");
		}
	}
	my $any = join('|', map { "(?:$_)" } @patterns);
	$args->{'redact'} = qr/$any/;
	return;
}

# ---------------------------------------------------------------------------
# _redact -- replace whatever matches the redact regex with [REDACTED]
#
# Purpose:      Remove secrets from a message or a structured-field value
#               before it reaches the history or any backend.
# Entry:        $re    -- the regex built by _check_redact_args.
#               $value -- a string, or a field value of any kind.
#               $seen  -- (recursion only) the references being walked.
# Exit:         Returns the redacted copy; the value itself is unchanged.
#               Plain hashes and arrays are copied with their contents
#               redacted; a blessed object whose stringification matches
#               becomes the redacted string; any other value is returned
#               as it is.  A reference that contains itself is replaced by
#               the marker where it recurs.
# Notes:        A pure function (no $self), called as _redact($re, $value).
#
# Pseudocode:
#   FUNCTION _redact(re, value, seen)
#     RETURN value if undef
#     IF blessed: RETURN _redact(re, "value") if "value" matches re, else value
#     IF a reference:
#       RETURN value unless a plain HASH or ARRAY
#       RETURN the marker if value is in seen (it contains itself)
#       add value to seen while walking it (local, so siblings may share it)
#       RETURN a copy with each element/value passed through _redact
#     replace every match of re in (a copy of) value with the marker
#     RETURN it
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _redact :Private {
	my ($re, $value, $seen) = @_;

	return $value if(!defined($value));
	if(Scalar::Util::blessed($value)) {
		my $string = "$value";
		return $value unless $string =~ $re;
		$string =~ s/$re/$REDACTED_MARKER/g;
		return $string;
	}
	if(my $type = ref($value)) {
		return $value if(($type ne 'HASH') && ($type ne 'ARRAY'));
		$seen ||= {};
		return $REDACTED_MARKER if($seen->{$value});
		local $seen->{$value} = 1;
		return ($type eq 'HASH')
			? { map { $_ => _redact($re, $value->{$_}, $seen) } keys %{$value} }
			: [ map { _redact($re, $_, $seen) } @{$value} ];
	}
	$value =~ s/$re/$REDACTED_MARKER/g;
	return $value;
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
#     close the logger's handle on path
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

	# Close the file first: Windows can't rename or delete an open file
	$self->_close_files($path);

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
#               is rotated first if rotate_size or rotate_interval says so,
#               and is kept open for the next line (see _file_handle), unless
#               reopen_interval is 0.
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
	# A failed write closes the file, so that the next one opens it again
	eval {
		my $fout = $self->_file_handle($target);
		print $fout "$line\n" or die "$target: $!";
		1;
	} or $self->_close_files($target);

	# reopen_interval 0: never hold the file open, as before 0.40
	if(($self->{'reopen_interval'} // $DEFAULT_REOPEN_INTERVAL) == $REOPEN_EVERY_WRITE) {
		$self->_close_files($target);
	}
	return;
}

# ---------------------------------------------------------------------------
# _file_handle -- the logger's open handle on a log file
#
# Purpose:      Keep log files open between messages, rather than opening
#               and closing them for every line.
# Entry:        $self -- the logger object (reopen_interval, and the open
#                        handles in $self->{_handles}).
#               $path -- a validated log-file path.
# Exit:         Returns a handle open for appending, with autoflush on.
#               Croaks (autodie) if the file can't be opened.
# Side effects: Opens the file if the logger hasn't, or opens it again if
#               the path is now a different file (renamed or deleted, e.g.
#               by logrotate), the process has had a SIGHUP, or
#               reopen_interval seconds have passed since it was opened
#               (never with -1).  Installs the SIGHUP handler
#               (_catch_sighup) when it opens a file, unless reopen_interval
#               is 0, when _write_line closes the file again at once.
# Notes:        Costs one stat() per line.  The device and inode are taken
#               from the path, not the handle, so that the two are compared
#               alike (Windows' fstat can differ).
#
# Pseudocode:
#   FUNCTION _file_handle(self, path)
#     IF the logger has a handle on path:
#       RETURN it IF path still names the same device and inode AND
#         there has been no SIGHUP since it was opened AND
#         (reopen_interval is -1 OR it was opened less than that long ago)
#       close it
#     install the SIGHUP handler, unless done already, on Windows, or
#       reopen_interval is 0
#     open path for appending, autoflush on
#     remember the handle, path's device and inode, the SIGHUP count and
#       the time
#     RETURN the handle
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _file_handle :Private {
	my ($self, $path) = @_;

	if(my $open = $self->{_handles}{$path}) {
		my @st = stat($path);
		my $interval = $self->{'reopen_interval'} // $DEFAULT_REOPEN_INTERVAL;
		if(@st && ($st[0] == $open->{dev}) && ($st[1] == $open->{ino})
		   && ($open->{sighup} == $sighup_count)
		   && (($interval == $REOPEN_ON_SIGHUP) || ((time() - $open->{opened}) < $interval))) {
			return $open->{fh};
		}
		$self->_close_files($path);
	}

	$self->_catch_sighup() unless(($self->{'reopen_interval'} // $DEFAULT_REOPEN_INTERVAL) == $REOPEN_EVERY_WRITE);
	open(my $fh, '>>', $path);
	$fh->autoflush(1);
	my @st = stat($path);
	$self->{_handles}{$path} = {
		fh => $fh, dev => $st[0], ino => $st[1], sighup => $sighup_count, opened => time(),
	};
	return $fh;
}

# ---------------------------------------------------------------------------
# _catch_sighup -- reopen the log files when the process gets a SIGHUP
#
# Purpose:      logrotate's postrotate script, and similar tools, send
#               SIGHUP to tell a program to reopen its log files.
# Entry:        $self -- the logger opening a file.
# Exit:         Returns nothing.
# Side effects: Except on Windows, counts the logger as a user of the
#               handler (_sighup), and if no logger has installed it, saves
#               $SIG{HUP} and sets it to a handler that counts the signal
#               (see $sighup_count) and then calls the saved handler, if it
#               is a code reference or a sub name.  So SIGHUP doesn't end
#               the process by default while a logger uses the handler;
#               _release_sighup puts the saved one back.
# Notes:        Called when a file is opened, so a program that never logs
#               to a file keeps its SIGHUP behaviour.  A handler the program
#               sets afterwards replaces this one; reopen_interval still
#               reopens the files.
# ---------------------------------------------------------------------------
sub _catch_sighup :Private {
	my $self = $_[0];

	return if($self->{_sighup} || ($^O eq 'MSWin32'));
	$self->{_sighup} = 1;
	$sighup_users++;
	return if($sighup_handler);

	$sighup_previous = $SIG{HUP};
	my $chain = $sighup_previous;
	if(defined($chain) && !ref($chain)) {
		$chain = undef if(($chain eq '') || ($chain eq 'IGNORE') || ($chain eq 'DEFAULT'));
		$chain = "main::$chain" if(defined($chain) && ($chain !~ /::/));
	}
	$sighup_handler = sub {
		$sighup_count++;
		if(defined($chain)) {
			no strict 'refs';
			$chain->(@_);
		}
	};
	$SIG{HUP} = $sighup_handler;
	return;
}

# ---------------------------------------------------------------------------
# _release_sighup -- stop using the SIGHUP handler
#
# Purpose:      Give the program its own SIGHUP handler back when no logger
#               needs this module's.
# Entry:        $self -- a logger being destroyed.
# Exit:         Returns nothing.
# Side effects: If the logger used the handler and was the last to, puts
#               back the $SIG{HUP} that _catch_sighup replaced, unless the
#               program has set a handler of its own since; the next logger
#               to open a file installs the handler again.
# ---------------------------------------------------------------------------
sub _release_sighup :Private {
	my $self = $_[0];

	return unless(delete $self->{_sighup});
	return if(--$sighup_users > 0);

	my $current = $SIG{HUP};
	if($sighup_handler && ref($current) && ($current == $sighup_handler)) {
		$SIG{HUP} = (defined($sighup_previous) && length($sighup_previous)) ? $sighup_previous : 'DEFAULT';
	}
	$sighup_handler = $sighup_previous = undef;
	return;
}

# ---------------------------------------------------------------------------
# _close_files -- close log files that the logger holds open
#
# Purpose:      Used by reopen(), before a rotation, and after a failed write.
# Entry:        $self  -- the logger object.
#               @paths -- the files to close; none means all of them.
# Exit:         Returns nothing.
# Side effects: Closes the handles and forgets them, so the next write opens
#               the file again.  A failing close is ignored.
# ---------------------------------------------------------------------------
sub _close_files :Private {
	my ($self, @paths) = @_;

	my $handles = $self->{_handles} or return;
	for my $path (@paths ? @paths : keys(%{$handles})) {
		my $open = delete $handles->{$path} or next;
		eval { close($open->{fh}) };
	}
	return;
}

# ---------------------------------------------------------------------------
# _send_email -- send one email: any held digest, then the new lines
#
# Purpose:      The sendmail backend's delivery, shared by _log and flush().
# Entry:        $self  -- the logger object (the digest and throttle state).
#               $sm    -- the sendmail hash (to, from, subject, host, port,
#                         digest, async).
#               @lines -- the bodies of the new messages (none from flush).
# Exit:         Returns 1 if the email was sent or there was nothing to
#               send, 0 if delivery failed.
# Side effects: Croaks on an invalid host or port, before the eval so that
#               the misconfiguration isn't hidden.  On success, clears the
#               digest and starts the min_interval throttle.  On failure,
#               carps, and with digest holds @lines for the next email (the
#               digest already held stays held).
# Notes:        The body is the held lines, a "... and N more" line if some
#               were dropped, then @lines, one per line; a single message
#               with nothing held is sent exactly as it is.
#               With async (not on Windows, nor while perl is exiting), a
#               forked child sends the email and this returns 1 at once, as
#               if it had been sent: the child carps a failure itself, and
#               the lines are lost.  If fork fails, the email is sent here.
#
# Pseudocode:
#   FUNCTION _send_email(self, sm, lines...)
#     CROAK if host contains unsafe characters, or port isn't 1-65535
#     body = held digest, "... and N more" if N were dropped, lines
#     RETURN 1 if body is empty
#     deliver = load Email::* modules; build email with sanitised headers
#               and body joined with newlines; send via SMTP transport
#     IF sm->{async} AND not Windows AND perl isn't exiting:
#       reap finished children
#       fork
#       IN THE CHILD: (eval) deliver; CARP on failure; _exit
#       IN THE PARENT, if the fork worked: remember the child; clear the
#         digest; record the time for the throttle; RETURN 1
#     (eval) deliver
#     IF it failed:
#       CARP; IF sm->{digest}: hold each of lines; RETURN 0
#     clear the digest; record the time for the throttle; RETURN 1
#   END FUNCTION
# ---------------------------------------------------------------------------
sub _send_email :Private {
	my ($self, $sm, @lines) = @_;

	# Validate host and port before any eval so bad config croaks immediately
	my $host = $sm->{'host'} || $DEFAULT_SMTP_HOST;
	Carp::croak(ref($self), ": Invalid SMTP host: $host")
		if $host =~ $RE_SAFE_HOST;
	my $port = $sm->{'port'} || $DEFAULT_SMTP_PORT;
	Carp::croak(ref($self), ": Invalid SMTP port: $port")
		unless $port =~ $RE_PORT
			&& $port >= $MIN_PORT
			&& $port <= $MAX_PORT;

	my $dropped = $self->{_email_digest_dropped};
	my @body = (
		@{$self->{_email_digest} || []},
		($dropped ? ("... and $dropped more " . (($dropped == 1) ? 'message' : 'messages')) : ()),
		@lines,
	);
	return 1 if(!@body);

	# Load mail modules lazily; called in an eval to handle delivery failures
	my $deliver = sub {
		require Email::Simple;
		require Email::Sender::Simple;
		require Email::Sender::Transport::SMTP;

		# Build the email object with sanitised headers
		my $email = Email::Simple->new('');
		$email->header_set('to', _sanitize_email_header($sm->{'to'}));
		$email->header_set('from', _sanitize_email_header($sm->{'from'} || $DEFAULT_FROM_ADDR));
		if(my $subject = $sm->{'subject'}) {
			$email->header_set('subject', _sanitize_email_header($subject));
		}
		$email->body_set(join("\n", @body));

		my $transport = Email::Sender::Transport::SMTP->new({
			host => $host,
			port => $port,
		});
		# A class method, rather than the exported sendmail(), so that
		# nothing is imported into this package
		Email::Sender::Simple->send($email, { transport => $transport });
	};

	# async: send from a child process, so that the log call doesn't wait
	# for the SMTP conversation.  Windows' fork is emulated with threads,
	# and while perl is exiting (DESTROY's flush) the modules may be gone
	if($sm->{'async'} && ($^O ne 'MSWin32') && (${^GLOBAL_PHASE} ne 'DESTRUCT')) {
		_reap_email_children();
		my $pid = do {
			no autodie qw(fork);
			fork();
		};
		if(defined($pid) && ($pid == 0)) {
			# The child: no END blocks, destructors or buffered output of
			# the parent's must run here, so leave with _exit
			my $ok = eval { $deliver->(); 1 };
			if(!$ok) {
				# Copied first: entering the eval clears $@
				my $error = $@;
				eval { Carp::carp("Failed to send email: $error") };
			}
			POSIX::_exit($ok ? $EXIT_SENT : $EXIT_FAILED);
		}
		if(defined($pid)) {
			push @email_children, $pid;
			delete @{$self}{qw(_email_digest _email_digest_dropped)};
			$self->{_last_email_sent} = time();
			return 1;
		}
		# fork failed: send it here instead
	}

	if(!eval { $deliver->(); 1 }) {
		Carp::carp("Failed to send email: $@");
		if($sm->{'digest'}) {
			$self->_hold_email($sm, $_) for @lines;
		}
		return 0;
	}

	# Record send time for the throttle on success
	delete @{$self}{qw(_email_digest _email_digest_dropped)};
	$self->{_last_email_sent} = time();
	return 1;
}

# ---------------------------------------------------------------------------
# _reap_email_children -- collect the async sendmail children that finished
#
# Purpose:      Stop finished children from being left as zombies.
# Entry:        None.
# Exit:         Returns nothing.
# Side effects: Reaps, without waiting, the children in @email_children
#               that have exited, and forgets them.  One already reaped by
#               the program (e.g. by a SIGCHLD handler) is forgotten too.
# Notes:        Called before each async send and by DESTROY.  Children
#               still running then are reaped by a later call, or when the
#               program exits.
# ---------------------------------------------------------------------------
sub _reap_email_children :Private {
	@email_children = grep { waitpid($_, POSIX::WNOHANG()) == 0 } @email_children;
	return;
}

# ---------------------------------------------------------------------------
# _hold_email -- keep a message body for the next email (sendmail digest)
#
# Purpose:      With digest, messages that min_interval (or a failed send)
#               would lose are sent with the next email instead.
# Entry:        $self -- the logger object.
#               $sm   -- the sendmail hash (digest_max).
#               $line -- the message's email body.
# Exit:         Returns nothing.  Holds $line, or once digest_max are held,
#               only counts it, so a burst can't use unbounded memory.
# ---------------------------------------------------------------------------
sub _hold_email :Private {
	my ($self, $sm, $line) = @_;

	my $held = $self->{_email_digest} ||= [];
	if(scalar(@{$held}) < ($sm->{'digest_max'} // $DEFAULT_DIGEST_MAX)) {
		push @{$held}, $line;
	} else {
		$self->{_email_digest_dropped}++;
	}
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
# Side effects: Appends to $self->{messages}.  Passes the message to the
#               backends (Log::Abstraction::Backend::*), which may write to a
#               file, fd, array, syslog, journald, email, Log::Any or
#               Log::Dispatch.  May load Email::* modules.
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
#     IF redact: _redact $str (the parts become just $str) and the fields
#     $text = $str plus the fields as logfmt key=value pairs (for backends
#       with no field support: syslog, email, objects)
#     Push { level, message, fields? } onto self->{messages} (always recorded);
#       drop the oldest entries beyond max_messages
#     Set $class = '' for base package, else the blessed class name
#     Resolve caller file/line; format the timestamp once (_timestamp),
#       shared by every file/fd backend
#     render(format) = _format_message(..., format), cached per format;
#       undef format means the logger's own
#     Build the event: level, priority, message, parts, fields, text, the
#       history entry, class, caller file/line, ctx, and closures for the
#       private methods the backends need (render, write, send_email,
#       hold_email, field_string)
#     backends = self->{_backends}, or _build_backends() if not built yet
#     FOR each backend (see _build_backends for which and in what order):
#       IF backend->wants(event) (its own level, if any, lets it through):
#         backend->emit(self, event)
#     (each Log::Abstraction::Backend::* class documents what it does)
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

	# Redact before the message reaches the history or any backend.  The
	# regex runs over the joined message, so a match may span arguments;
	# the CODE and object backends then get the one redacted string
	if(my $redact = $self->{'redact'}) {
		$str = _redact($redact, $str);
		@messages = ($str);
		$fields = _redact($redact, $fields) if($fields);
	}

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
	# messages routed through Log::Any report the user's code.  So are those
	# of the Log::Abstraction that forwarded a message here (see the LogAny
	# and LogDispatch backends)
	my $depth = ((caller(1))[3] // '') =~ /::_high_priority$/ ? 2 : 1;
	my $skip = $Log::Abstraction::Backend::FORWARDING ? qr/^Log::(?:Any|Abstraction|Dispatch)(?:::|$)/ : qr/^Log::Any(?:::|$)/;
	while((caller($depth + 1))[0] && (((caller($depth))[0] // '') =~ $skip)) {
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

	# What a backend needs to know about the message, and closures for
	# the private methods it needs (see Log::Abstraction::Backend)
	my %event = (
		level       => $level,
		priority    => $syslog_values{$level},
		message     => $str,
		parts       => \@messages,
		fields      => $fields,
		fields_text => $fields_text,
		text        => $text,
		entry       => \@entry,
		class       => Scalar::Util::blessed($self) || __PACKAGE__,
		file        => $caller_file,
		line        => $caller_line,
		ctx         => $self->{ctx},
		render      => $render,
		write       => sub {
			my ($target, $line) = @_;
			$target = $self->_validate_file_path($target) if(!ref($target));
			$self->_write_line($target, $line);
		},
		send_email   => sub { $self->_send_email(@_) },
		hold_email   => sub { $self->_hold_email(@_) },
		field_string => sub { _field_string(@_) },
	);

	# Pass the message to every backend whose own level it passes.  A bare
	# object (not made by new()) builds them now
	my $backends = $self->{_backends} //= $self->_build_backends();
	for my $backend (@{$backends}) {
		$backend->emit($self, \%event) if($backend->wants(\%event));
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
#     IF redact: _redact the warning text, for Carp below
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

	# What Carp shows must be redacted too (_log redacts its own copy)
	$warning = _redact($self->{'redact'}, $warning) if($self->{'redact'});

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

=head2 flush

  $logger->flush();

Sends, now, the messages that a C<sendmail> backend with C<digest> is
holding back because of C<min_interval> (see L</Email digests>), whether or
not the interval has passed.  Does nothing if none are held.  Called
automatically when the logger is destroyed.

=head3 Arguments

None.

=head3 Returns

The logger, for method chaining.

=head3 Side Effects

May send an email, which starts the C<min_interval> interval again.  A
delivery failure is carped and the messages stay held.  With C<async>, the
email is sent by a child process and the messages are no longer held: a
failure is carped by the child, and the messages are lost.  Croaks if the
C<sendmail> C<host> or C<port> is invalid.

=head3 Example

  $logger->error('disk full');    # emailed
  $logger->error('disk still full');    # held: within min_interval
  $logger->flush();                # emailed now

=head3 API SPECIFICATION

=head4 Input

  {} (no arguments)

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=cut

sub flush {
	my $self = $_[0];

	# Preserve the caller's $@ and $! (see _log)
	local ($@, $!);

	my $sm = (ref($self->{'logger'}) eq 'HASH') ? $self->{'logger'}->{'sendmail'} : undef;
	if($sm && $self->{_email_digest}) {
		$self->_send_email($sm);
	}
	return $self;
}

=head2 reopen

  $logger->reopen();

Closes the log files the logger holds open, so that the next message opens
them again.  Log files written by path (see L</File rotation>) are kept open
between messages; call this after something outside the program has renamed,
moved or truncated them.  It isn't usually needed: a file that has been
renamed or deleted is noticed on the next write, a C<SIGHUP> reopens every
logger's files (except on Windows, see L</logrotate>), and every file is
reopened when C<reopen_interval> has passed (unless it is C<-1>).  File
handles passed as C<fd> are not closed.  It does nothing if no files are
open.

A file is also closed when writing to it fails (e.g. the disk is full), so
that the next message opens it again.

A program that sets its own C<$SIG{HUP}> after logging has started replaces
the module's handler, and can call this from its own:

  $SIG{HUP} = sub { $logger->reopen(); reload_config() };

=head3 Arguments

None.

=head3 Returns

The logger, for method chaining.

=head3 Side Effects

Closes the logger's log files.

=head3 API SPECIFICATION

=head4 Input

  {} (no arguments)

=head4 Output

  { type => 'object', class => 'Log::Abstraction' }

=cut

sub reopen {
	my $self = $_[0];

	# Preserve the caller's $@ and $! (see _log)
	local ($@, $!);

	$self->_close_files();
	return $self;
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
# DESTROY -- release the syslog connection and SIGHUP handler when freed
#
# Purpose:      Ensure the syslog socket is closed cleanly on object
#               destruction, avoiding resource leaks under persistent
#               interpreters such as mod_perl.
# Entry:        $self -- the logger object being destroyed.
# Exit:         void
# Side effects: Sends any held email digest.  Puts back the program's
#               SIGHUP handler (_release_sighup) if this was the last
#               logger using the module's.  Removes the _syslog_opened flag, and calls
#               Sys::Syslog::closelog() if no other instance still uses it.
# Notes:        Uses fully-qualified Sys::Syslog::closelog() so that
#               Test::Mockingbird can intercept the call in tests.
# ---------------------------------------------------------------------------
sub DESTROY {
	my $self = $_[0];

	# Destructors run at unpredictable times, e.g. while an exception is
	# propagating, so don't let closelog() change the error variables
	local ($@, $!, $?);

	# Send any messages a sendmail digest is still holding
	eval { $self->flush() } if($self->{_email_digest});

	# Collect async sendmail children that have finished
	_reap_email_children() if(@email_children);

	# openlog/closelog are process-global, so only close the connection
	# when the last instance using it goes away
	if($self->{_syslog_opened}) {
		delete $self->{_syslog_opened};
		Log::Abstraction::Backend::Syslog->release_connection();
	}

	# Give the program its SIGHUP handler back if no other logger needs ours
	$self->_release_sighup() if($self->{_sighup});
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

Only the history, array, CODE-ref, JSON, journald and Log::Any backends
keep L</Structured fields> as data.  Text formats, syslog, email,
Log::Dispatch and object loggers get them as C<key=value> text appended to
the message, and a custom C<format> has no token for them on their own.

=item B<Process-wide state, and no thread safety>

Some state belongs to the whole process, not to a logger: the syslog
connection (above), the C<$SIG{HUP}> handler (see L</logrotate>), and the
list of C<async> email children still to be reaped.  The per-logger state
(open log files, the C<min_interval> throttle and C<digest>, the
first-open syslog flag) is stored on the object without locking.  Under
Perl ithreads or other concurrency models, objects shared between threads
are not safe.

=item B<Asynchronous email uses fork>

The C<sendmail> C<async> option sends each email from a child made with
C<fork>.  That may not suit every program: under mod_perl the child is a
copy of the Apache process; with ithreads only the calling thread is
copied; and in an event loop (L<AnyEvent>, L<IO::Async>, L<Mojo::IOLoop>)
the child is reaped by this module, not by the loop's child watcher.  A
program that reaps every child itself (e.g. C<waitpid(-1, ...)> in a
C<$SIG{CHLD}> handler) sees these children too.  The child's success or
failure isn't reported back: a failure is carped by the child and the
message is lost.  Without C<async> the email is sent in the log call.

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
C<Log::Abstraction> with a single C<Log::Any::Adapter-E<gt>set()> call,
or send messages on to Log::Any with the C<log_any> backend.

=item * L<Log::Abstraction::Backend>

The classes that send messages to each kind of backend.

=item * L<Log::Dispatch>

Send messages on to a C<Log::Dispatch> object with the C<log_dispatch>
backend (see L</Forwarding to Log::Any and Log::Dispatch>).

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

  entry(l, m, f) == {level ↦ l, message ↦ ρ(m)} ∪ (if f = ∅ then ∅ else {fields ↦ ρ(f)})

  ρ(x) == if redact = ∅ then x
          else x with each match of redact replaced by '[REDACTED]'
               (in strings, recursively in plain hashes and arrays)

  ┌─ LogState ──────────────────────────────────────────────────
  │ level        : ℤ
  │ messages     : seq ENTRY
  │ max_messages : ℕ ∪ {∞}
  │ logger       : LOGGER
  │ redact       : REGEX ∪ {∅}
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
  │ result!.redact = ⋃ args?.redact   {one regex matching any; ∅ if none}
  │ args?.redact ≠ ∅ ⟹ ¬('' ∈ L(result!.redact))
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

=head2 flush

  ┌─ Flush ────────────────────────────────────────────────────
  │ ΔLogState
  │ result! : LogState
  ├─────────────────────────────────────────────────────────────
  │ digest ≠ ⟨⟩ ∧ (sent(digest) ∨ async ∧ forked) ⟹
  │     digest' = ⟨⟩ ∧ last_email_sent' = now
  │ digest ≠ ⟨⟩ ∧ ¬sent(digest) ∧ ¬(async ∧ forked) ⟹ digest' = digest
  │ digest = ⟨⟩ ⟹ digest' = digest
  │ messages' = messages
  │ result! = self
  └─────────────────────────────────────────────────────────────

=head2 reopen

  INTERVAL == ℤ                     reopen_interval: seconds, 0 or -1
  HANDLE   == { fh; dev; ino; sighup : ℕ; opened : ℕ }

  ┌─ OpenFiles ─────────────────────────────────────────────────
  │ handles         : PATH ⇸ HANDLE
  │ reopen_interval : INTERVAL
  ├─────────────────────────────────────────────────────────────
  │ reopen_interval ≥ -1
  │ reopen_interval = 0 ⟹ handles = ∅   (between log calls)
  └─────────────────────────────────────────────────────────────

  A handle h on path p is used for the next write iff
    stat(p) = (h.dev, h.ino) ∧ h.sighup = sighup_count
    ∧ (reopen_interval = -1 ∨ now - h.opened < reopen_interval)
  and is otherwise closed and p opened again.

  ┌─ Reopen ────────────────────────────────────────────────────
  │ ΔOpenFiles
  │ result! : LogState
  ├─────────────────────────────────────────────────────────────
  │ handles' = ∅
  │ reopen_interval' = reopen_interval
  │ result! = self
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
