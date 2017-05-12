package Dredd::Hooks::Methods;

=head1 NAME

Dredd::Hooks::Methods - Sugar module for each of writing Dredd Hookfiles

=head1 SUMMARY

    #!/usr/bin/env perl
    # hookfiles.pl

    use strict;
    use warnings;

    use Dredd::Hooks::Methods;

    before('/messages > GET' => sub {
        my ($transaction) = @_;

        $transaction->{headers}{RawData}{Auth} = 'Basic: hud87y2h8o7ysdiuhlku12h=='
    });

=head1 DESCRIPTION

Dredd::Hooks::Methods provides useful functions for writing
Dredd hook files.

L<Dredd|https://dredd.readthedocs.org> is a testing framework
for testing API BluePrint formatted API definition files
against the implemenation that exposes that API. This is useful
to ensure that the API documentation doesn't get out of sync
with an new code changes.

L<Dredd::Hooks> provides and implementation of the
L<Dredd hooks handler socket interface|https://dredd.readthedocs.org/en/latest/hooks-new-language/>
and ensures that hooks from user defined hook files are run in
the correct order and with the correct information.

Dredd::Hooks::Methods provides functionallity that allow the
user to define the hooks files that get run and their
functionality.

=head1 Creating a hook file

Hookfiles are plain .pl perl files containing some callbacks
that are run for specific events.

The hookfile should have a .pl file extention (required by the
dredd funtion and are provided as an argument to the dredd code:

C<dredd apiary.apib http://localhost:5000 --language perl --hookfiles=./hooks/hooks_*.pl>

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

=cut

use strict;
use warnings;

use Hash::Merge;
use Sub::Exporter -setup => {
    exports => [qw/
        before
        beforeAll
        beforeEach
        beforeEachValidation
        beforeValidation
        after
        afterAll
        afterEach
        get_hooks
        merge_hook
    /],
    groups => {
        default => [qw/
            before
            beforeAll
            beforeEach
            beforeEachValidation
            beforeValidation
            after
            afterAll
            afterEach
        /],
        handler => [qw/
            get_hooks
            merge_hook
        /]
    }
};

{
    my $hooks = {};
    sub get_hooks {
        return $hooks;
    }

    my $merger = Hash::Merge->new('RETAINMENT_PRECEDENT');
    sub merge_hook {
        my ($hook) = @_;

        $hooks = $merger->merge($hooks, $hook);
    }
}

=head1 Events

=head2 beforeAll (callback Sub)

The beforeAll event is triggered before all transactions
are run. As such it is an ideal place to run test setup code.

The hook will receive an array of transaction hashrefs
representing each transaction that will be implemented.

=cut

sub beforeAll {
    my ($callback) = @_;

    merge_hook({beforeAll => $callback });
}

=head2 beforeEach (callback Sub)

The beforeEach event is called for before each transaction
is run.

The hook will receive a single transaction hashref.

NOTE: This event from Dredd triggers the before event

=cut

sub beforeEach {
    my ($callback) = @_;

    merge_hook({beforeEach => $callback });
}

=head2 before (name Str, callback Sub)

The before event is called for each transaction whose
name attribute matches that given in the hook creation.

The hook will receive a single transaction hashref.

NOTE: before is not actually and event called by Dredd
directly but it is called after the beforeEach event.

=cut

sub before {
    my ($name, $callback) = @_;

    merge_hook({before => { $name => $callback }});
}

=head2 beforeEachValidation (callback Sub)

The beforeEachValidation event is called for before each
transactions result is validated.

The hook will receive a single transaction hashref.

NOTE: This event is from Dredd triggers the beforeValidation event

=cut

sub beforeEachValidation {
    my ($callback) = @_;

    merge_hook({beforeEachValidation => $callback });
}

=head2 beforeValidation (name Str, callback Sub)

The beforeEachValidation event is called for before the
validation of each transactions result, whose transaction
name matches the name supplied to this function, is validatated.

The hook will receive a single transaction hashref.

NOTE: beforeValidation is not actually and event called by Dredd
directly but it is called after the beforeEachValidation event.

=cut

sub beforeValidation {
    my ($name, $callback) = @_;

    merge_hook({beforeValidation => { $name => $callback }});
}

=head2 after (name Str, callback Sub)

The after event is called after each transaction whose
name attribute matches that given in the hook creation.

The hook will receive a single transaction hashref.

NOTE: after is not actually and event called by Dredd
directly but it is called before the afterEach event.

=cut

sub after {
    my ($name, $callback) = @_;

    merge_hook({after => { $name => $callback }});
}

=head2 beforeEach (callback Sub)

The afterEach event is called for after each transaction
is run.

The hook will receive a single transaction hashref.

NOTE: This event from Dredd triggers the after event

=cut

sub afterEach {
    my ($callback) = @_;

    merge_hook({afterEach => $callback });
}

=head2 afterAll (callback Sub)

The afterAll event is triggers after all transactions are run.
As such it is an ideal place to run test teardown code.

The hook will receive an array of transaction hashrefs
representing each transaction that will be implemented.

=cut

sub afterAll {
    my ($callback) = @_;

    merge_hook({afterAll => $callback });
}
1;
__END__

=head1 BUGS AND REQUESTS

This modules source is stored in L<GitHub|https://github.com/ungrim97/Dredd-Hooks>
and any issues or suggestions should be posted there.

=head1 AUTHOR

Mike Eve E<lt>ungrim97@gmail.comE<gt>

=head1 LICENSE

Copyright 2016 - Broadbean Technologies, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Broadbean for providing time to open source this during one of the regular Hack-days.

=cut

