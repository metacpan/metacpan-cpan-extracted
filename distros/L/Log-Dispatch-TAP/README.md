# NAME

Log::Dispatch::TAP - Log to TAP output

# VERSION

version v0.1.0

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

This module provides a [Log::Dispatch](https://metacpan.org/pod/Log::Dispatch) output sink for logging to
[Test::Simple](https://metacpan.org/pod/Test::Simple) diagnostics.

It is similar to [Log::Dispatch::TestDiag](https://metacpan.org/pod/Log::Dispatch::TestDiag), except that it allows you
to choose the logging method.

# CONSTRUCTOR

The constructor takes the following parameter in addition to the
standard parameters for [Log::Dispatch::Output](https://metacpan.org/pod/Log::Dispatch::Output).

## method

This is the logging method, which is either `note` or `diag`
(corresponding to those functions in [Test::More](https://metacpan.org/pod/Test::More)).

# SEE ALSO

[Log::Log4perl::Appender::TAP](https://metacpan.org/pod/Log::Log4perl::Appender::TAP)

[Log::Dispatch::TestDiag](https://metacpan.org/pod/Log::Dispatch::TestDiag)

# SOURCE

The development version is on github at [https://github.com/robrwo/Log-Dispatch-TAP](https://github.com/robrwo/Log-Dispatch-TAP)
and may be cloned from [git://github.com/robrwo/Log-Dispatch-TAP.git](git://github.com/robrwo/Log-Dispatch-TAP.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Log-Dispatch-TAP/issues](https://github.com/robrwo/Log-Dispatch-TAP/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

Some of the code was adapted from [Log::Log4perl::Appender::TAP](https://metacpan.org/pod/Log::Log4perl::Appender::TAP)
and [Log::Dispatch::TestDiag](https://metacpan.org/pod/Log::Dispatch::TestDiag).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
