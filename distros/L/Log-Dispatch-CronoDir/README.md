[![Build Status](https://travis-ci.org/yowcow/p5-Log-Dispatch-CronoDir.svg?branch=master)](https://travis-ci.org/yowcow/p5-Log-Dispatch-CronoDir)
# NAME

Log::Dispatch::CronoDir - Log dispatcher for logging to time-based directories

# SYNOPSIS

    use Log::Dispatch::CronoDir;

    my $log = Log::Dispatch::CronoDir->new(
        dirname_pattern => '/var/log/%Y/%m/%d',
        permissions     => 0777,
        filename        => 'output.log',
        mode            => '>>:unix',
        binmode         => ':utf8',
        autoflush       => 1,
    );

    # Write log to file `/var/log/2000/01/01/output.log`
    $log->log(level => 'error', message => 'Something has happened');

# DESCRIPTION

Log::Dispatch::CronoDir is a file log dispatcher with time-based directory management.

# METHODS

## new(Hash %args)

Creates an instance.  Accepted hash keys are:

- dirname\_pattern => Str

    Directory name pattern where log files to be written to.
    POSIX strftime's conversion characters `%Y`, `%m`, and `%d` are currently accepted.

- permissions => Octal

    Directory permissions when specified directory does not exist. Optional.
    When not specified, creating directory's permissions are based on current umask.

    Note that this won't work on Windows OS.

- filename => Str

    Log file name to be written in the directory.

- mode => Str

    Mode to be used when opening a file handle.  Default: ">>"

- binmode => Str

    Binmode to specify with `binmode`.  Optional.  Default: None

- autoflush => Bool

    Enable or disable autoflush.  Default: 1

## log(Hash %args)

Writes log to file.

- level => Str

    Log level.

- message => Str

    A message to write to log file.

# SEE ALSO

[Log::Dispatch](https://metacpan.org/pod/Log::Dispatch)

# LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yowcow <yowcow@cpan.org>
