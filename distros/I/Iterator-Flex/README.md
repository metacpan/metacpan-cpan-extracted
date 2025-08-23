# NAME

Iterator::Flex - Iterators with flexible behaviors

# VERSION

version 0.26

# SYNOPSIS

# DESCRIPTION

Note! **`Iterator::Flex` is alpha quality software.**

## What is It?

`Iterator::Flex` provides iterators that can:

- rewind to the beginning, keeping track of state (e.g. cycles which
always know the previous value).
- reset to the initial state
- serialize, so that you can restart from where you left off,
- signal exhaustion by returning a sentinel value (e.g. `undef`) or throwing
an exception, and provide a test for exhaustion via the `is_exhausted` method.
- wrap existing iterators so that they have the same exhaustion interface
as your own iterators
- provide history via `prev` and `current` methods.

These are _optional_ things behaviors that an iterator can support.  Not all
iterators need the bells and whistles, but sometimes they are very handy.

## Where are the iterators?

See [Iterator::Flex::Common](https://metacpan.org/pod/Iterator%3A%3AFlex%3A%3ACommon) for a set of common iterators.  These
are pre-made for you.  See [Iterator::Flex::Manual::Using](https://metacpan.org/pod/Iterator%3A%3AFlex%3A%3AManual%3A%3AUsing) for how to
use them.

## I need to write my own.

See [Iterator::Flex::Manual::Authoring](https://metacpan.org/pod/Iterator%3A%3AFlex%3A%3AManual%3A%3AAuthoring) for how to write your own
flexible iterators.

See [Iterator::Flex::Manual::Internals](https://metacpan.org/pod/Iterator%3A%3AFlex%3A%3AManual%3A%3AInternals) for how everything links
together.

## Show me the Manual

[Iterator::Flex::Manual](https://metacpan.org/pod/Iterator%3A%3AFlex%3A%3AManual)

## What doesn't work?  What should frighten me away?

[Iterator::Flex::Manual::Caveats](https://metacpan.org/pod/Iterator%3A%3AFlex%3A%3AManual%3A%3ACaveats)

# INTERNALS

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-iterator-flex@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex](https://rt.cpan.org/Public/Dist/Display.html?Name=Iterator-Flex)

## Source

Source is available at

    https://gitlab.com/djerius/iterator-flex

and may be cloned from

    https://gitlab.com/djerius/iterator-flex.git

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
