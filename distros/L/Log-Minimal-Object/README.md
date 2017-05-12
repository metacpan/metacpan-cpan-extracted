[![Build Status](https://travis-ci.org/moznion/Log-Minimal-Object.png?branch=master)](https://travis-ci.org/moznion/Log-Minimal-Object) [![Coverage Status](https://coveralls.io/repos/moznion/Log-Minimal-Object/badge.png?branch=master)](https://coveralls.io/r/moznion/Log-Minimal-Object?branch=master)
# NAME

Log::Minimal::Object - Provides the OOP interface of Log::Minimal

# SYNOPSIS

    use Log::Minimal::Object;

    my $logger = Log::Minimal::Object->new();
    $logger->infof("This is info!"); # => 2014-05-18T17:24:02 [INFO] This is info! at eg/sample.pl line 13
    $logger->warnf("This is warn!"); # => 2014-05-18T17:24:02 [WARN] This is warn! at eg/sample.pl line 14

# DESCRIPTION

Log::Minimal::Object is the simple wrapper to provide the OOP interface of [Log::Minimal](https://metacpan.org/pod/Log::Minimal).

This module can have and apply independent customize settings for each instance, it's intuitive!

# CLASS METHODS

- Log::Minimal::Object->new(%arg | \\%arg)

    Creates the instance. This method receives arguments to configure as hash or hashref, like so;

        my $logger = Log::Minimal::Object->new(
            color     => 1,
            log_level => 'WARN',
        );

    Please refer to the ["CONFIGURATIONS"](#configurations) to know details of configurable items.

# INSTANCE METHODS

Instance of this module provides the methods that are defined in the ["EXPORT FUNCTIONS" in Log::Minimal](https://metacpan.org/pod/Log::Minimal#EXPORT-FUNCTIONS) (e.g. infof, warnf, and etc).

# CONFIGURATIONS

The configurable keys and its relations are follows (please see also ["CUSTOMIZE" in Log::Minimal](https://metacpan.org/pod/Log::Minimal#CUSTOMIZE) to get information of `$Log::Minimal::*`):

- color

    `$Log::Minimal::COLOR` (default: 0)

- autodump

    `$Log::Minimal::AUTODUMP` (default: 0)

- trace\_level

    `$Log::Minimal::TRACE_LEVEL` (default: 2, this value is equal to `Log::Minimal::Object::DEFAULT_TRACE_LEVEL`)

- log\_level

    `$Log::Minimal::LOG_LEVEL` (default: 'DEBUG')

- escape\_whitespace

    `$Log::Minimal::ESCAPE_WHITESPACE` (default: 0)

- print

    `$Log::Minimal::PRINT`

- die

    `$Log::Minimal::DIE`

# PROVIDED CONSTANTS

- Log::Minimal::Object::DEFAULT\_TRACE\_LEVEL

    Default `trace_level` of this module.
    When you would like to control the trace level on the basis of this module, please use this value.

    For example: `$logger->{trace_level} = Log::Minimal::Object::DEFAULT_TRACE_LEVEL + 1`

# SEE ALSO

[Log::Minimal](https://metacpan.org/pod/Log::Minimal)

# LICENSE

Copyright (C) moznion.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

moznion <moznion@gmail.com>
