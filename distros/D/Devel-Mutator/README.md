# NAME

Devel::Mutator - Mutation testing for Perl

# SYNOPSIS

    mutator mutate lib/MyModule.pm
    mutator test

# DESCRIPTION

Devel::Mutator is a mutation testing toolkit for Perl. Mutation testing is
changing the working program in different ways and checking that the test suite
fails and thus detecting the bad testing.

## How it works

First we generate mutated code. For example every occurance of `=` is replaced
by `!=`. All the mutants are collected in the `mutants/` directory. Then we
run the tests replacing original code by the mutant. If the test suite does not
fail when the code is changed it is reported with a `diff` output, which helps
to see the problem.

    (10/18) ./mutants/7021082cc1c0afbe9322f60a9b5e5d5f/lib/Input/Validator/Field.pm ... not ok
    --- ./mutants/7021082cc1c0afbe9322f60a9b5e5d5f/lib/Input/Validator/Field.pm Sat Nov  1 11:27:00 2014
    +++ lib/Input/Validator/Field.pm.bak    Sun May 18 21:50:14 2014
    @@ -14,7 +14,7 @@
         my $self = shift;

         $self->{constraints} ||= [];
    -    $self->{messages}    //= {};
    +    $self->{messages}    ||= {};

         $self->{trim} = 1 unless defined $self->{trim};

Here we can see that the test suite does not check the need for `//`.

## Warning

The original code is replaced by the mutants, so make sure it is under a VCS if
something bad happens.  This is the easiest and the 100% working way. Maybe
this will be changed in the future when a better way is found.

## Mutation testing drawbacks

There are several drawbacks.

### The equivalent program

The equivalent program can be produced thus failing the test. There is no
solution to that for now.

### Infinite loops

Infinite loops can be created easily. The solution is to run the test suite
limited in time through a `timeout` option, which is 10s by default. After 10s
of running, the test suite is killed and `n/a timeout` is reported.

# METHODS

# CREDITS

Alexandr Ciornii (chorny)

Tim Teasdale (hooverbag)

Patricio Valle (pvallev)

# AUTHOR

Viacheslav Tykhanovskyi, <viacheslav.t@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.
