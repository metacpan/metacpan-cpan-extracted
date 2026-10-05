## Name

Log::Abstraction - Logging Abstraction Layer

## Version

0.37

## Synopsis

```perl
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

### Structured Fields

Every logging method accepts a hash reference of structured fields after
the message:

```perl
$logger->info('User logged in', { user_id => 42, ip => $ip });
$logger->warn('Slow query', { ms => 1250 });
```

A hash reference is taken as fields only when it is the last of two or more
arguments, so `warn({ warning => ... })` keeps its meaning, and a lone
hash reference is still a message.  An empty hash reference is ignored.  The
fields are copied, so changing the hash afterwards doesn't change what was
logged.  They are kept out of the message and go to each backend as follows:

- ["messages"](#messages), `array` and an ARRAY `logger` -- a `fields` key in
the entry, alongside `level` and `message`.
- a CODE `logger` -- a `fields` key in the hashref it is called with.
- `format => 'json'` -- a nested `fields` object.  Objects are
stringified; other references are kept as JSON data.
- `journald` -- journal fields.  Each name is upper-cased, characters
other than `A-Z`, `0-9` and `_` become `_`, leading underscores are
removed and it is cut to 64 characters; a field left with no name is
dropped.  Fields override the extra keys in the `journald` hash, but never
`MESSAGE`, `PRIORITY` or `SYSLOG_IDENTIFIER`.
- text formats (`file`, `fd`, a scalar `logger`), `syslog`,
`sendmail` and object loggers -- appended to the message as logfmt-style
`key=value` pairs in key order, e.g. `User logged in ip=10.0.0.1 user_id=42`.
Characters other than `[\w.-]` in a key become `_`.  A value that is empty
or contains white space, `"`, `=` or `\` is double-quoted, with `"` and
`\` escaped and control characters written as `\n`, `\r`, `\t` or
`\xNN`.  Objects are stringified and other references written as JSON.  An
object logger is passed the pairs as an extra argument after the message.

When logging through [Log::Any](https://metacpan.org/pod/Log%3A%3AAny), a hash reference at the end of the call,
together with the proxy's `context`, arrives here as fields; see
["structured" in Log::Any::Adapter::Abstraction](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter%3A%3AAbstraction#structured).

### Per-Backend Level and Format

Every backend can have its own `level` and `format`, as well as the
logger's.  `syslog`, `journald` and `sendmail` are hashes already, so
they take them as keys.  `file`, `fd` and `array`, inside a `logger` hash
or at the top level, may be given as a hash holding the destination under
the backend's own name:

```perl
my $log = Log::Abstraction->new(
    level  => 'debug',
    logger => {
        file   => { file => '/var/log/myapp.log', format => 'json' },
        fd     => { fd => \*STDERR, level => 'warning' },
        array  => { array => \@recent, level => 'info' },
        syslog => { level => 'error', format => '%level%: %message%' },
    },
);
```

- `level` -- the backend only gets messages at this level or more
severe.  A level name or a syslog number (0-7).  The logger's `level` is
applied first, so a backend's level can only narrow it: set the logger's
`level` to the most verbose any backend wants.
- `format` -- a format string, or `json`, as for the logger's
["format"](#format), which it overrides.  For `file` and `fd` it is the line
written.  For the others, which by default get the message as it is, it
replaces the message: the `array` entry's `message`, the text sent to
syslog, the journal's `MESSAGE` field and the email body.

The plain forms (`file => $path`, `fd => $handle`,
`array => \@array`) still work and have no level or format of their
own.  A blessed handle object is a destination, not the hash form.

### File Rotation

Log files written by path (a scalar `logger`, a `file` key in a `logger`
hash, and the top-level `file`) can be rotated by size, by time, or both:

```perl
my $log = Log::Abstraction->new(
    file            => '/var/log/myapp.log',
    rotate_size     => '10M',
    rotate_interval => 'daily',
    rotate_keep     => 7,
);
```

Before each write the file is checked, and if it is due it is renamed to
`myapp.log.1`, the old `.1` to `.2` and so on, the oldest beyond
`rotate_keep` being deleted; the line then goes to a new `myapp.log`.  A
rotation that fails (e.g. for lack of permission) is ignored, and the line is
still written.  File handles passed as `fd` aren't rotated.

Rotation isn't coordinated between processes: if several processes log to the
same file, use **logrotate** instead.

#### Logrotate

The file is opened, appended to and closed for every message, never held
open, so **logrotate**'s default (rename the file and let the application
create a new one) works without `copytruncate`, and without sending the
process a `SIGHUP`: the next message is written to the new file.

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

    Format string for the file, fd and scalar-path backends; a backend's own
    `format` (see ["Per-backend level and format"](#per-backend-level-and-format)) overrides it for that
    backend.  Unset or an empty string means the default,
    `%level%> [%timestamp%] %class% %callstack% %message%`.  Tokens expanded
    at log time:

    ```
    %callstack%   caller file and line number
    %class%       blessed class of the logger object
    %level%       upper-cased level name
    %message%     the joined log message
    %timestamp%   the time of the call; YYYY-MM-DD HH:MM:SS local time by
                  default (see timestamp_format, timestamp_precision and utc)
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
    of `Log::Abstraction`, and `fields` when the call has ["Structured fields"](#structured-fields).
    Keys are emitted in sorted order.

    **Security note:** because a format may contain `%env_*%` tokens, which
    expand to environment variables, avoid granting untrusted sources write
    access to config files that set `format` or any backend's `format` (see
    ["Per-backend level and format"](#per-backend-level-and-format)).

- `level`

    Minimum level at which to emit log entries.  Defaults to `"warning"`.
    Valid values (case-insensitive): `trace`, `debug`, `info`/`informational`,
    `notice`, `warn`/`warning`, `error`/`err`, `crit`/`critical`/`fatal`,
    `alert`, `emerg`/`emergency`/`panic`.  `trace` and `debug` are the same
    threshold (see ["LIMITATIONS"](#limitations)).  It may also be an array reference, whose
    first element is used, as some configuration-file formats produce.

- `max_messages`

    The most entries to keep in the in-memory history returned by
    ["messages"](#messages); when it is full, the oldest entry is discarded.  Must be a
    non-negative integer; `0` keeps no history at all.  Unlimited by default, which in a long-running process
    means the history grows without bound.

- `logger`

    One of:

    - A code reference -- called with a hashref `{ class, file, line, level, message, ctx, fields }`
    (`ctx` and `fields` only when there are any)
    - An object -- method matching the level name is called on it
    - A hash reference -- may contain `file`, `array`, `fd`, `syslog`, `journald`, and/or `sendmail` keys,
    each of which may have its own `level` and `format` (see ["Per-backend level and format"](#per-backend-level-and-format))
    - An array reference -- `{ level, message }` hashrefs are pushed onto it, with a
    `fields` key when the call has ["Structured fields"](#structured-fields)
    - A scalar string -- treated as a file path to append to

    When not supplied, [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) is initialised as the default backend.

    The `sendmail` sub-hash supports:
    `host`, `port`, `to`, `from`, `subject`, `level`, `format`,
    `min_interval`.  `to` is required.  With `format`, the email body is the
    formatted line rather than the message.  `level` may be a level name or a syslog number (0-7);
    without it, every message is emailed.
    At most one email is sent per `min_interval` seconds per instance.  If
    delivery fails, `Carp::carp` is called and the other backends still receive
    the message.

    The `syslog` sub-hash supports the keys below.  The message is passed to
    `syslog()` through a `%s` format, so `%` sequences in it, such as `%m`,
    are logged literally.

    - `facility` -- the syslog facility (default: `local0`)
    - `level` -- only messages at this level or more severe are sent; a level name or a syslog number (0-7)
    - `format` -- format the message with this (see ["format"](#format)) before sending it; by default the message is sent as it is
    - `host` (or its alias `server`), and any other ["setlogsock" in Sys::Syslog](https://metacpan.org/pod/Sys%3A%3ASyslog#setlogsock) option -- passed to `setlogsock()`

    The `journald` sub-hash sends each message as a single datagram to the
    systemd journal using the journald native protocol.  Supported keys:

    - `socket` -- path to the journald socket (default: `/run/systemd/journal/socket`)
    - `identifier` -- value for the `SYSLOG_IDENTIFIER` field (default: basename of `$0`)
    - `level` -- only messages at this level or more severe are sent; a level name or a syslog number (0-7)
    - `format` -- the `MESSAGE` field is the message formatted with this (see ["format"](#format)); by default it is the message as it is
    - any other key -- included verbatim as an uppercase journald field name.
    The upper-cased name must contain only `A-Z`, `0-9` and `_`, and must not
    start with `_`; `new()` croaks otherwise.

    The `PRIORITY` field is set automatically from the log level (0=emerg...7=debug).
    A message too large for one datagram (about 200KB) is truncated and
    `[truncated]` appended.
    Delivery failures are silent apart from a single `Carp::carp` (repeated only
    after a later send has succeeded); the application is never crashed by a
    journald error.

- `rotate_interval`

    Rotate log files by time: `hourly`, `daily`, `weekly` (weeks start on
    Monday) or `monthly`, case-insensitive.  Before each write, a file whose
    last-modified time is in an earlier period than now (in local time, or UTC
    with `utc`) is rotated, so a file not written to for a while rotates on the
    next write.  See ["File rotation"](#file-rotation).

- `rotate_keep`

    How many rotated files to keep, `FILE.1` to `FILE._n_` (default 5).  With
    `0`, a file due for rotation is deleted instead.

- `rotate_size`

    Rotate log files that have reached this size: a number of bytes, optionally
    followed by `K`, `M` or `G` (powers of 1024), e.g. `10M`.  See
    ["File rotation"](#file-rotation).

- `script_name`

    Script name reported to syslog.  Auto-detected from `$0` if not supplied.

- `timestamp_format`

    How `%timestamp%`, and the `timestamp` key of `format => 'json'`,
    are written.  Either a ["strftime" in POSIX](https://metacpan.org/pod/POSIX#strftime) pattern (default
    `%Y-%m-%d %H:%M:%S`) or one of these names (case-insensitive):

    ```
    iso8601, rfc3339   2026-10-03T20:14:23-04:00, or 2026-10-04T00:14:23Z with utc
    ```

    The pattern may also use:

    ```
    %N        fractional seconds, 9 digits (nanoseconds)
    %3N       fractional seconds, 3 digits (milliseconds); any width 1-9
    %z        UTC offset as +hhmm (on every platform, unlike some strftimes)
    %:z       UTC offset as +hh:mm, as RFC 3339 needs
    %Z        the time-zone name; "UTC" when utc is set
    %%        a literal %
    ```

    Fractional seconds come from [Time::HiRes](https://metacpan.org/pod/Time%3A%3AHiRes) and are truncated, not rounded;
    digits beyond the system clock's resolution (usually microseconds) are
    noise.  The timestamp is taken once per message, so every backend shows the
    same time.

- `timestamp_precision`

    The number of fractional-second digits, 0-9 (default 0), added after the
    seconds (each `%S`) of whichever `timestamp_format` is in use:

    ```perl
    Log::Abstraction->new(timestamp_format => 'rfc3339', timestamp_precision => 3, utc => 1);
    # 2026-10-04T00:14:24.094Z
    ```

- `utc`

    If true, timestamps are in UTC rather than local time.

- `verbose`

    When using the default Log::Log4perl backend, raises the logging level to
    DEBUG when set to a true value.

#### Returns

A blessed `Log::Abstraction` object.

#### Side Effects

Loads `File::Basename` if `syslog` is configured (either at the top level
or in a `logger` hash) and `script_name` is not supplied.  Loads
`Log::Log4perl` if no backend (`logger`, `file`, `fd` or `array`) is
specified.

#### Example

```perl
my $logger = Log::Abstraction->new(
    level  => 'debug',
    logger => \@messages,
);

my $clone = $logger->new(level => 'info');
```

#### Api Specification

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
    rotate_interval => { type => 'string', regex => qr/^(hourly|daily|weekly|monthly)$/i, optional => 1 },
    rotate_keep    => { type => 'integer', min => 0, optional => 1 },
    rotate_size    => { type => 'string',  regex => qr/^\s*[1-9]\d*\s*[kmg]?b?\s*$/i, optional => 1 },
    script_name    => { type => 'string',  optional => 1 },
    timestamp_format    => { type => 'string', min => 1, optional => 1 },
    timestamp_precision => { type => 'integer', min => 0, max => 9, optional => 1 },
    utc            => { type => 'boolean', optional => 1 },
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
```

The following are not raised by `new()` but later, by the logging methods
(`trace`, `debug`, `info`, `notice`, `warn`, `error`, `fatal`,
`critical`, `alert`, `emergency`), when
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

In setter mode: `$self` (to allow chaining), or `undef`, after a
`Carp::carp`, if the level name is not recognised; the level is then
unchanged.  A false argument (`undef`, `''` or `0`) is a get, not a set,
so levels are set by name.

#### Side Effects

When setting, updates `$self->{level}`.

#### Example

```perl
$logger->level('debug');
my $n = $logger->level();   # e.g. 7

# Method chaining
$logger->level('info')->info('Now at info level');
```

#### Api Specification

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

### Level Detection Methods

- is\_trace
- is\_debug
- is\_info
- is\_notice
- is\_warn
- is\_error
- is\_critical
- is\_alert
- is\_emergency

```
if($logger->is_debug()) { ... }
```

Each returns a true value when a message logged with the method of the same
name (`is_warn` for `warn()`) would pass the logger's level threshold, so
that expensive message-building can be skipped.  They follow the current
threshold, including changes made with ["level"](#level).  As with the levels
themselves, `is_trace` equals `is_debug`.  Provided for compatibility with
[Log::Any](https://metacpan.org/pod/Log%3A%3AAny).

#### Arguments

None.

#### Returns

`1` if messages at that level would be emitted; `0` otherwise.

#### Example

```
if($logger->is_debug()) {
    $logger->debug('Expensive diagnostic: ' . Dumper(\%state));
}

$logger->level('warning');
$logger->is_warn();    # 1
$logger->is_info();    # 0
```

#### Api Specification

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
`message` (string), and `fields` (hashref) when the message was logged with
["Structured fields"](#structured-fields).

#### Side Effects

None.  The returned array is a copy; modifying it does not affect the
internal history.

#### Example

```perl
$logger->info('hello');
my $msgs = $logger->messages();
# $msgs->[0] = { level => 'info', message => 'hello' }
```

#### Api Specification

##### Input

```
{} (no arguments)
```

##### Output

```perl
{ type => 'arrayref', element_type => { level => 'string', message => 'string', fields => 'hashref?' } }
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
    without a separator before storage.  May be followed by a hashref of
    ["Structured fields"](#structured-fields).

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

#### Api Specification

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

    One or more strings, or a single array reference, optionally followed by
    a hashref of ["Structured fields"](#structured-fields).

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to the internal message history and dispatches to configured backends.

#### Example

```
$logger->debug('Query took ', $elapsed, 'ms');
```

#### Api Specification

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

    One or more strings, or a single array reference, optionally followed by
    a hashref of ["Structured fields"](#structured-fields).

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to the internal message history and dispatches to configured backends.

#### Example

```
$logger->info('Server started on port ', $port);
```

#### Api Specification

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

    One or more strings, or a single array reference, optionally followed by
    a hashref of ["Structured fields"](#structured-fields).

#### Returns

`$self`, to allow method chaining.

#### Side Effects

Appends to the internal message history and dispatches to configured backends.

#### Example

```
$logger->notice('Configuration reloaded');
```

#### Api Specification

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
$logger->warn($text, \%fields);
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
    Either form may be followed by a hashref of ["Structured fields"](#structured-fields), e.g.
    `warn('Slow query', { ms => 1250 })`.

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

#### Api Specification

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
$logger->error($text, \%fields);
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

#### Api Specification

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

#### Api Specification

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

### Methods Above Error

- critical
- alert
- emergency

```perl
$logger->critical(@messages);
$logger->alert(warning => $text);
$logger->emergency($text, \%fields);
```

Log a message at a level more severe than `error`:

```
Method      Level       syslog   Priority
----------  ----------  -------  --------
critical    critical    crit     2
alert       alert       alert    1
emergency   emergency   emerg    0
```

#### Arguments

`critical`, `alert` and `emergency` take the same argument forms as
`warn()`.

#### Returns

`$self`, to allow method chaining (unless they croak; see below).

#### Side Effects

These behave like `error()`, at a more severe level: `croak_on_error`, or
having no backend, makes them `Carp::croak`, and `carp_on_warn` makes them
`Carp::carp`.  The level string passed to backends is the method name
(`critical`, `alert` or `emergency`, upper-cased in text formats); syslog
gets `crit`, `alert` or `emerg`, and journald `PRIORITY` 2, 1 or 0.  An
object logger without the method (such as [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl)) is called with
`fatal`, or `error` if it has no `fatal` either.

#### Example

```perl
$logger->critical('Disk 95% full', { mount => '/var' });
$logger->alert('Primary database unreachable');
$logger->emergency('Data corruption detected; shutting down');
```

#### Api Specification

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
    log call: `facility`, `level` and `format` are temporarily removed before
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

- **Structured fields are text in most backends**

    Only the history, array, CODE-ref, JSON and journald backends keep
    ["Structured fields"](#structured-fields) as data.  Text formats, syslog, email and object
    loggers get them as `key=value` text appended to the message, and a custom
    `format` has no token for them on their own.

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

    When no `logger`, `file`, `fd` or `array` backend is configured, `new()`
    loads [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) and uses it as the default backend, so it is a
    required dependency even for applications that never use it.

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
```

### Is\_Trace, Is\_Debug, Is\_Info, Is\_Notice, Is\_Warn, Is\_Error, Is\_Critical, Is\_Alert, Is\_Emergency

```
┌─ IsLevel ──────────────────────────────────────────────────
│ ΞLogState
│ lvl? : LEVEL
│ result! : BOOLEAN
├─────────────────────────────────────────────────────────────
│ result! = (level ≥ syslog_values(lvl?))
└─────────────────────────────────────────────────────────────

is_<lvl> ≡ IsLevel[lvl? := lvl]
```

### Messages

```
┌─ Messages ─────────────────────────────────────────────────
│ ΞLogState
│ result! : seq ENTRY
├─────────────────────────────────────────────────────────────
│ result! = messages
└─────────────────────────────────────────────────────────────
```

### Trace

```
┌─ Trace ────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
│ fields? : FIELDS
├─────────────────────────────────────────────────────────────
│ syslog_values('trace') ≤ level
│ messages' = messages ⌢ ⟨entry('trace', ⊕(msg?), fields?)⟩
└─────────────────────────────────────────────────────────────
```

### Debug

```
┌─ Debug ────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
│ fields? : FIELDS
├─────────────────────────────────────────────────────────────
│ syslog_values('debug') ≤ level
│ messages' = messages ⌢ ⟨entry('debug', ⊕(msg?), fields?)⟩
└─────────────────────────────────────────────────────────────
```

### Info

```
┌─ Info ─────────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
│ fields? : FIELDS
├─────────────────────────────────────────────────────────────
│ syslog_values('info') ≤ level
│ messages' = messages ⌢ ⟨entry('info', ⊕(msg?), fields?)⟩
└─────────────────────────────────────────────────────────────
```

### Notice

```
┌─ Notice ───────────────────────────────────────────────────
│ ΔLogState
│ msg? : seq STRING
│ fields? : FIELDS
├─────────────────────────────────────────────────────────────
│ syslog_values('notice') ≤ level
│ messages' = messages ⌢ ⟨entry('notice', ⊕(msg?), fields?)⟩
└─────────────────────────────────────────────────────────────
```

### Warn

```
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
```

### Error

```
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
```

### Fatal

```
fatal ≡ error   (identical operation schema)
```

### Critical, Alert, Emergency

```
The Error schema, with 'error' replaced by 'critical', 'alert' or
'emergency' respectively.

In every logging schema, when #messages' would exceed max_messages
the oldest entries are dropped: messages' = the last max_messages
entries.  fields? is a hashref given after the message (see
Structured fields); fields? = ∅ when there is none.
```

## Copyright and License

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
