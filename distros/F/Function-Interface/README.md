[![Build Status](https://travis-ci.org/kfly8/p5-Function-Interface.svg?branch=master)](https://travis-ci.org/kfly8/p5-Function-Interface) [![Coverage Status](https://img.shields.io/coveralls/kfly8/p5-Function-Interface/master.svg?style=flat)](https://coveralls.io/r/kfly8/p5-Function-Interface?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Function-Interface.svg)](https://metacpan.org/release/Function-Interface)
# NAME

Function::Interface - specify type constraints of subroutines

# SYNOPSIS

```perl
package IFoo {
    use Function::Interface;
    use Types::Standard -types;

    fun hello(Str $msg) :Return(Str);
}
```

and implements interface class:

```perl
package Foo {
    use Function::Interface::Impl qw(IFoo);

    use Function::Parameters;
    use Function::Return;
    use Types::Standard -types;

    fun hello(Str $msg) :Return(Str) {
        return "HELLO $msg";
    }
}
```

# DESCRIPTION

Function::Interface provides Interface like Java and checks the arguments and return type of the function at compile time.

# LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

kfly8 <kfly@cpan.org>
