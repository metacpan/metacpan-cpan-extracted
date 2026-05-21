# NAME

Log::Dispatch::UDP - Log messages to a remote UDP socket

# SYNOPSIS

```perl
use Log::Dispatch;

my $log = Log::Dispatch->new(
  outputs => [
      [
          'UDP'
          host      => $destination_host,
          port      => $destination_port,
          min_level => 'info',
      ],
  ],
);

$log->info('my message');
```

# DESCRIPTION

This class can be used to write messages to a UDP socket
listening on some remote host.  The datagrams themselves
contain only the messages (there's no real structure to them),
so you can easily listen in using netcat.

# RECENT CHANGES

Changes for version 0.02 (2026-05-21)

- Documentation
    - New maintainer is Robert Rothenberg <perl@rhizomnic.com>
    - Updated copyright year
    - Reformatted Changes to follow the Changes spec
    - Added a security policy
    - Added a SECURITY CONSIDERATIONS section
    - Added doap.xml metadata
- Bug Fixes
    - Remove unused code
- Security
    - Increases the minimum versions of some prerequisites
- Tests
    - Added author tests.
- Toolchain
    - Changes to the Dist::Zilla configuration

See the `Changes` file for more details.

# REQUIREMENTS

This module lists the following modules as runtime dependencies:

- [Carp](https://metacpan.org/pod/Carp)
- [IO::Socket::INET](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AINET)
- [Log::Dispatch::Output](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3AOutput)
- [Socket](https://metacpan.org/pod/Socket) version 2.026 or later
- [namespace::clean](https://metacpan.org/pod/namespace%3A%3Aclean)
- [parent](https://metacpan.org/pod/parent)
- [perl](https://metacpan.org/pod/perl) version v5.8.0 or later
- [strict](https://metacpan.org/pod/strict)
- [warnings](https://metacpan.org/pod/warnings)

See the `cpanfile` file for the full list of prerequisites.

# INSTALLATION

The latest version of this module (along with any dependencies) can be installed from [CPAN](https://www.cpan.org) with the `cpan` tool that is included with Perl:

```
cpan Log::Dispatch::UDP
```

You can also extract the distribution archive and install this module (along with any dependencies):

```
cpan .
```

You can also install this module manually using the following commands:

```
perl Makefile.PL
make
make test
make install
```

If you are working with the source repository, then it may not have a `Makefile.PL` file.  But you can use the [Dist::Zilla](https://dzil.org/) tool in anger to build and install this module:

```
dzil build
dzil test
dzil install --install-command="cpan ."
```

For more information, see [How to install CPAN modules](https://www.cpan.org/modules/INSTALL.html).

# SECURITY CONSIDERATIONS

Log messages are not encrypted.  Be wary of logging authentication
details such as usernames, passwords or session ids, financial
information such as credit cards, or other personally identifying
information over unsecured channels.

# SUPPORT

Only the latest version of this module will be supported.

This module requires Perl v5.8 or later.
Future releases may only support Perl versions released in the last ten (10) years.

## Reporting Bugs and Submitting Feature Requests

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl-Log-Dispatch-UDP/issues](https://github.com/robrwo/perl-Log-Dispatch-UDP/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

If the bug you are reporting has security implications which make it inappropriate to send to a public issue tracker,
then see `SECURITY.md` for instructions how to report security vulnerabilities.

# SOURCE

The development version is on github at [https://github.com/robrwo/perl-Log-Dispatch-UDP](https://github.com/robrwo/perl-Log-Dispatch-UDP)
and may be cloned from [https://github.com/robrwo/perl-Log-Dispatch-UDP.git](https://github.com/robrwo/perl-Log-Dispatch-UDP.git)

# AUTHOR

Rob Hoelz <rob@hoelz.ro>

This module is currently maintained by Robert Rothenberg <perl@rhizomnic.com>.

# CONTRIBUTOR

Robert Rothenberg <perl@rhizomnic.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012, 2026 by Rob Hoelz <rob@hoelz.ro>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# SEE ALSO

[Log::Dispatch](https://metacpan.org/pod/Log%3A%3ADispatch)
