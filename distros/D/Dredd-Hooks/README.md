[![Build Status](https://travis-ci.org/ungrim97/Dredd-Hooks.svg?branch=master)](https://travis-ci.org/ungrim97/Dredd-Hooks)
# NAME

Dredd::Hooks::Methods - Sugar module for each of writing Dredd Hookfiles

# SUMMARY

    #!/usr/bin/env perl
    # hookfiles.pl

    use strict;
    use warnings;

    use Dredd::Hooks::Methods;

    before('/messages > GET' => sub {
        my ($transaction) = @_;

        $transaction->{headers}{RawData}{Auth} = 'Basic: hud87y2h8o7ysdiuhlku12h=='
    });

# DESCRIPTION

Dredd::Hooks::Methods provides useful functions for writing
Dredd hook files.

[Dredd](https://dredd.readthedocs.org) is a testing framework
for testing API BluePrint formatted API definition files
against the implemenation that exposes that API. This is useful
to ensure that the API documentation doesn't get out of sync
with an new code changes.

[Dredd::Hooks](https://metacpan.org/pod/Dredd::Hooks) provides and implementation of the
[Dredd hooks handler socket interface](https://dredd.readthedocs.org/en/latest/hooks-new-language/)
and ensures that hooks from user defined hook files are run in
the correct order and with the correct information.

Dredd::Hooks::Methods provides functionallity that allow the
user to define the hooks files that get run and their
functionality.

# Creating a hook file

Hookfiles are plain .pl perl files containing some callbacks
that are run for specific events.

The hookfile should have a .pl file extention (required by the
dredd funtion and are provided as an argument to the dredd code:

`dredd apiary.apib http://localhost:5000 --language perl --hookfiles=./hooks/hooks_*.pl`

for each event listed in the Dredd documentation a method is
provided that takes a sub ref that will be run for that event,
This event will receive a transaction (HashRef) or an arrayref of
transactions that it should modify in place. The return value of this
function will be ignored:

    beforeAll(sub {
        my ($transactions) = @_;
    });

    beforeEach(sub {
        my ($transaction) = @_;
    });

See the each event below for the which events take which arguments.
If multiple callbacks are defined for the same event then these will
be run individually in the order defined. e.g:

    beforeAll(sub {
        ... # Run First
    });

    beforeAll(sub {
        ... # Run Second
    });

You can also supply multiple files (or a glob) to the dredd command
and these will all be coallated together. Allowing spefic hooks for
specific transactions or event types.

All events are run in a specific order:

      beforeAll - Run before all transactions
      beforeEach - Run before each transaction
      before - Run before specific transactions
      beforeEachValidation - Run before each Validation step
      beforeValidation - Run before a specific validation step
      after - Run after a specific transaction
      afterEach - Run after each transaction
      afterAll - Run after all transactions

# Events

## beforeAll (callback Sub)

The beforeAll event is triggered before all transactions
are run. As such it is an ideal place to run test setup code.

The hook will receive an array of transaction hashrefs
representing each transaction that will be implemented.

## beforeEach (callback Sub)

The beforeEach event is called for before each transaction
is run.

The hook will receive a single transaction hashref.

NOTE: This event from Dredd triggers the before event

## before (name Str, callback Sub)

The before event is called for each transaction whose
name attribute matches that given in the hook creation.

The hook will receive a single transaction hashref.

NOTE: before is not actually and event called by Dredd
directly but it is called after the beforeEach event.

## beforeEachValidation (callback Sub)

The beforeEachValidation event is called for before each
transactions result is validated.

The hook will receive a single transaction hashref.

NOTE: This event is from Dredd triggers the beforeValidation event

## beforeValidation (name Str, callback Sub)

The beforeEachValidation event is called for before the
validation of each transactions result, whose transaction
name matches the name supplied to this function, is validatated.

The hook will receive a single transaction hashref.

NOTE: beforeValidation is not actually and event called by Dredd
directly but it is called after the beforeEachValidation event.

## after (name Str, callback Sub)

The after event is called after each transaction whose
name attribute matches that given in the hook creation.

The hook will receive a single transaction hashref.

NOTE: after is not actually and event called by Dredd
directly but it is called before the afterEach event.

## beforeEach (callback Sub)

The afterEach event is called for after each transaction
is run.

The hook will receive a single transaction hashref.

NOTE: This event from Dredd triggers the after event

## afterAll (callback Sub)

The afterAll event is triggers after all transactions are run.
As such it is an ideal place to run test teardown code.

The hook will receive an array of transaction hashrefs
representing each transaction that will be implemented.

# BUGS AND REQUESTS

This modules source is stored in [GitHub](https://github.com/ungrim97/Dredd-Hooks)
and any issues or suggestions should be posted there.

# AUTHOR

Mike Eve &lt;ungrim97@gmail.com>

# LICENSE

Copyright 2016 - Broadbean Technologies, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# ACKNOWLEDGEMENTS

Thanks to Broadbean for providing time to open source this during one of the regular Hack-days.
