# NAME

Exporter::Auto - export all public functions from your package

# SYNOPSIS

    package Foo;
    use Exporter::Auto;

    sub foo { }

    package main;
    use Foo;
    foo();  # <= this function was exported!

# DESCRIPTION

Exporter::Auto is a simple replacement for [Exporter](https://metacpan.org/pod/Exporter) that will export
all public functions from your package. If you want all functions to be
exported from your module by default, then this might be the module for you.
If you only want some functions exported, or want tags, or to export variables,
then you should look at one of the other Exporter modules (["SEE ALSO"](#see-also)).

Let's say you have a library module with three functions, all of which
you want to export by default. With [Exporter](https://metacpan.org/pod/Exporter), you'd write something like:

    package MyLibrary;
    use parent 'Exporter';
    our @EXPORT = qw/ foo bar baz /;
    sub foo { ... }
    sub bar { ... }
    sub baz { ... }
    1;

Every time you add a new function,
you must remember to add it to `@EXPORT`.
Not a big hassle, but a small inconvenience.

With `Exporter::Auto` you just write:

    package MyLibrary;
    use Exporter::Auto;
    sub foo { ... }
    sub bar { ... }
    sub baz { ... }
    1;

When you `use Exporter::Auto` it automatically adds an `import` function
to your package, so you don't need to declare your package as a subclass.

That's it. If you want anything more fancy than this,
it's time for another module.

# REPOSITORY

[https://github.com/tokuhirom/Exporter-Auto](https://github.com/tokuhirom/Exporter-Auto)

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# DEPENDENCIES

This module uses magical [B::Hooks::EndOfScope](https://metacpan.org/pod/B::Hooks::EndOfScope).
If you think this module is too clever, please try [Module::Functions](https://metacpan.org/pod/Module::Functions) instead.

# SEE ALSO

[Exporter](https://metacpan.org/pod/Exporter) is the grandaddy of all Exporter modules, and bundled with Perl
itself, unlike the rest of the modules listed here.

[Sub::Exporter](https://metacpan.org/pod/Sub::Exporter) is a "sophisticated exporter for custom-built routines";
it lets you provide generators that can be used to customise what
gets imported when someone uses your module.

[Exporter::Tiny](https://metacpan.org/pod/Exporter::Tiny) provides the same features as [Sub::Exporter](https://metacpan.org/pod/Sub::Exporter),
but relying only on core dependencies.

[Exporter::Declare](https://metacpan.org/pod/Exporter::Declare) provides Moose-style functions used to define
what your module exports in a declarative way.

[Exporter::Lite](https://metacpan.org/pod/Exporter::Lite) is a lightweight exporter module, falling somewhere
between `Exporter::Auto` and [Exporter](https://metacpan.org/pod/Exporter).

# LICENSE

Copyright (C) Tokuhiro Matsuno <TOKUHIROM @ GMAIL COM

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
