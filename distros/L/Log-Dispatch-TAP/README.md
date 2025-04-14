# NAME

Log::Dispatch::TAP - Log to TAP output

# VERSION

version v0.2.2

# SYNOPSIS

```perl
use Log::Dispatch;

my $logger = Log::Dispatch->new(
  outputs => [
    [
       'TAP',
       method    => 'note',
       min_level => 'debug',
  ]
);
```

# DESCRIPTION

This module provides a [Log::Dispatch](https://metacpan.org/pod/Log%3A%3ADispatch) output sink for logging to
[Test::Simple](https://metacpan.org/pod/Test%3A%3ASimple) diagnostics.

It is similar to [Log::Dispatch::TestDiag](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3ATestDiag).

# CONSTRUCTOR

The constructor takes the following parameter in addition to the
standard parameters for [Log::Dispatch::Output](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3AOutput).

## method

This is the logging method, which is either `note` or `diag`
(corresponding to those functions in [Test::More](https://metacpan.org/pod/Test%3A%3AMore)).

# SUPPORT FOR OLDER PERL VERSIONS

Since v0.2.0, the this module requires Perl v5.14 or later.

Future releases may only support Perl versions released in the last ten years.

# SEE ALSO

[Log::Log4perl::Appender::TAP](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3AAppender%3A%3ATAP)

[Log::Dispatch::TestDiag](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3ATestDiag)

# SOURCE

The development version is on github at [https://github.com/robrwo/Log-Dispatch-TAP](https://github.com/robrwo/Log-Dispatch-TAP)
and may be cloned from [git://github.com/robrwo/Log-Dispatch-TAP.git](git://github.com/robrwo/Log-Dispatch-TAP.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Log-Dispatch-TAP/issues](https://github.com/robrwo/Log-Dispatch-TAP/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

## Reporting Security Vulnerabilities

Security issues should not be reported on the bugtracker website. Please see `SECURITY.md` for instructions how to
report security vulnerabilities

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some of the code was adapted from [Log::Log4perl::Appender::TAP](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3AAppender%3A%3ATAP)
and [Log::Dispatch::TestDiag](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3ATestDiag).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2025 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
