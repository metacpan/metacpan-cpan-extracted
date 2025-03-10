# NAME

Log::YetAnother - A flexible logging class for Perl

# VERSION

0.03

# SYNOPSIS

    use Log::YetAnother;

    my $logger = Log::YetAnother->new(logger => 'logfile.log');

    $logger->debug('This is a debug message');
    $logger->info('This is an info message');
    $logger->notice('This is a notice message');
    $logger->trace('This is a trace message');
    $logger->warn({ warning => 'This is a warning message' });

# DESCRIPTION

The `Log::YetAnother` class provides a flexible logging mechanism that can handle different types of loggers,
including code references, arrays, file paths, and objects.
It also supports logging to syslog if configured.

# METHODS

## new

    my $logger = Log::YetAnother->new(%args);

Creates a new `Log::YetAnother` object.
The argument can be a hash,
a reference to a hash or the `logger` value.
The following arguments can be provided:

- `logger` - A logger can be a code reference, an array reference, a file path, or an object.
- `syslog` - A hash reference for syslog configuration.
- `script_name` - Name of the script, needed when `syslog` is given

## debug

    $logger->debug(@messages);

Logs a debug message.

## info

    $logger->info(@messages);

Logs an info message.

## notice

    $logger->notice(@messages);

Logs a notice message.

## trace

    $logger->trace(@messages);

Logs a trace message.

## warn

    $logger->warn(@messages);
    $logger->warn(warning => \@messages);

Logs a warning message. This method also supports logging to syslog if configured.
If not logging mechanism is set,
falls back to `Carp`.

# AUTHOR

Nigel Horne ` <njh@nigelhorne.com` >

# COPYRIGHT AND LICENSE

Copyright (C) 2025 Nigel Horne

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
