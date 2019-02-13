[![Build Status](https://travis-ci.org/kfly8/p5-Function-Return.svg?branch=master)](https://travis-ci.org/kfly8/p5-Function-Return) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Function-Return/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Function-Return?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Function-Return.svg)](https://metacpan.org/release/Function-Return)
# NAME

Function::Return - specify a function return type

# SYNOPSIS

```perl
use Function::Return;
use Types::Standard -types;

sub foo :Return(Int) { 123 }
sub bar :Return(Int) { 3.14 }

foo(); # 123
bar(); # ERROR! Invalid type

# multi return values
sub baz :Return(Num, Str) { 3.14, 'message' }
my ($pi, $msg) = baz();
my $count = baz(); # ERROR! Required list context.

# empty return
sub boo :Return() { return; }
boo();
```

# DESCRIPTION

Function::Return allows you to specify a return type for your functions.

## SUPPORT

This module supports all perl versions starting from v5.14.

## IMPORT OPTIONS

### name

you can change `Return` to your own name:

```perl
use Function::Return name => 'MyReturn';

sub foo :MyReturn(Str) { }
```

### no\_check

you can switch off type check:

```perl
use Function::Return no_check => 1;

sub foo :Return(Int) { 3.14 }
foo(); # NO ERROR!
```

## METHODS

### Function::Return::info($coderef)

The function `Function::Return::info` lets you introspect return values like [Function::Parameters::Info](https://metacpan.org/pod/Function::Parameters::Info):

```perl
use Function::Return;

sub baz() :Return(Str) { 'hello' }

my $rinfo = Function::Return::info \&baz;

$rinfo->types; # [Str]
$rinfo->isa('Function::Return::Info');
```

In addition, it can be used with [Function::Parameters](https://metacpan.org/pod/Function::Parameters):

```perl
use Function::Parameters;
use Function::Return;

fun baz() :Return(Str) { 'hello' }

my $pinfo = Function::Parameters::info \&baz;
my $rinfo = Function::Return::info \&baz;
```

This makes it possible to know both type information of function arguments and return value at compile time, making it easier to use for testing etc.

### Function::Return->wrap\_sub($coderef)

This interface is for power-user. Rather than using the `:Return` attribute, it's possible to wrap a coderef like this:

```perl
my $wrapped = Function::Return->wrap_sub($orig, [Str]);
$wrapped->();
```

# NOTE

## enforce LIST to simplify

`Function::Return` makes the original function is called in list context whether the wrapped function is called in list, scalar, void context:

```perl
sub foo :Return(Str) { wantarray ? 'LIST!!' : 'NON!!' }
my $a = foo(); # => LIST!!
```

The specified type checks against the value the original function was called in the list context.

`wantarray` is convenient, but it sometimes causes confusion. So, in this module, we prioritized that the expected type of function return value becomes easy to understand.

## requirements of type constraint

The requirements of type constraint of `Function::Return` is the same as for `Function::Parameters`. Specific requirements are as follows:

\> The only requirement is that the returned value (here referred to as $tc, for "type constraint") is an object that provides $tc->check($value) and $tc->get\_message($value) methods. check is called to determine whether a particular value is valid; it should return a true or false value. get\_message is called on values that fail the check test; it should return a string that describes the error.

## compare Return::Type

Both `Return::Type` and `Function::Return` perform type checking on the return value of the function, but there are some differences.

1\. `Function::Return` is not possible to specify different type constraints for scalar and list context.

2\. `Function::Return` check type constraint for void context.

3\. `Function::Return::info` and `Function::Parameters::info` can be used together.

# SEE ALSO

[Function::Parameters](https://metacpan.org/pod/Function::Parameters), [Return::Type](https://metacpan.org/pod/Return::Type)

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
