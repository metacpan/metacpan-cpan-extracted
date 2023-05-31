# NAME

Exporter::Handy - An EXPERIMENTAL subclass of <Exporter::Extensible>, which helps create easy-to-extend modules that export symbols

# VERSION

version 1.000004

# SYNOPSIS

Define a module with exports

    package My::Utils;
    use Exporter::Handy -exporter_setup => 1;

    export(qw( foo $x @STUFF -strict_and_warnings ), ':baz' => ['foo'] );

    sub foo { ... }

    sub strict_and_warnings {
      strict->import;
      warnings->import;
    }

Create a new module which exports all that, and more

    package My::MoreUtils;
    use My::Utils -exporter_setup => 1;
    sub util_fn3 : Export(:baz) { ... }

Use the module

    use My::MoreUtils qw( -strict_and_warnings :baz @STUFF );
    # Use the exported things
    push @STUFF, foo(), util_fn3();

# DESCRIPTION

This module is currently EXPERIMENTAL. You are advised to restrain from using it.

You have been warned.

# FUNCTIONS

## xtags

Build one or more **export tags** suitable for [Exporter::Handy](https://metacpan.org/pod/Exporter%3A%3AHandy), [Exporter::Extensible](https://metacpan.org/pod/Exporter%3A%3AExtensible) and co.

    use Exporter::Handy -exporter_setup => 1, xtags;

    export(
        foo
        baz
        xtags(
          bar => [qw( $bozo @baza boom )],
        ),
    );

# OPTIONS

## strict, warnings, feature, utf8

The below statement:

    use Exporter::Handy -strict;

is equivalent to:
    use Exporter::Handy;
    use strict;

Same thing for "feature", "warnings", "utf8";

## strictures

The below statement:

    use Exporter::Handy -strictures;

is equivalent to:
    use Exporter::Handy;
    use strict;
    use warnings;

## sane

The below statement:

    use Exporter::Handy -sane;

is equivalent to:
    use Exporter::Handy;
    use strict;
    use warnings;

## features

The below statement:

    use Exporter::Handy -features;

is equivalent to:
    use Exporter::Handy;
    use feature (
      'current\_sub',      # Perl v5.16+ (2012) : enable \_\_SUB\_\_ token that returns a ref to the current subroutine (or undef).
      'evalbytes',        # Perl v5.16+ (2012) : like string eval, but it treats its argument as a byte string.
      'fc',               # Perl v5.16+ (2012) : enable the fc function (Unicode casefolding).
      'lexical\_subs',     # Perl v5.18+ (2012) : enable declaration of subroutines via my sub foo, state sub foo and our sub foo syntax.
      'say',              # Perl v5.10+ (2007) : enable the Raku-inspired "say" function.
      'state',            # Perl v5.10+ (2007) : enable state variables.
      'unicode\_eval',     # Perl v5.16+ (2012) : changes the behavior of plain string eval to work more consistently, especially in the Unicode world.
      'unicode\_strings',  # Perl v5.12+ (2010) : use Unicode rules in all string operations (unless either use locale or use bytes are also within the scope).
    );

whereas the below statement:

    use Exporter::Handy -features => [qw(say)];

is equivalent to:

    use Exporter::Handy;
    use feature (
      'say',              # Perl v5.10+ (2007) : enable the Raku-inspired "say" function.
    );

# AUTHORS

Tabulo\[n\] <dev@tabulo.net>

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/tabulon-perl/p5-Exporter-Handy/issues](https://github.com/tabulon-perl/p5-Exporter-Handy/issues).

## Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/tabulon-perl/p5-Exporter-Handy](https://github.com/tabulon-perl/p5-Exporter-Handy)

    git clone https://github.com/tabulon-perl/p5-Exporter-Handy.git

# CONTRIBUTOR

Tabulo <dev-git.perl@tabulo.net>

# LEGAL

This software is copyright (c) 2023 by Tabulo\[n\].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
