# NAME

Log::Minimal::Instance - Instance based on Log::Minimal

# SYNOPSIS

    use Log::Minimal::Instance;

    # log to file
    my $log = Log::Minimal::Instance->new(
        base_dir => 'log',
        pattern  => 'myapp.log.%Y%m%d',  # File::Stamped style
    );

    # same as Log::Minimal method
    $log->debugf('debug');
    $log->infof('info');

    # ./log/myapp.log.20130101
    2013-01-01T16:15:39 [DEBUG] debug at lib/MyApp.pm line 10
    2013-01-01T16:15:39 [INFO] info at lib/MyApp.pm line 11

    # log to stderr
    $log = Log::Minimal::Instance->new();

    # specified $Log::Minimal::LOG_LEVEL
    $log = Log::Minimal::Instance->new(
        level => 'WARN',
    );

    # original methods
    $log->infod(\%hash);
    $log->warnd(\@array);
    $log->log_to('finish.log.%Y%m%d', $message); # log to log/finish.log.20130101

# DESCRIPTION

Log::Minimal::Instance is used in Log::Minimal based module to create an instance.

# IMPORTED METHODS

See [Log::Minimal](https://metacpan.org/pod/Log::Minimal)

- new(%args)

    Create new instance of Log::Minimal::Instance based on [Log::Minimal](https://metacpan.org/pod/Log::Minimal).

    Attributes are following:

    - level

            Set to $Log::Minimal::LOG_LEVEL

    - base\_dir

            Base directory for log file

    - pattern

            This is file name pattern that is same of L<File::Stamped>.

    - symlink

            Generate symlink file for log file.

    - callback

            See L<File::Stamped>.

    - close\_after\_write

            Default value is 1.

    - iomode

            Default value is '>>:utf8'.

    - autoflush

            Default value is true.

    - rotationtime

            Default value is true.

    - auto\_make\_dir

            Default value is false.

- critf
- warnf
- infof
- debugf
- critff
- warnff
- infoff
- debugff

# ORIGINAL METHODS

- critd($value)
- warnd($value)
- infod($value)
- debugd($value)

When expressed in code the above methods:

    use Log::Minimal;
    infof( ddf(\%hash) );

- log\_to($pattern, $message)
- log\_to(\[ $pattern, $symlink \], $message)
- log\_to({ pattern => $pattern, symlink => $symlink, ... }, $message)

        # $pattern is File::Stamped style.
        $log->log_to('trace.log.%Y%m%d', 'traceroute');

        # ./log/trace.log.20130101
        2013-01-01T16:15:40 traceroute at lib/MyApp.pm line 13

        # with symlink
        $log->log_to([ 'trace.log.%Y%m%d', 'trace.log' ], 'blah blah blah');

# AUTHOR

Kosuke Arisawa <arisawa {at} gmail.com>

# COPYRIGHT

Copyright 2013- Kosuke Arisawa

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[Log::Minimal](https://metacpan.org/pod/Log::Minimal)

[File::Stamped](https://metacpan.org/pod/File::Stamped)
