# NAME

Log::Abstraction - Logging Abstraction Layer

# VERSION

0.32

# SYNOPSIS

    use Log::Abstraction;

    my $logger = Log::Abstraction->new(logger => 'logfile.log');

    $logger->debug('This is a debug message');
    $logger->info('This is an info message');
    $logger->notice('This is a notice message');
    $logger->trace('This is a trace message');
    $logger->warn({ warning => 'This is a warning message' });

# DESCRIPTION

The `Log::Abstraction` class provides a flexible logging layer on top of
different types of loggers, including code references, arrays, file paths,
and objects.  It also supports logging to syslog if configured.

# METHODS

## new

    my $logger = Log::Abstraction->new(%args);
    my $logger = Log::Abstraction->new(\%args);
    my $logger = Log::Abstraction->new($file_path);

    # Clone with optional overrides
    my $clone = $logger->new(level => 'debug');

Creates a new `Log::Abstraction` instance, or clones an existing one when
called on an object.

### Arguments

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

        export Log::Abstraction::script_name=foo

- `ctx`

    Arbitrary context value passed through to CODE-ref logger callbacks as
    `$args->{ctx}`.

- `format`

    Format string for file/fd backends.  Tokens expanded at log time:

        %callstack%   caller file and line number
        %class%       blessed class of the logger object
        %level%       upper-cased level name
        %message%     the joined log message
        %timestamp%   YYYY-MM-DD HH:MM:SS (local time)
        %env_FOO%     value of $ENV{FOO}, or empty string if unset

    The special value `"json"` (not a format string but a magic keyword) switches
    all file and fd backends to emit one compact JSON object per log line:

        {"timestamp":"...","level":"info","message":"...","file":"...","line":42}

    This format is compatible with log aggregators such as journald, Loki,
    Elasticsearch, and Splunk.  `class` is included when the logger is a subclass
    of `Log::Abstraction`.

    **Security note:** because `format` may contain `%env_*%` tokens, avoid
    granting untrusted sources write access to config files that set this key.

- `level`

    Minimum level at which to emit log entries.  Defaults to `"warning"`.
    Valid values (case-insensitive): `trace`, `debug`, `info`, `notice`,
    `warn`/`warning`, `error`.

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
    At most one email is sent per `min_interval` seconds per instance.

    The `journald` sub-hash sends each message as a single datagram to the
    systemd journal using the journald native protocol.  Supported keys:

    - `socket` -- path to the journald socket (default: `/run/systemd/journal/socket`)
    - `identifier` -- value for the `SYSLOG_IDENTIFIER` field (default: basename of `$0`)
    - any other key -- included verbatim as an uppercase journald field name

    The `PRIORITY` field is set automatically from the log level (0=emerg...7=debug).
    Delivery failures are silent (`Carp::carp` only); the application is never crashed by a journald error.

- `script_name`

    Script name reported to syslog.  Auto-detected from `$0` if not supplied.

- `verbose`

    When using the default Log::Log4perl backend, raises the logging level to
    DEBUG when set to a true value.

### Returns

A blessed `Log::Abstraction` object.

### Side Effects

Loads `File::Basename` if `syslog` is configured and `script_name` is
not supplied.  Loads `Log::Log4perl` if no logger backend is specified.

### Example

    my $logger = Log::Abstraction->new(
        level  => 'debug',
        logger => \@messages,
    );

    my $clone = $logger->new(level => 'info');

### API Specification

#### Input

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

#### Output

    { type => 'object', class => 'Log::Abstraction' }

### MESSAGES

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

### PSEUDOCODE

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

## level

    my $current = $logger->level();
    $logger->level('debug');

Get or set the minimum logging level.  When setting, returns `$self` to
allow method chaining.  When getting, returns the current level as an
integer (per the syslog numeric scale; lower numbers are higher priority).

### Arguments

- `$level` (optional)

    A level name string: `trace`, `debug`, `info`, `notice`, `warn`/`warning`,
    or `error`.  Case-insensitive.  Omit to perform a pure get.

### Returns

In getter mode: an integer in the range 0 (emergency) to 7 (debug/trace).

In setter mode: `$self` (to allow chaining).

### Side Effects

When setting, updates `$self->{level}`.

### Example

    $logger->level('debug');
    my $n = $logger->level();   # e.g. 7

    # Method chaining
    $logger->level('info')->info('Now at info level');

### API Specification

#### Input

    {
        level => { type => 'string', regex => qr/^(trace|debug|info|notice|warn(?:ing)?|error)$/i, optional => 1 },
    }

#### Output

    Getter: { type => 'integer', min => 0, max => 7 }
    Setter: { type => 'object', class => 'Log::Abstraction' }

### MESSAGES

    Warning                                   Meaning / Action
    ----------------------------------------  ------------------------------------------
    "<class>: invalid syslog level '<l>'"     The supplied level name is not recognised.
                                              Use trace/debug/info/notice/warn/error.

### PSEUDOCODE

    FUNCTION level(self, level?)

      IF level argument supplied:
        CARP and RETURN undef if level is not a recognised syslog name
        Store syslog_values{level} in self->{'level'}
        RETURN self  (allows method chaining)

      ELSE (getter mode):
        RETURN self->{'level'}  (current numeric threshold)

    END FUNCTION

## is\_debug

    if($logger->is_debug()) { ... }

Returns a true value when the logger is configured at `debug` level or
below (i.e. debug messages will actually be emitted).  Provided for
compatibility with [Log::Any](https://metacpan.org/pod/Log%3A%3AAny).

### Arguments

None.

### Returns

`1` if the current level threshold includes debug (or trace) messages;
`0` otherwise.

### Example

    if($logger->is_debug()) {
        $logger->debug('Expensive diagnostic: ' . Dumper(\%state));
    }

### API Specification

#### Input

    {} (no arguments)

#### Output

    { type => 'boolean' }

## messages

    my $aref = $logger->messages();

Returns a reference to a shallow copy of all messages emitted through this
logger since it was created (or since the last clone).

### Arguments

None.

### Returns

An array reference of hashrefs, each with keys `level` (string) and
`message` (string).

### Side Effects

None.  The returned array is a copy; modifying it does not affect the
internal history.

### Example

    $logger->info('hello');
    my $msgs = $logger->messages();
    # $msgs->[0] = { level => 'info', message => 'hello' }

### API Specification

#### Input

    {} (no arguments)

#### Output

    { type => 'arrayref', element_type => { level => 'string', message => 'string' } }

## trace

    $logger->trace(@messages);
    $logger->trace(\@messages);

Logs a message at `trace` level (the most verbose level, below `debug`).
The message is dropped silently when the configured level threshold is above
`trace`.

### Arguments

- `@messages`

    One or more strings, or a single array reference.  All elements are joined
    without a separator before storage.

### Returns

`$self`, to allow method chaining.

### Side Effects

Appends to the internal message history and dispatches to configured backends.

### Example

    $logger->trace('entering sub foo, args=', join(',', @args));

    # Chaining
    $logger->trace('start')->debug('details')->info('summary');

### API Specification

#### Input

    { messages => { type => [ 'arrayref', 'scalar' ] } }

#### Output

    { type => 'object', class => 'Log::Abstraction' }

## debug

    $logger->debug(@messages);
    $logger->debug(\@messages);

Logs a message at `debug` level.

### Arguments

- `@messages`

    One or more strings, or a single array reference.

### Returns

`$self`, to allow method chaining.

### Side Effects

Appends to the internal message history and dispatches to configured backends.

### Example

    $logger->debug('Query took ', $elapsed, 'ms');

### API Specification

#### Input

    { messages => { type => [ 'arrayref', 'scalar' ] } }

#### Output

    { type => 'object', class => 'Log::Abstraction' }

## info

    $logger->info(@messages);
    $logger->info(\@messages);

Logs a message at `info` level.

### Arguments

- `@messages`

    One or more strings, or a single array reference.

### Returns

`$self`, to allow method chaining.

### Side Effects

Appends to the internal message history and dispatches to configured backends.

### Example

    $logger->info('Server started on port ', $port);

### API Specification

#### Input

    { messages => { type => [ 'arrayref', 'scalar' ] } }

#### Output

    { type => 'object', class => 'Log::Abstraction' }

## notice

    $logger->notice(@messages);
    $logger->notice(\@messages);

Logs a message at `notice` level (higher priority than `info`, lower than
`warn`).

### Arguments

- `@messages`

    One or more strings, or a single array reference.

### Returns

`$self`, to allow method chaining.

### Side Effects

Appends to the internal message history and dispatches to configured backends.

### Example

    $logger->notice('Configuration reloaded');

### API Specification

#### Input

    { messages => { type => [ 'arrayref', 'scalar' ] } }

#### Output

    { type => 'object', class => 'Log::Abstraction' }

## warn

    $logger->warn(@messages);
    $logger->warn(\@messages);
    $logger->warn(warning => $text);
    $logger->warn({ warning => $text });
    $logger->warn(warning => \@parts);

Logs a warning message.  Also dispatches to syslog and/or email backends
when those are configured.  Falls back to `Carp::carp` when no logger
backend is set.

A `warn()` call with an empty or all-undef argument list is a silent no-op.

### Arguments

- `@messages`

    A plain list of strings joined without separator, **or** a named `warning`
    parameter whose value may be a string or an array reference of strings.

### Returns

`$self`, to allow method chaining.

### Side Effects

Appends to internal message history.  Writes to all configured backends.
May call `Carp::carp` if `carp_on_warn` is set or no backend is active.

### Example

    $logger->warn('Disk usage is high');
    $logger->warn(warning => 'Connection reset', ' retrying');
    $logger->warn({ warning => ['Part A', 'Part B'] });

### API Specification

#### Input

    # Named form
    { warning => { type => [ 'scalar', 'arrayref' ] } }
    # Plain-list form
    { messages => { type => 'arrayref' } }

#### Output

    { type => 'object', class => 'Log::Abstraction' }

### MESSAGES

    (no croak/carp messages from this method itself; see _high_priority)

## error

    $logger->error(@messages);
    $logger->error(warning => $text);

Logs an error-level message.  Behaves identically to `warn()` but at the
`error` level, which triggers `Carp::croak` if `croak_on_error` is set
or no logger backend is active.

### Arguments

Same argument forms as `warn()`.

### Returns

`$self`, to allow method chaining.  Note: if `croak_on_error` is set, the
method never returns -- execution unwinds via `Carp::croak`.

### Side Effects

Same as `warn()` plus optional `Carp::croak` escalation.

### Example

    $logger->error('Fatal: database unavailable');

### API Specification

#### Input

    { warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }

#### Output

    { type => 'object', class => 'Log::Abstraction' }

### MESSAGES

    Croak                                     Meaning / Action
    ----------------------------------------  ------------------------------------------
    (the error message text itself)           croak_on_error is set, or no backend is
                                              active.  The call stack is unwound.

## fatal

    $logger->fatal(@messages);

Synonym for `error()`.  Provided for compatibility with logging frameworks
that use `fatal` as the highest-severity level name.

### Arguments

Same as `error()`.

### Returns

`$self`.

### Side Effects

Same as `error()`.

### Example

    $logger->fatal('Unrecoverable state; aborting');

### API Specification

#### Input

    { warning => { type => [ 'scalar', 'arrayref' ], optional => 1 } }

#### Output

    { type => 'object', class => 'Log::Abstraction' }

### MESSAGES

Same as `error()`.

# EXAMPLES

## CSV file logging for BI import

The code-reference backend gives you full control over the output format.
The example below writes every message at `trace` level and above as a
CSV row to a file, producing output that can be loaded directly into a
spreadsheet or BI tool (Tableau, Power BI, Metabase, etc.).

Each row contains: `timestamp`, `level`, `class`, `file`, `line`, `message`.

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

The resulting `app_events.csv` looks like:

    timestamp,level,class,file,line,message
    "2026-05-27T14:00:00Z","trace","Log::Abstraction","app.pl","42","application started"
    "2026-05-27T14:00:01Z","info","Log::Abstraction","app.pl","43","user logged in"
    "2026-05-27T14:00:02Z","warn","Log::Abstraction","Log/Abstraction.pm","820","disk usage above 80%"

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

Note: the `sendmail` backend writes the module's standard text format, not
CSV.  To produce CSV rows _and_ send email alerts from the same logger,
embed both the CSV-write and the mail-send logic inside a single code-ref
callback as described above.

# LIMITATIONS

- **Syslog hash mutation**

    The `syslog` sub-hash passed to `new()` is mutated in-place on the first
    log call: `facility` and `level` are temporarily removed before
    `setlogsock()` is called, then restored; `server` is permanently renamed
    to `host`.  Sharing a syslog hashref between two `Log::Abstraction`
    instances is not supported and produces undefined behaviour on the second
    instance.

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

# AUTHOR

Nigel Horne `njh@nigelhorne.com`

# SEE ALSO

- [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) and [Log::Any::Adapter::Abstraction](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter%3A%3AAbstraction)

    Route messages from any `Log::Any`-using CPAN module through
    `Log::Abstraction` with a single `Log::Any::Adapter->set()` call.

- [Test Dashboard](https://nigelhorne.github.io/Log-Abstraction/coverage/)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-log-abstraction at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Abstraction](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Abstraction).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Log::Abstraction

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Log-Abstraction](https://metacpan.org/dist/Log-Abstraction)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Abstraction](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Abstraction)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Log-Abstraction](http://matrix.cpantesters.org/?dist=Log-Abstraction)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Log::Abstraction](http://deps.cpantesters.org/?module=Log::Abstraction)

# FORMAL SPECIFICATION

## new

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

## level

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

## is\_debug

    ┌─ IsDebug ──────────────────────────────────────────────────
    │ ΞLogState
    │ result! : BOOLEAN
    ├─────────────────────────────────────────────────────────────
    │ result! = (level ≥ syslog_values('debug'))
    └─────────────────────────────────────────────────────────────

## messages

    ┌─ Messages ─────────────────────────────────────────────────
    │ ΞLogState
    │ result! : seq { level : STRING; message : STRING }
    ├─────────────────────────────────────────────────────────────
    │ result! = messages
    └─────────────────────────────────────────────────────────────

## trace

    ┌─ Trace ────────────────────────────────────────────────────
    │ ΔLogState
    │ msg? : seq STRING
    ├─────────────────────────────────────────────────────────────
    │ msg? ≠ ⟨⟩
    │ syslog_values('trace') ≤ level
    │ messages' = messages ⌢ ⟨{level ↦ 'trace', message ↦ ⊕(msg?)}⟩
    └─────────────────────────────────────────────────────────────

## debug

    ┌─ Debug ────────────────────────────────────────────────────
    │ ΔLogState
    │ msg? : seq STRING
    ├─────────────────────────────────────────────────────────────
    │ msg? ≠ ⟨⟩
    │ syslog_values('debug') ≤ level
    │ messages' = messages ⌢ ⟨{level ↦ 'debug', message ↦ ⊕(msg?)}⟩
    └─────────────────────────────────────────────────────────────

## info

    ┌─ Info ─────────────────────────────────────────────────────
    │ ΔLogState
    │ msg? : seq STRING
    ├─────────────────────────────────────────────────────────────
    │ msg? ≠ ⟨⟩
    │ syslog_values('info') ≤ level
    │ messages' = messages ⌢ ⟨{level ↦ 'info', message ↦ ⊕(msg?)}⟩
    └─────────────────────────────────────────────────────────────

## notice

    ┌─ Notice ───────────────────────────────────────────────────
    │ ΔLogState
    │ msg? : seq STRING
    ├─────────────────────────────────────────────────────────────
    │ msg? ≠ ⟨⟩
    │ syslog_values('notice') ≤ level
    │ messages' = messages ⌢ ⟨{level ↦ 'notice', message ↦ ⊕(msg?)}⟩
    └─────────────────────────────────────────────────────────────

## warn

    ┌─ Warn ─────────────────────────────────────────────────────
    │ ΔLogState
    │ msg? : seq STRING | { warning : STRING | seq STRING }
    ├─────────────────────────────────────────────────────────────
    │ msg? ≠ ∅ ∧ join(msg?) ≠ ''
    │ syslog_values('warn') ≤ level
    │ messages' = messages ⌢ ⟨{level ↦ 'warn', message ↦ join(msg?)}⟩
    └─────────────────────────────────────────────────────────────

## error

    ┌─ Error ────────────────────────────────────────────────────
    │ ΔLogState
    │ msg? : seq STRING | { warning : STRING | seq STRING }
    ├─────────────────────────────────────────────────────────────
    │ msg? ≠ ∅ ∧ join(msg?) ≠ ''
    │ syslog_values('error') ≤ level
    │ messages' = messages ⌢ ⟨{level ↦ 'error', message ↦ join(msg?)}⟩
    │ croak_on_error = 1 ⟹ execution_continues = false
    └─────────────────────────────────────────────────────────────

## fatal

    fatal ≡ error   (identical operation schema)

# COPYRIGHT AND LICENSE

Copyright (C) 2025-2026 Nigel Horne

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
