# NAME

Log::Any::Adapter::Syslog - Send Log::Any logs to syslog

# VERSION

version 1.6

# SYNOPSIS

    use Log::Any::Adapter;
    Log::Any::Adapter->set('Syslog');

    # You can override defaults:
    use Unix::Syslog qw{:macros};
    Log::Any::Adapter->set(
        'Syslog',
        # name defaults to basename($0)
        name     => 'my-name',
        # options default to LOG_PID
        options  => LOG_PID|LOG_PERROR,
        # facility defaults to LOG_LOCAL7
        facility => LOG_LOCAL7
    );

# DESCRIPTION

[Log::Any](https://metacpan.org/pod/Log::Any) is a generic adapter for writing logging into Perl modules; this
adapter use the [Unix::Syslog](https://metacpan.org/pod/Unix::Syslog) module to direct that output into the standard
Unix syslog system.

# CONFIGURATION

`Log::Any::Adapter::Syslog` is designed to work out of the box with no
configuration required; the defaults should be reasonably sensible.

You can override the default configuration by passing extra arguments to the
`Log::Any::Adapter` method:

- name

    The _name_ argument defaults to the basename of `$0` if not supplied, and is
    inserted into each line sent to syslog to identify the source.

- options

    The _options_ configure the behaviour of syslog; see [Unix::Syslog](https://metacpan.org/pod/Unix::Syslog) for
    details.

    The default is `LOG_PID`, which includes the PID of the current process after
    the process name:

        example-process[2345]: something amazing!

    The most likely addition to that is `LOG_PERROR` which causes syslog to also
    send a copy of all log messages to the controlling terminal of the process.

    **WARNING:** If you pass a defined value you are setting, not augmenting, the
    options.  So, if you want `LOG_PID` as well as other flags, pass them all.

- facility

    The _facility_ determines where syslog sends your messages.  The default is
    `LOCAL7`, which is not the most useful value ever, but is less bad than
    assuming the fixed facilities.

    See [Unix::Syslog](https://metacpan.org/pod/Unix::Syslog) and [syslog(3)](http://man.he.net/man3/syslog) for details on the available facilities.

- min\_level

    Minimum syslog level. All messages below the selected level will be silently
    discarded. Default is debug.

    If LOG\_LEVEL environment variable is set, it will be used instead. If TRACE
    environment variable is set to true, level will be set to 'trace'. If DEBUG
    environment variable is set to true, level will be set to 'debug'. If VERBOSE
    environment variable is set to true, level will be set to 'info'.If QUIET
    environment variable is set to true, level will be set to 'error'.

# AUTHORS

- Daniel Pittman &lt;daniel@rimspace.net>
- Stephen Thirlwall &lt;sdt@cpan.org>

# CONTRIBUTOR

Maros Kollar &lt;maros.kollar@geizhals.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Stephen Thirlwall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
