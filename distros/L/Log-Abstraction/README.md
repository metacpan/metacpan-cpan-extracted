## Name

Log::Abstraction - Logging Abstraction Layer

## Version

0.35

## Synopsis

```perl
use Log::Abstraction;

my $logger = Log::Abstraction->new(logger => 'logfile.log');

$logger->debug('This is a debug message');
$logger->info('This is an info message');
$logger->notice('This is a notice message');
$logger->trace('This is a trace message');
$logger->warn({ warning => 'This is a warning message' });
```

## Description

The `Log::Abstraction` class provides a flexible logging layer on top of
different types of loggers, including code references, arrays, file paths,
and objects.  It also supports logging to syslog if configured.

### Unicode

Messages may be character strings containing any Unicode text.  The file,
fd and scalar-path backends write character strings as UTF-8 (unless an
`fd` handle already has a `:utf8` or `:encoding` layer, in which case the
handle does the encoding), and `format => 'json'` output is UTF-8 too.
journald fields are sent as UTF-8.  Byte strings are written unchanged.

## Methods

### New

```perl
my $logger = Log::Abstraction->new(%args);
my $logger = Log::Abstraction->new(\%args);
my $logger = Log::Abstraction->new($file_path);

# Clone with optional overrides
my $clone = $logger->new(level => 'debug');
```

Creates a new `Log::Abstraction` instance, or clones an existing one when
called on an object.  It may also be called as a plain function,
`Log::Abstraction::new(%args)`, which behaves like
`Log::Abstraction->new(%args)`.

#### Arguments

- `carp_on_warn`

    If set to 1, and no `logger` is given, call `Carp::carp` on `warn()`.
    Also causes `error()` to `carp` if `croak_on_error` is not set.

- `croak_on_error`

    If set to 1, and no `logger` is given, call `Carp::croak` on `error()`.

- `config_file`

    Path to a configuration file (YAML, XML, INI, etc.) whose contents are
    merged with the constructor arguments.  On non-Windows systems the class
    can also be configured via environment variables prefixed with
    `"Log::Abstraction::"`.  For example:

    ```
    export Log::Abstraction::script_name=foo
    ```

- `ctx`

    Arbitrary context value passed through to CODE-ref logger callbacks as
    `$args->{ctx}`.

- `format`

    Format string for file/fd backends.  Tokens expanded at log time:

    ```
    %callstack%   caller file and line number
    %class%       blessed class of the logger object
    %level%       upper-cased level name
    %message%     the joined log message
    %timestamp%   YYYY-MM-DD HH:MM:SS (local time)
    %env_FOO%     value of $ENV{FOO}, or empty string if unset
    ```

    Tokens are only expanded in the format string itself, never in the text
    of the message.  Each line break in a message is followed by a tab, so a
    continuation line can't be mistaken for a new log entry.

    The special value `"json"` (not a format string but a magic keyword) switches
    all file and fd backends to emit one compact JSON object per log line:

    ```
    {"timestamp":"...","level":"info","message":"...","file":"...","line":42}
    ```

    This format is compatible with log aggregators such as journald, Loki,
    Elasticsearch, and Splunk.  `class` is included when the logger is a subclass
    of `Log::Abstraction`.  Keys are emitted in sorted order.

    **Security note:** because `format` may contain `%env_*%` tokens, avoid
    granting untrusted sources write access to config files that set this key.

- `level`

    Minimum level at which to emit log entries.  Defaults to `"warning"`.
    Valid values (case-insensitive): `trace`, `debug`, `info`/`informational`,
    `notice`, `warn`/`warning`, `error`/`err`, `crit`/`critical`/`fatal`,
    `alert`, `emerg`/`emergency`/`panic`.  `trace` and `debug` are the same
    threshold (see ["LIMITATIONS"](#limitations)).

- `max_messages`

    The most entries to keep in the in-memory history returned by
    ["messages"](#messages); when it is full, the oldest entry is discarded.  Must be a
    non-negative integer.  Unlimited by default, which in a long-running process
    means the history grows without bound.

- `logger`

    One of:

    - A code reference -- called with a hashref `{ class, file, line, level, message, ctx }`
    - An object -- method matching the level name is called on it
    - A hash reference -- may contain `file`, `array`, `fd`, `syslog`, `journald`, and/or `sendmail` keys
    - An array reference -- `{ level, message }` hashrefs are pushed onto it
    - A scalar string -- treated as a file path to append to

    When not supplied, [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) is initialised as the default backend.

    The `sendmail` sub-hash supports:
    `host`, `port`, `to`, `from`, `subject`, `level`, `min_interval`.
    `to` is required.  `level` may be a level name or a syslog number (0-7);
    without it, every message is emailed.
    At most one email is sent per `min_interval` seconds per instance.  If
    delivery fails, `Carp::carp` is called and the other backends still receive
    the message.

    The `syslog` sub-hash supports:

    - `facility` -- the syslog facility (default: `local0`)
    - `level` -- only messages at this level or more severe are sent; a level name or a syslog number (0-7)
    - `host` (or its alias `server`), and any other ["setlogsock" in Sys::Syslog](https://metacpan.org/pod/Sys%3A%3ASyslog#setlogsock) option -- passed to `setlogsock()`

    The `journald` sub-hash sends each message as a single datagram to the
    systemd journal using the journald native protocol.  Supported keys:

    - `socket` -- path to the journald socket (default: `/run/systemd/journal/socket`)
    - `identifier` -- value for the `SYSLOG_IDENTIFIER` field (default: basename of `$0`)
    - any other key -- included verbatim as an uppercase journald field name.
    The upper-cased name must contain only `A-Z`, `0-9` and `_`, and must not
    start with `_`; `new()` croaks otherwise.

    The `PRIORITY` field is set automatically from the log level (0=emerg...7=debug).
    A message too large for one datagram (about 200KB) is truncated and
    `[truncated]` appended.
    Delivery failures are silent apart from a single `Carp::carp` (repeated only
    after a later send has succeeded); the application is never crashed by a
    journald error.

- `script_name`

    Script name reported to syslog.  Auto-detected from `$0` if not supplied.

- `verbose`

    When using the default Log::Log4perl backend, raises the logging level to
    DEBUG when set to a true value.

#### Returns

A blessed `Log::Abstraction` object.

#### Side Effects

Loads `File::Basename` if `syslog` is configured (either at the top level
or in a `logger` hash) and `script_name` is not supplied.  Loads
`Log::Log4perl` if no logger backend is specified.

#### Example

```perl
my $logger = Log::Abstraction->new(
    level  => 'debug',
    logger => \@messages,
);

my $clone = $logger->new(level => 'info');
```

#### API Specification

##### Input

```perl
{
    carp_on_warn   => { type => 'boolean', optional => 1 },
    config_file    => { type => 'string',  optional => 1 },
    croak_on_error => { type => 'boolean', optional => 1 },
    ctx            => { optional => 1 },
    format         => { type => 'string',  optional => 1 },
    level          => { type => 'string',  regex => qr/^(trace|debug|info(?:rmational)?|notice|warn(?:ing)?|err(?:or)?|crit(?:ical)?|fatal|alert|emerg(?:ency)?|panic)$/i, optional => 1 },
    logger         => { optional => 1 },
    max_messages   => { type => 'integer', min => 0, optional => 1 },
    script_name    => { type => 'string',  optional => 1 },
    verbose        => { type => 'boolean', optional => 1 },
}
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

```perl
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
"<class>: invalid sendmail level '<l>'"   The sendmail sub-hash 'level' is neither
                                          a level name nor 0-7.  (A bad syslog
                                          sub-hash 'level' gives "invalid syslog
                                          level", as above.)
"<class>: the sendmail backend needs      The sendmail sub-hash has no 'to' key.
  a 'to' address"
"<class>: invalid journald field name     An extra journald key, upper-cased, is not
  '<k>'"                                  [A-Z0-9_] or starts with '_'.
```

The following are not raised by `new()` but later, by the logging methods
(`trace`, `debug`, `info`, `notice`, `warn`, `error`, `fatal`), when
a message that passes the level threshold reaches the backend concerned.
Croaks are configuration errors; delivery failures only carp, because a
logging failure must never crash the application.

```
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
```

#### Pseudocode

```perl
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
    copy message history list
    count the clone as a user of an open syslog connection
    RETURN clone

  IF syslog requested (top level or in a logger hash) and script_name
  not supplied:
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

  CROAK if max_messages is given and is not a non-negative integer

  IF logger is a hash:
    CROAK if the syslog or sendmail sub-hash 'level' is not a level
      name or 0-7
    CROAK if a sendmail sub-hash has no 'to' address
    CROAK if an extra journald key is not a valid journald field name

  RETURN bless { messages => [], merged args, level => numeric } as class

END FUNCTION
```

### Level

```perl
my $current = $logger->level();
$logger->level('debug');
```

Get or set the minimum logging level.  When setting, returns `$self` to
allow method chaining.  When getting, returns the current level as an
integer (per the syslog numeric scale; lower numbers are higher priority).

#### Arguments

- `$level` (optional)

    A level name string: `trace`, `debug`, `info`, `notice`, `warn`/`warning`,
    or `error`.  Case-insensitive.  Omit to perform a pure get.

#### Returns

In getter mode: an integer in the range 0 (emergency) to 7 (debug/trace).

In setter mode: `$self` (to allow chaining).

#### Side Effects

When setting, updates `$self->{level}`.

#### Example

```perl
$logger->level('debug');
my $n = $logger->level();   # e.g. 7

# Method chaining
$logger->level('info')->info('Now at info level');
```

#### API Specification

##### Input

```perl
{
    level => { type => 'string', regex => qr/^(trace|debug|info(?:rmational)?|notice|warn(?:ing)?|err(?:or)?|crit(?:ical)?|fatal|alert|emerg(?:ency)?|panic)$/i, optional => 1 },
}
```

##### Output

```perl
Getter: { type => 'integer', min => 0, max => 7 }
Setter: { type => 'object', class => 'Log::Abstraction' }
```

#### Messages

```
Warning                                   Meaning / Action
----------------------------------------  ------------------------------------------
"<class>: invalid syslog level '<l>'"     The supplied level name is not recognised.
                                          Use trace/debug/info/notice/warn/error.
```

#### Pseudocode

```
FUNCTION level(self, level?)

  IF level argument supplied:
    CARP and RETURN undef if level is not a recognised syslog name
    Store syslog_values{level} in self->{'level'}
    RETURN self  (allows method chaining)

  ELSE (getter mode):
    RETURN self->{'level'}  (current numeric threshold)

END FUNCTION
```

### Is\_Debug

```
if($logger->is_debug()) { ... }
```

Returns a true value when the logger is configured at `debug` level or
below (i.e. debug messages will actually be emitted).  Provided for
compatibility with [Log::Any](https://metacpan.org/pod/Log%3A%3AAny).

#### Arguments

None.

#### Returns

`1` if the current level threshold includes debug (or trace) messages;
`0` otherwise.

#### Example

```
if($logger->is_debug()) {
    $logger->debug('Expensive diagnostic: ' . Dumper(\%state));
}
```

#### API Specification

##### Input

```
{} (no arguments)
```

##### Output

```perl
{ type => 'boolean' }
```

### Messages

```perl
my $aref = $logger->messages();
```

Returns a reference to a shallow copy of all messages emitted through this
logger since it was created (or since the last clone).

#### Arguments

None.

#### Returns

An array reference of hashrefs, each with keys `level` (string) and
`message` (string).

#### Side Effects

None.  The returned array is a copy; modifying it does not affect the
internal history.

#### Example

```perl
$logger->info('hello');
my $msgs = $logger->messages();
# $msgs->[0] = { level => 'info', message => 'hello' }
```

#### API Specification

##### Input

```
{} (no arguments)
```

##### Output

```perl
{ type => 'arrayref', element_type => { level => 'string', message => 'string' } }
```

### Trace

```
$logger->trace(@messages);
$logger->trace(\@messages);
```

Logs a message at `trace` level.  syslog has no priority below debug, so
`trace` shares `debug`'s threshold: trace messages are emitted whenever
debug messages are, and are sent to syslog and journald as debug.  The
message is dropped silently when the configured level is above `debug`.

#### Arguments

- `@messages`

    One or more strings, or a single array reference.  All elements are joined
    without a separator before storage.

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to the internal message history and dispatches to configured backends.

#### Example

```perl
$logger->trace('entering sub foo, args=', join(',', @args));

# Chaining
$logger->trace('start')->debug('details')->info('summary');
```

#### API Specification

##### Input

```perl
{ messages => { type => [ 'arrayref', 'scalar' ] } }
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under ["new"](#new)'s MESSAGES.

### Debug

```
$logger->debug(@messages);
$logger->debug(\@messages);
```

Logs a message at `debug` level.

#### Arguments

- `@messages`

    One or more strings, or a single array reference.

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to the internal message history and dispatches to configured backends.

#### Example

```
$logger->debug('Query took ', $elapsed, 'ms');
```

#### API Specification

##### Input

```perl
{ messages => { type => [ 'arrayref', 'scalar' ] } }
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under ["new"](#new)'s MESSAGES.

### Info

```
$logger->info(@messages);
$logger->info(\@messages);
```

Logs a message at `info` level.

#### Arguments

- `@messages`

    One or more strings, or a single array reference.

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to the internal message history and dispatches to configured backends.

#### Example

```
$logger->info('Server started on port ', $port);
```

#### API Specification

##### Input

```perl
{ messages => { type => [ 'arrayref', 'scalar' ] } }
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under ["new"](#new)'s MESSAGES.

### Notice

```
$logger->notice(@messages);
$logger->notice(\@messages);
```

Logs a message at `notice` level (higher priority than `info`, lower than
`warn`).

#### Arguments

- `@messages`

    One or more strings, or a single array reference.

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to the internal message history and dispatches to configured backends.

#### Example

```
$logger->notice('Configuration reloaded');
```

#### API Specification

##### Input

```perl
{ messages => { type => [ 'arrayref', 'scalar' ] } }
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

Croaks if the configured backend is misconfigured, and carps if delivery
fails; see the second table under ["new"](#new)'s MESSAGES.

### Warn

```perl
$logger->warn(@messages);
$logger->warn(\@messages);
$logger->warn(warning => $text);
$logger->warn({ warning => $text });
$logger->warn(warning => \@parts);
```

Logs a warning message.  Also dispatches to syslog and/or email backends
when those are configured.  Falls back to `Carp::carp` when no backend
(`logger`, `array`, `file` or `fd`) is set.  The `Carp::carp` (whether
from `carp_on_warn` or the fallback) only happens when the message passes
the level threshold.

Called as a class method (`Log::Abstraction->warn(...)`, or on a
subclass), it calls `Carp::carp` directly.

A `warn()` call with an empty or all-undef argument list is a silent no-op.

#### Arguments

- `@messages`

    A plain list of strings joined without separator, **or** a named `warning`
    parameter whose value may be a string or an array reference of strings.

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to internal message history.  Writes to all configured backends.
May call `Carp::carp` if `carp_on_warn` is set or no backend is active.

#### Example

```perl
$logger->warn('Disk usage is high');
$logger->warn(warning => 'Connection reset', ' retrying');
$logger->warn({ warning => ['Part A', 'Part B'] });
```

#### API Specification

##### Input

```perl
# Named form
{ warning => { type => [ 'scalar', 'arrayref' ] } }
# Plain-list form
{ messages => { type => 'arrayref' } }
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

```
(the warning text itself)                 Carped if carp_on_warn is set, or if no
                                          backend (logger, array, file or fd) is
                                          configured, provided the warning passes
                                          the level threshold.  Also carped when
                                          called as a class method.
```

Backend misconfiguration and delivery failures are reported as described
in the second table under ["new"](#new)'s MESSAGES.

### Error

```perl
$logger->error(@messages);
$logger->error(warning => $text);
```

Logs an error-level message.  Behaves identically to `warn()` but at the
`error` level, which triggers `Carp::croak` if `croak_on_error` is set
or no backend (`logger`, `array`, `file` or `fd`) is set.  Called as a
class method, it calls `Carp::croak` directly.

#### Arguments

Same argument forms as `warn()`.

#### Returns

`$self`, to allow method chaining.  Note: if `croak_on_error` is set, the
method never returns -- execution unwinds via `Carp::croak`.

#### Side Effects

Same as `warn()` plus optional `Carp::croak` escalation.

#### Example

```
$logger->error('Fatal: database unavailable');
```

#### API Specification

##### Input

```perl
{ warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

```
Croak                                     Meaning / Action
----------------------------------------  ------------------------------------------
(the error message text itself)           croak_on_error is set, or no backend
                                          (logger, array, file or fd) is
                                          configured, or error() was called as a
                                          class method.  The call stack is unwound.
(the error message text itself), as a     carp_on_warn is set and croak_on_error
  carp                                    is not.
```

Backend misconfiguration and delivery failures are reported as described
in the second table under ["new"](#new)'s MESSAGES.

### Fatal

```
$logger->fatal(@messages);
```

Synonym for `error()`.  Provided for compatibility with logging frameworks
that use `fatal` as the highest-severity level name.

#### Arguments

Same as `error()`.

#### Returns

`$self`.

#### Side Effects

Same as `error()`.

#### Example

```
$logger->fatal('Unrecoverable state; aborting');
```

#### API Specification

##### Input

```perl
{ warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }
```

##### Output

```perl
{ type => 'object', class => 'Log::Abstraction' }
```

#### Messages

Same as `error()`.

## Examples

### CSV File Logging for BI Import

The code-reference backend gives you full control over the output format.
The example below writes every message at `trace` level and above as a
CSV row to a file, producing output that can be loaded directly into a
spreadsheet or BI tool (Tableau, Power BI, Metabase, etc.).

Each row contains: `timestamp`, `level`, `class`, `file`, `line`, `message`.

```perl
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
```

The resulting `app_events.csv` looks like:

```
timestamp,level,class,file,line,message
"2026-05-27T14:00:00Z","trace","Log::Abstraction","app.pl","42","application started"
"2026-05-27T14:00:01Z","info","Log::Abstraction","app.pl","43","user logged in"
"2026-05-27T14:00:02Z","warn","Log::Abstraction","Log/Abstraction.pm","820","disk usage above 80%"
```

Note: `class` is always `Log::Abstraction` (or the subclass name if you subclass the
module).  For `trace`, `debug`, `info`, and `notice` calls, `file` and `line`
resolve to the caller's source location.  For `warn` and `error` calls the
extra `_high_priority` stack frame shifts the resolution one level inward, so
`file` and `line` point into the module rather than the calling script.

For production use, consider replacing the manual `$csv_field` quoting with
[Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV) for correct handling of embedded newlines and other edge cases.

If you also want real-time alerting on critical events, add the email logic
directly inside the code-ref callback -- test `$args->{level}` and call
your mailer for `warn` / `error` messages while still writing the CSV row
for every message.

Alternatively, use the `sendmail` hash-ref backend on its own (without the
code-ref) and add a `level` key to restrict emails to warn-and-above:

```perl
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
```

Note: the `sendmail` backend writes the module's standard text format, not
CSV.  To produce CSV rows _and_ send email alerts from the same logger,
embed both the CSV-write and the mail-send logic inside a single code-ref
callback as described above.

## Limitations

- **Syslog hash mutation**

    The `syslog` sub-hash passed to `new()` is mutated in-place on the first
    log call: `facility` and `level` are temporarily removed before
    `setlogsock()` is called, then restored; `server` is permanently renamed
    to `host`.  Sharing a syslog hashref between two `Log::Abstraction`
    instances is not supported and produces undefined behaviour on the second
    instance.

- **trace is the same threshold as debug**

    syslog has no priority below debug, so `trace` and `debug` share one
    threshold: a logger at `debug` level also emits `trace` messages, and
    `trace` can't be filtered separately.

- **Unbounded message history by default**

    Every logged message is kept in the history returned by ["messages"](#messages).  In a
    long-running process (a daemon, or under mod\_perl) set `max_messages` to
    stop it growing without bound.

- **syslog connection is shared**

    `openlog()` and `closelog()` act on the whole process, so every instance
    logging to syslog shares one connection, opened with the `script_name` of
    the first.  It is closed when the last such instance is destroyed.

- **No structured log fields**

    All backends except the CODE-ref backend reduce the message to a flat string.
    To log structured key/value pairs, use a CODE-ref backend that formats the
    data itself.

- **Single-threaded email throttle**

    The `min_interval` throttle for the `sendmail` backend and the
    `_syslog_opened` first-open flag are stored on the object without mutex
    protection.  Under Perl ithreads or other concurrency models, objects shared
    between threads are not safe.

- **OpenTelemetry not yet supported**

    The OTel Logs SDK for Perl is incomplete; see the TODO block at the top of
    `lib/Log/Abstraction.pm` for a full status report and the list of blockers.
    Monitor [https://metacpan.org/pod/OpenTelemetry::SDK](https://metacpan.org/pod/OpenTelemetry::SDK) for progress.

- **Log::Log4perl is a de-facto required dependency**

    When no `logger`, `file`, or `array` backend is configured, `new()`
    loads [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) and uses it as the default backend.  Although listed
    as an optional runtime dependency, it is required in that default-backend
    path.

## Author

Nigel Horne `njh@nigelhorne.com`

## See Also

- [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) and [Log::Any::Adapter::Abstraction](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter%3A%3AAbstraction)

    Route messages from any `Log::Any`-using CPAN module through
    `Log::Abstraction` with a single `Log::Any::Adapter->set()` call.

- [Test Dashboard](https://nigelhorne.github.io/Log-Abstraction/coverage/)

## Support

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-log-abstraction at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Abstraction](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Abstraction).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

```
perldoc Log::Abstraction
```

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Log-Abstraction](https://metacpan.org/dist/Log-Abstraction)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Abstraction](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Abstraction)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Log-Abstraction](http://matrix.cpantesters.org/?dist=Log-Abstraction)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Log::Abstraction](http://deps.cpantesters.org/?module=Log::Abstraction)

## Formal Specification

### New

```
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
│ args?.logger ≠ ∅ ⟹ result!.logger = args?.logger
│ args?.logger = ∅ ∧ args?.file = ∅ ∧ args?.array = ∅
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
```

### Level

```
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
```

### Is\_Debug

```
┌─ IsDebug ──────────────────────────────────────────────────
│ ΞLogState
│ result! : BOOLEAN
├─────────────────────────────────────────────────────────────
│ result! = (level ≥ syslog_values('debug'))
└─────────────────────────────────────────────────────────────
```

### Messages

```
┌─ Messages ─────────────────────────────────────────────────
│ ΞLogState
│ result! : seq { level : STRING; message : STRING }
├─────────────────────────────────────────────────────────────
│ result! = messages
└─────────────────────────────────────────────────────────────
```

### Trace

```
┌─ Trace ────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
├─────────────────────────────────────────────────────────────
│ syslog_values('trace') ≤ level
│ messages' = messages ⌢ ⟨{level ↦ 'trace', message ↦ ⊕(msg?)}⟩
└─────────────────────────────────────────────────────────────
```

### Debug

```
┌─ Debug ────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
├─────────────────────────────────────────────────────────────
│ syslog_values('debug') ≤ level
│ messages' = messages ⌢ ⟨{level ↦ 'debug', message ↦ ⊕(msg?)}⟩
└─────────────────────────────────────────────────────────────
```

### Info

```
┌─ Info ─────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
├─────────────────────────────────────────────────────────────
│ syslog_values('info') ≤ level
│ messages' = messages ⌢ ⟨{level ↦ 'info', message ↦ ⊕(msg?)}⟩
└─────────────────────────────────────────────────────────────
```

### Notice

```
┌─ Notice ───────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
├─────────────────────────────────────────────────────────────
│ syslog_values('notice') ≤ level
│ messages' = messages ⌢ ⟨{level ↦ 'notice', message ↦ ⊕(msg?)}⟩
└─────────────────────────────────────────────────────────────
```

### Warn

```
┌─ Warn ─────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING | { warning : STRING | seq STRING }
├─────────────────────────────────────────────────────────────
│ msg? ≠ ∅ ∧ join(msg?) ≠ ''
│ syslog_values('warn') ≤ level
│ messages' = messages ⌢ ⟨{level ↦ 'warn', message ↦ join(msg?)}⟩
│ (carp_on_warn ∨ no_backend) ⟹ carp(join(msg?))
└─────────────────────────────────────────────────────────────

no_backend ≡ logger = ∅ ∧ array = ∅ ∧ file = ∅ ∧ fd = ∅

Called as a class method (no LogState): carp(join(msg?)), and
messages is not touched.
```

### Error

```
┌─ Error ────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING | { warning : STRING | seq STRING }
├─────────────────────────────────────────────────────────────
│ msg? ≠ ∅ ∧ join(msg?) ≠ ''
│ syslog_values('error') ≤ level
│ messages' = messages ⌢ ⟨{level ↦ 'error', message ↦ join(msg?)}⟩
│ (croak_on_error ∨ no_backend) ⟹ execution_continues = false
└─────────────────────────────────────────────────────────────

Called as a class method (no LogState): croak(join(msg?)).
```

### Fatal

```
fatal ≡ error   (identical operation schema)
```

## Copyright and License

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
