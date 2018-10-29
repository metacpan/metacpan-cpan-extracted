[![Build Status](https://travis-ci.org/kfly8/p5-Function-Return.svg?branch=master)](https://travis-ci.org/kfly8/p5-Function-Return) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Function-Return/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Function-Return?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Function-Return.svg)](https://metacpan.org/release/Function-Return)
# NAME

Function::Return - add return type for a function

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

## IMPORT OPTIONS

### name

you can change \`Return\` to your own name:

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

## INTROSPECTION

The function Function::Return::info lets you introspect return values like [Function::Parameters::Info](https://metacpan.org/pod/Function::Parameters::Info):

```perl
use Function::Parameters;
use Function::Return;

fun baz() :Return(Str) { 'hello' }

my $pinfo = Function::Parameters::info \&baz;
my $rinfo = Function::Return::info \&baz;

$rinfo->types; # [Str]
```

# SUPPORT

This module supports all perl versions starting from v5.14.

# NOTE

## COMPARE Return::Type

It is NOT possible to specify different type constraints for scalar and list context.

Check type constraint for void context.

Function::Return::info and Function::Parameters::info can be used together.

# SEE ALSO

[Function::Parameters](https://metacpan.org/pod/Function::Parameters)
[Return::Type](https://metacpan.org/pod/Return::Type)

# LICENSE

Copyright (C) Kenta, Kobayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kenta, Kobayashi <kentafly88@gmail.com>
