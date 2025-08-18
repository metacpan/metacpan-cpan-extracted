# NAME

Log::Abstraction - Logging Abstraction Layer

# VERSION

0.25

# SYNOPSIS

    use Log::Abstraction;

    my $logger = Log::Abstraction->new(logger => 'logfile.log');

    $logger->debug('This is a debug message');
    $logger->info('This is an info message');
    $logger->notice('This is a notice message');
    $logger->trace('This is a trace message');
    $logger->warn({ warning => 'This is a warning message' });

# DESCRIPTION

The `Log::Abstraction` class provides a flexible logging layer on top of different types of loggers,
including code references, arrays, file paths, and objects.
It also supports logging to syslog if configured.

# METHODS

## new

    my $logger = Log::Abstraction->new(%args);

Creates a new `Log::Abstraction` object.

The argument can be a hash,
a reference to a hash or the `logger` value.
The following arguments can be provided:

- `carp_on_warn`

    If set to 1,
    and `logger` is not given,
    call `Carp:carp` on `warn()`.

- `config_file`

    Points to a configuration file which contains the parameters to `new()`.
    The file can be in any common format,
    including `YAML`, `XML`, and `INI`.
    This allows the parameters to be set at run time.

    On a non-Windows system,
    the class can be configured using environment variables starting with `"Log::Abstraction::"`.
    For example:

        export Log::Abstraction::script_name=foo

    It doesn't work on Windows because of the case-insensitive nature of that system.

- `level`

    The minimum level at which to log something,
    the default is "warning".

- `logger`

    A logger can be one or more of:

    - a code reference
    - an object
    - a hash of options
    - sendmail - send higher priority messages to an email address

        To send an e-mail you need ["require Email::Simple"](#require-email-simple), ["require Email::Sender::Simple"](#require-email-sender-simple) and [Email::Sender::Transport::SMTP](https://metacpan.org/pod/Email%3A%3ASender%3A%3ATransport%3A%3ASMTP).

    - array - a reference to an array
    - fd - containing a file descriptor to log to
    - file - containing the filename

    Defaults to [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl).
    In that case,
    the argument 'verbose' to new() will raise the logging level.

- `format`

    The format of the message.
    Expands:

    - %callstack%
    - %level%
    - %class%
    - %message%
    - %timestamp%

        &#x3d;%item \* %env\_foo%

        Replaces with `$ENV{foo}`

- `syslog`

    A hash reference for syslog configuration.
    Only warnings and above will be sent to syslog.
    This restriction should be lifted in the future,
    since it's reasonable to send notices and above to the syslog.

- `script_name`

    The name of the script.
    It's needed when `syslog` is given,
    if none is passed, the value is guessed.

Clone existing objects with or without modifications:

    my $clone = $logger->new();

## \_sanitize\_email\_header

    my $clean_value = _sanitize_email_header($raw_value);

Internal routine to remove carriage return and line feed characters from an email header value to prevent header injection or formatting issues.

- Input

    Takes a single scalar value, typically a string representing an email header field.

- Behavior

    If the input is undefined, returns \`undef\`. Otherwise, removes all newline characters (\`\\n\`), carriage returns (\`\\r\`), and CRLF pairs from the string.

- Output

    Returns the sanitized string with CR/LF characters removed.

### FORMAL SPECIFICATION

If the input is undefined (∅), the output is also undefined (∅).

If the input is defined, the result is a defined string with CR and LF characters removed.

    [CHAR]

    CR, LF : CHAR
    CR == '\r'
    LF == '\n'

    STRING == seq CHAR

    SanitizeEmailHeader
        raw?: STRING
        sanitized!: STRING
        -------------------------------------------------
        sanitized! = [ c : raw? | c ≠ CR ∧ c ≠ LF ]

## level

Get/set the minimum level to log at.
Returns the current level, as an integer.

## is\_debug

Are we at a debug level that will emit debug messages?
For compatability with [Log::Any](https://metacpan.org/pod/Log%3A%3AAny).

## messages

Return all the messages emitted so far

## debug

    $logger->debug(@messages);

Logs a debug message.

## info

    $logger->info(@messages);

Logs an info message.

## notice

    $logger->notice(@messages);

Logs a notice message.

## error

    $logger->error(@messages);

Logs an error message. This method also supports logging to syslog if configured.
If not logging mechanism is set,
falls back to `Carp`.

## trace

    $logger->trace(@messages);

Logs a trace message.

## warn

    $logger->warn(@messages);
    $logger->warn(\@messages);
    $logger->warn(warning => \@messages);

Logs a warning message. This method also supports logging to syslog if configured.
If not logging mechanism is set,
falls back to `Carp`.

## \_high\_priority

Helper to handle important messages.

# AUTHOR

Nigel Horne `njh@nigelhorne.com`

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

# COPYRIGHT AND LICENSE

Copyright (C) 2025 Nigel Horne

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
