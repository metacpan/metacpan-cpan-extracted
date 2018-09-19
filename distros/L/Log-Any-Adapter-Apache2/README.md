[![Build Status](https://travis-ci.org/ivanych/Log-Any-Adapter-Apache2.svg?branch=master)](https://travis-ci.org/ivanych/Log-Any-Adapter-Apache2) [![MetaCPAN Release](https://badge.fury.io/pl/Log-Any-Adapter-Apache2.svg)](https://metacpan.org/release/Log-Any-Adapter-Apache2)
# NAME

Log::Any::Adapter::Apache2 - Log::Any adapter for Apache2::Log

# SYNOPSIS

    use Log::Any::Adapter ('Apache2');

    or

    use Log::Any::Adapter;
    Log::Any::Adapter->set('Apache2');

# DESCRIPTION

This Log::Any adapter uses Apache2::Log for logging. There are no parameters. The logging level is specified in the Apache configuration file.

# LOG LEVEL TRANSLATION

Log levels are translated from Log::Any to Apache2::Log as follows:

    trace -> debug;
    warning -> warn;
    critical ->crit;
    emergency -> emerg;

# SEE ALSO

- [Log::Any](https://metacpan.org/pod/Log::Any)
- [Log::Any::Adapter](https://metacpan.org/pod/Log::Any::Adapter)
- [Apache2::Log](https://metacpan.org/pod/Apache2::Log)

# LICENSE

Copyright (C) Mikhail Ivanov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Mikhail Ivanov <m.ivanych@gmail.com>
