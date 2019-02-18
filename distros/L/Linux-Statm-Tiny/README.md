# NAME

Linux::Statm::Tiny - simple access to Linux /proc/../statm

# VERSION

version 0.0601

# SYNOPSIS

```perl
use Linux::Statm::Tiny;

my $stats = Linux::Statm::Tiny->new( pid => $$ );

my $size = $stats->size;
```

# DESCRIPTION

This class returns the Linux memory stats from `/proc/$pid/statm`.

# ATTRIBUTES

## `pid`

The PID to obtain stats for. If omitted, it uses the current PID from
`$$`.

## `page_size`

The page size.

## `statm`

The raw array reference of values.

## `size`

Total program size, in pages.

## `vsz`

An alias for ["size"](#size).

## `resident`

Resident set size (RSS), in pages.

## `rss`

An alias for ["resident"](#resident).

## `share`

Shared pages.

## `text`

Text (code).

## `lib`

Library (unused in Linux 2.6).

## `data`

Data + Stack.

## `dt`

Dirty pages (unused in Linux 2.6).

# ALIASES

You can append the "\_pages" suffix to attributes to make it explicit
that the return value is in pages, e.g. `vsz_pages`.

You can also use the "\_bytes", "\_kb" or "\_mb" suffixes to get the
values in bytes, kilobytes or megabytes, e.g. `size_bytes`, `size_kb`
and `size_mb`.

The fractional kilobyte and megabyte sizes will be rounded up, e.g.
if the ["size"](#size) is 1.04 MB, then `size_mb` will return "2".

# METHODS

## `refresh`

The values do not change dynamically. If you need to refresh the
values, then you you must either create a new instance of the object,
or use the `refresh` method:

```
$stats->refresh;
```

# SEE ALSO

[proc(5)](http://man.he.net/man5/proc).

# SOURCE

The development version is on github at [https://github.com/robrwo/Linux-Statm-Tiny](https://github.com/robrwo/Linux-Statm-Tiny)
and may be cloned from [git://github.com/robrwo/Linux-Statm-Tiny.git](git://github.com/robrwo/Linux-Statm-Tiny.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Linux-Statm-Tiny/issues](https://github.com/robrwo/Linux-Statm-Tiny/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# CONTRIBUTORS

- Adrian Lai <aidy@cpan.org>
- Karen Etheridge <ether@cpan.org>
- Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2019 by Thermeon Worldwide, PLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
