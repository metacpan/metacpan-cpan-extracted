[![Build Status](https://travis-ci.org/kfly8/p5-Function-Interface.svg?branch=master)](https://travis-ci.org/kfly8/p5-Function-Interface) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Function-Interface/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Function-Interface?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Function-Interface.svg)](https://metacpan.org/release/Function-Interface)
# NAME

Function::Interface - declare typed interface package

# SYNOPSIS

Declare typed interface package `IFoo`:

```perl
package IFoo {
    use Function::Interface;
    use Types::Standard -types;

    fun hello(Str $msg) :Return(Str);

    fun add(Int $a, Int $b) :Return(Int);
}
```

Implements the interface package `IFoo`:

```perl
package Foo {
    use Function::Interface::Impl qw(IFoo);
    use Types::Standard -types;

    fun hello(Str $msg) :Return(Str) {
        return "HELLO $msg";
    }

    fun add(Int $a, Int $b) :Return(Int) {
        return $a + $b;
    }
}
```

Use the type `ImplOf`:

```perl
package FooService {
    use Function::Interface::Types qw(ImplOf);
    use Function::Parameters;
    use Function::Return;
    use Mouse;

    use aliased 'IFoo';

    fun greet(ImplOf[IFoo] $foo) :Return() {
        print $foo->hello;
        return;
    }
}

my $foo_service = FooService->new;
my $foo = Foo->new; # implements of IFoo

$foo_service->greet($foo);
```

# DESCRIPTION

This module provides a typed interface.
`Function::Interface` declares abstract functions without implementation and defines an interface package.
`Function::Interface::Impl` checks if the abstract functions are implemented at **compile time**.

## SUPPORT

This module supports all perl versions starting from v5.14.

## Declare function

`Function::Interface` provides two new keywords, `fun` and `method`, for declaring abstract functions and methods with types:

```
fun hello(Str $msg) :Return(Str);

method new(Num :$x, Num :$y) :Return(Point);
```

The method of declaring abstract functions is the same as [Function::Parameters](https://metacpan.org/pod/Function::Parameters) and [Function::Return](https://metacpan.org/pod/Function::Return).

### declare parameters

Function arguments must always specify a variable name and type constraint, and named arguments and optional arguments can optionally be specified:

```perl
# positional parameters
# e.g. called `foo(1,2,3)`
fun foo1(Int $a, Int $b, Int $c) :Return();

# named parameters
# e.g. called `bar(x => 123, y => 456)`
fun foo2(Num :$x, Num :$y) :Return();

# optional
# e.g. called `baz()` or `baz('some')`
fun foo3(Str $msg=) :Return();
```

### declare return types

Specify zero or more type constraints for the function's return value:

```
# zero(empty)
fun bar1() :Return();

# one
fun bar2() :Return(Str);

# two
fun bar3() :Return(Str, Num);
```

## requirements of type constraint

The requirements of type constraint of `Function::Interface` is the same as for [Function::Parameters](https://metacpan.org/pod/Function::Parameters) and [Function::Return](https://metacpan.org/pod/Function::Return).

# METHODS

## Function::Interface::info($interface\_package)

The function `Function::Interface::info` lets you introspect interface functions:

```perl
# declare interface package
package IBar {
    use Function::Interface;
    fun hello() :Return();
    fun world() :Return();
}

# introspect
my $info = Function::Interface::info 'IBar';
$info->package; # => IBar
$info->functions; # => list of Function::Interface::Info::Function
```

It returns either `undef` if it knows nothing about the interface or an object of [Function::Interface::Info](https://metacpan.org/pod/Function::Interface::Info).

# SEE ALSO

[Function::Interface::Impl](https://metacpan.org/pod/Function::Interface::Impl)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
