FSA/Rules version 0.35
======================

[![CPAN version](https://badge.fury.io/pl/FSA-Rules.svg)](http://badge.fury.io/pl/FSA-Rules)
[![Build Status](https://travis-ci.org/theory/fsa-rules.svg)](https://travis-ci.org/theory/fsa-rules)
[![Coverage Status](https://coveralls.io/repos/theory/fsa-rules/badge.svg)](https://coveralls.io/r/theory/fsa-rules)

FSA::Rules implements a simple state machine pattern, allowing you to quickly
build rules-based state machines in Perl. As a simple implementation of a
powerful concept, it differs slightly from an ideal DFA model in that it does
not enforce a single possible switch from one state to another. Rather, it
short circuits the evaluation of the rules for such switches, so that the
first rule to return a true value will trigger its switch and no other switch
rules will be checked. (But see the `strict` attribute and parameter to
`new()`.) It differs from an NFA model in that it offers no back-tracking. But
in truth, you can use it to build a state machine that adheres to either
model--hence the more generic FSA moniker.

FSA::Rules uses named states so that it's easy to tell what state you're in
and what state you want to go to. Each state may optionally define actions
that are triggered upon entering the state, after entering the state, and upon
exiting the state. They may also define rules for switching to other states,
and these rules may specify the execution of switch-specific actions. All
actions are defined in terms of anonymous subroutines that should expect an
FSA::State object itself to be passed as the sole argument.

FSA::Rules objects and the FSA::State objects that make them up are all
implemented as empty hash references. This design allows the action
subroutines to use the FSA::State object passed as the sole argument, as well
as the FSA::Rules object available via its `machine()` method, to stash data
for other states to access, without the possibility of interfering with the
state or the state machine itself.

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies
------------

This module requires no modules or libraries not already included with Perl.
It does, however recommend the following modules:

* GraphViz 2.00
* Text::Wrap
* Storable 2.05
* B::Deparse 0.61

Copyright and License
---------------------

Copyright (c) 2002-2015, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
