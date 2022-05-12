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
([ES2020](https://tc39.github.io/ecma262/) specification) directly in your
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

$JS\_CODE is a _character_ string.

## _OBJ_->eval\_module( $JS\_CODE )

Runs $JS\_CODE as a module, which enables ES6 module syntax.
Note that no values can be returned directly in this mode of execution.

## $obj = _OBJ_->set\_module\_base( $PATH )

Sets a base path (a byte string) for ES6 module imports.

## $obj = _OBJ_->unset\_module\_base()

Restores QuickJS’s default directory for ES6 module imports
(as of this writing, it’s the process’s current directory).

# TYPE CONVERSION: JAVASCRIPT → PERL

This module converts returned values from JavaScript thus:

- JS string primitives become _character_ strings in Perl.
- JS number & boolean primitives become corresponding Perl values.
- JS null & undefined become Perl undef.
- JS objects …
    - Arrays become Perl array references.
    - “Plain” objects become Perl hash references.
    - Functions become Perl code references.
    - RegExp objects become Perl [JavaScript::QuickJS::RegExp](https://metacpan.org/pod/JavaScript%3A%3AQuickJS%3A%3ARegExp) objects.
    - Behaviour is **UNDEFINED** for other object types.

# TYPE CONVERSION: PERL → JAVASCRIPT

Generally speaking, it’s the inverse of JS → Perl:

- Perl strings, numbers, & booleans become corresponding JavaScript
primitives.

    **IMPORTANT:** Perl versions before 5.36 don’t reliably distinguish “numeric
    strings” from “numbers”. If your perl predates 5.36, typecast accordingly
    to prevent your Perl “number” from becoming a JavaScript string. (Even in
    5.36 and later it’s still a good idea.)

- Perl undef becomes JS null.
- Unblessed array & hash references become JavaScript arrays and
“plain” objects.
- [Types::Serialiser](https://metacpan.org/pod/Types%3A%3ASerialiser) booleans become JavaScript booleans.
- Perl code references become JavaScript functions.
- [JavaScript::QuickJS::RegExp](https://metacpan.org/pod/JavaScript%3A%3AQuickJS%3A%3ARegExp) objects become their original
JavaScript `RegExp` objects.
- Anything else triggers an exception.

# MEMORY HANDLING NOTES

If any instance of a class of this distribution is DESTROY()ed at Perl’s
global destruction, we assume that this is a memory leak, and a warning is
thrown. To prevent this, avoid circular references.

Callbacks make that tricky. As noted above, JavaScript functions
given to Perl become Perl code references. Those code references are
closures around the QuickJS context & runtime; once the code reference
is destroyed, we release its reference to QuickJS.

Perl code references given to JavaScript become JavaScript functions;
however, QuickJS exposes no facility analogous to Perl `DESTROY()`. Thus,
we retain those Perl code references as part of the QuickJS context.

Consider the following:

    my $return;

    $js->set_globals(  __return => sub { $return = shift; () } );

    $js->eval('__return( a => a )');

Here $js retains a reference to the `__return` callback. That callback
refers to `$return`. Once we run `eval()`, Perl $return stores
_another_ callback, which stores a reference to $js. Here we have a
circular reference. The way to break it is simply:

    undef $return;

… which is ugly, but it is what it is for now.

Note also that the `__return` callback ends with `()`. Recall that, in
Perl, a function’s last statement value is the function’s default return
value. Without the `()`, then, our callback would return `$return`,
which would create yet _another_ reference cycle.

# CHARACTER ENCODING NOTES

Although QuickJS (like all JS engines) assumes its strings are text,
you can oftentimes pass in byte strings and get a reasonable result.

One place where this falls over, though, is ES6 modules. QuickJS, when
it loads an ES6 module, decodes that module’s string literals to characters.
Thus, if you pass in byte strings from Perl, QuickJS will treat your
Perl byte strings’ code points as character code points, and when you
combine those code points with the ones from your ES6 module you may
get mangled output.

Another place that may create trouble is if your argument to `eval()`
or `eval_module()` (above) contains JSON. Perl’s popular JSON encoders
output byte strings by default, but as noted above, `eval()` and
`eval_module()` need _character_ strings. So either configure your
JSON encoder to output characters, or decode JSON bytes to characters
before calling `eval()`/`eval_module()`.

For best results, _always_ interact with QuickJS via _character_
strings, and double-check that you’re doing it that way consistently.

# NUMERIC PRECISION

Note the following if you expect to deal with “large” numbers:

- JavaScript’s numeric-precision limits apply. (cf.
[Number.MAX\_SAFE\_INTEGER](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER).)
- Perl’s stringification of numbers may be _less_ precise than
JavaScript’s storage of those numbers, or even than Perl’s own storage.
For example, in Perl 5.34 `print 1000000000000001.0` prints `1e+15`.

    To counteract this loss of precision, add 0 to Perl’s numeric scalars
    (e.g., `print 0 + 1000000000000001.0`); this will encourage Perl to store
    numbers as integers when possible, which fixes the precision problem.

- Long-double and quad-math perls may lose precision when converting
numbers to/from JavaScript. To see if this affects your perl—which, if
you’re unsure, it probably doesn’t—run `perl -V`, and see if the
compile-time options mention long doubles or quad math.

# OS SUPPORT

QuickJS supports Linux & macOS natively, so these work without issue.

FreeBSD, OpenBSD, & Cygwin work after a few patches that we apply when
building this library. (Hopefully these will eventually merge into QuickJS.)

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
See [perlartistic](https://metacpan.org/pod/perlartistic).
