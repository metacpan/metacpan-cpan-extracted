### NAME

Lox - A Perl implementation of the Lox programming language

### DESCRIPTION

A Perl translation of the Java Lox interpreter from
[Crafting Interpreters](https://craftinginterpreters.com/).

### INSTALL

As long as you have Perl 5.24.0 or greater, you should be able to run `plox`
from the root project directory.

If you'd rather build and install it:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

### SYNOPSIS

If you have built and installed `plox`:

    $ plox
    Welcome to Perl-Lox version 0.02
    >

    $ plox hello.lox
    Hello, World!

Otherwise from the root project directory:

    $ perl -Ilib bin/plox
    Welcome to Perl-Lox version 0.02
    >

    $ perl -Ilib bin/plox hello.lox
    Hello, World!

Pass the `--debug` or `-d` option to `plox` to print the tokens it scanned
and the parse tree.

### TESTING

The test suite includes 238 test files from the Crafting Interpreters
[repo](https://github.com/munificent/craftinginterpreters).

    $ prove -l t/*

### EXTENSIONS

Perl-Lox has these capabilities from the "challenges" sections of the book:

- Anonymous functions `fun () { ... }`
- Break statements in loops
- Multi-line comments `/* ... */`
- New Exceptions:
    - Evaluating an uninitialized variable

### DIFFERENCES

Differences from the canonical "jlox" implementation:

- repl is stateful
- signed zero is unsupported
- methods are equivalent

    Prints "true" in plox and "false" in jlox:

        class Foo  { bar () { } } print Foo().bar == Foo().bar;

### AUTHOR

Copyright 2020 David Farrell

### LICENSE

See `LICENSE` file.
