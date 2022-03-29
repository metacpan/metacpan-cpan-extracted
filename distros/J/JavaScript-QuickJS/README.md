# NAME

JavaScript::QuickJS - Run JavaScript via [QuickJS](https://bellard.org/quickjs) in Perl

# SYNOPSIS

Quick and dirty …

    my $val = JavaScript::QuickJS->new()->eval( q<
        let foo = "bar";
        [ "The", "last", "value", "is", "returned." ];
    > );

# DESCRIPTION

This library embeds Fabrice Bellard’s [QuickJS](https://bellard.org/quickjs)
engine into a Perl XS module. You can thus run JavaScript
([ES2020](https://tc39.github.io/ecma262/)) specification) directly in your
Perl programs.

This distribution includes all needed C code; unlike with most XS modules
that interface with C libraries, you don’t need QuickJS pre-installed on
your system.

# METHODS

## $obj = _CLASS_->new()

Instantiates _CLASS_.

## $obj = _OBJ_->set\_globals( NAME1 => VALUE1, .. )

Sets 1 or more globals in _OBJ_. See below for details on type conversions
from Perl to JavaScript.

## $obj = _OBJ_->helpers()

Defines QuickJS’s “helpers”, e.g., `console.log`.

## $obj = _OBJ_->std()

Enables (but does _not_ import) QuickJS’s `std` module.

## $obj = _OBJ_->os()

Like `std()` but for QuickJS’s `os` module.

## $VALUE = _OBJ_->eval( $JS\_CODE )

Comparable to running `qjs -e '...'`. Returns the last value from $JS\_CODE;
see below for details on type conversions from JavaScript to Perl.

Untrapped exceptions in JavaScript will be rethrown as Perl exceptions.

## _OBJ_->eval\_module( $JS\_CODE )

Runs $JS\_CODE as a module, which enables ES6 module syntax.
Note that no values can be returned directly in this mode of execution.

# TYPE CONVERSION: JAVASCRIPT → PERL

This module converts returned values from JavaScript thus:

- JS string primitives become _character_ strings in Perl.
- JS number & boolean primitives become corresponding Perl values.
- JS null & undefined become Perl undef.
- JS objects …
    - Arrays become Perl array references.
    - “Plain” objects become Perl hash references.
    - Functions become Perl code references.
    - Behaviour is **UNDEFINED** for other object types.

# TYPE CONVERSION: PERL → JAVASCRIPT

Generally speaking, it’s the inverse of JS → Perl, though since Perl doesn’t
differentiate “numeric strings” from “numbers” there’s occasional ambiguity.
In such cases, behavior is undefined; be sure to typecast in JavaScript
accordingly.

- Perl strings, numbers, & booleans become corresponding JavaScript
primitives.
- Perl undef becomes JS null.
- Unblessed array & hash references become JavaScript arrays and
“plain” objects.
- Perl code references become JavaScript functions.
- Anything else triggers an exception.

# PLATFORM NOTES

Due to QuickJS limitations, Linux & macOS are the only platforms known
to work “out-of-the-box”. Other POSIX OSes _should_ work with some small
tweaks to quickjs; see the compiler errors and `quickjs.c` for more
details.

Pull requests to improve portability are welcome!

# SEE ALSO

Other JavaScript modules on CPAN include:

- [JavaScript::Duktape::XS](https://metacpan.org/pod/JavaScript%3A%3ADuktape%3A%3AXS) and [JavaScript::Duktape](https://metacpan.org/pod/JavaScript%3A%3ADuktape) make the
[Duktape](https://duktape.org) library available to Perl. They’re similar to
this library, but Duktape itself (as of this writing) lacks support for
several JavaScript constructs that QuickJS supports. (It’s also slower.)
- [JavaScript::V8](https://metacpan.org/pod/JavaScript%3A%3AV8) and [JavaScript::V8::XS](https://metacpan.org/pod/JavaScript%3A%3AV8%3A%3AXS) expose Google’s
[V8](https://v8.dev) library to Perl. Neither seems to support current
V8 versions.
- [JE](https://metacpan.org/pod/JE) is a pure-Perl (!) JavaScript engine.
- [JavaScript](https://metacpan.org/pod/JavaScript) and [JavaScript::Lite](https://metacpan.org/pod/JavaScript%3A%3ALite) expose Mozilla’s
[SpiderMonkey](https://spidermonkey.dev/) engine to Perl.

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.
