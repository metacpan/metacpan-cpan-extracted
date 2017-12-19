# NAME

Log::Any::Adapter::LinuxJournal - Log::Any adapter for the systemd journal on Linux

# VERSION

version 0.173471

# SYNOPSIS

```perl
use Log::Any::Adapter;
Log::Any::Adapter->set('LinuxJournal',
    # app_id => 'myscript', # default is basename($0)
);
```

# DESCRIPTION

**WARNING** This is a [Log::Any](https://metacpan.org/pod/Log::Any) adpater for _structured_ logging, which means it
is only useful with a very recent version of [Log::Any](https://metacpan.org/pod/Log::Any), at least `1.700`

It will log messages to the systemd journal via [Linux::Systemd::Journal::Write](https://metacpan.org/pod/Linux::Systemd::Journal::Write).

# SEE ALSO

[Log::Any::Adapter::Journal](https://metacpan.org/pod/Log::Any::Adapter::Journal)

# SUPPORT

## Perldoc

You can find documentation for this module with the perldoc command.

```
perldoc Log::Any::Adapter::LinuxJournal
```

## Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

- MetaCPAN

    A modern, open-source CPAN search engine, useful to view POD in HTML format.

    [https://metacpan.org/release/Log-Any-Adapter-LinuxJournal](https://metacpan.org/release/Log-Any-Adapter-LinuxJournal)

## Bugs / Feature Requests

Please report any bugs or feature requests through the web interface at [https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal/issues](https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal/issues).
You will be automatically notified of any progress on the request by the system.

## Source Code

The source code is available for from the following locations:

[https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal](https://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal)

```
git clone git://github.com/ioanrogers/Log-Any-Adapter-LinuxJournal.git
```

# AUTHOR

Ioan Rogers <ioanr@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ioan Rogers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
