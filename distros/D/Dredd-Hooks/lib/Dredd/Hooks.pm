package Dredd::Hooks;

=encoding utf-8

=head1 NAME

Dredd::Hooks - Handler for running Hook files for Dredd

=head1 SYNOPSIS

    use Dredd::Hooks;

    my $hook_runner = Dredd::Hooks->new(hook_files => [...]);

    my $hook_runner->$event."_hook"

=head1 DESCRIPTION

Dredd::Hooks provides the code to actually run the hooks used in the
L<Dredd|https://dredd.readthedocs.org> API testing suite.

Unless you are righting your own TCP server to accept Dredd Hook requests
then you likely want L<Dredd::Hooks::Methods> which describes how to write
Dredd Hook files.

=cut

use Moo;

use Dredd::Hooks::Methods '-handler';

our $VERSION = "0.05";

use Types::Standard qw/HashRef ArrayRef/;

# Stores the hooks that result from Dredd::Hooks::Methods
has _hooks => (
    is => 'lazy',
    isa => HashRef
);

=head1 ATTRIBUTES

=head2 hook_files

An arrayref of fully expanded file names that will be required
and should contain hook code.

See L<Dredd::Hooks::Methods> for information on creating these
files

=cut

has hook_files => (
    is => 'ro',
    isa => ArrayRef
);

# Run each hook file in $self->hook_files and then
# return the value stored in Dredd::Hooks::Methods

sub _build__hooks {
    my ($self) = @_;

    my $hook_files = $self->hook_files;
    return {} unless $hook_files && scalar @$hook_files;

    for my $hook_file (@$hook_files){
        next unless -e $hook_file;

        do $hook_file;
    }

    return Dredd::Hooks::Methods::get_hooks();
}

# Run the hook callback specified for this event/transaction
# combination.

sub _run_hooks {
    my ($self, $hooks, $transaction) = @_;

    return $transaction unless $hooks;

    $hooks = [$hooks] unless ref $hooks eq 'ARRAY';

    for my $hook (@$hooks){
        next unless $hook && ref $hook eq 'CODE';

        $hook->($transaction);
        STDOUT->flush;
    }
    return $transaction;
}

=head1 EVENT METHODS

=head2 beforeEach_hook (transaction HashRef -> transaction HashRef)

Runs hooks for the BeforeEach event from Dredd. This then calls
the before_hook before returning. This is because the before event
is not an event directly called by dredd.

=cut

sub beforeEach_hook {
    my ($self, $transaction) = @_;

    return $self->before_hook(
        $self->_run_hooks(
            $self->_hooks->{beforeEach},
            $transaction
        )
    );
}

=head2 before_hook (transaction HashRef -> transaction HashRef)

Runs the before event hooks and returns the modified transaction object

NOTE: This is currently run by the beforeEach handler as the before event
is not an event directly sent from Dredd.

=cut

sub before_hook {
    my ($self, $transaction) = @_;

    return $self->_run_hooks(
        $self->_hooks->{before}{$transaction->{name}},
        $transaction,
     );
}

=head2 beforeEachValidation_hook (transaction HashRef -> transaction HashRef)

Handles the beforeEachValidation event from Dredd. This then calls the beforeValidation_hook
to handle the beforeValidation event.

=cut

sub beforeEachValidation_hook {
    my ($self, $transaction) = @_;

    return $self->beforeValidation_hook(
        $self->_run_hooks(
            $self->_hooks->{beforeEachValidation},
            $transaction
        )
    );
}

=head2 beforeValidation_hook (transaction HashRef -> transaction HashRef)

Handles the beforeValidation event and returns the modified transaction.

NOTE: This event is called from beforeEachValidation_hook as it is not
and event directly run from Dredd.

=cut

sub beforeValidation_hook {
    my ($self, $transaction) = @_;

    return $self->_run_hooks(
        $self->_hooks->{beforeValidation}{$transaction->{name}},
        $transaction
    );
}

=head2 afterEach_hook (transaction HashRef -> transaction HashRef)

Handles the afterEach event from Dredd. Runs the after_hook handler
first before running hooks for this event.

=cut

sub afterEach_hook {
    my ($self, $transaction) = @_;

    return $self->_run_hooks(
        $self->_hooks->{afterEach},
        $self->after_hook($transaction),
    )
}

=head2 after_hook (transaction HashRef -> transaction HashRef)

Handles the after event and returns the modified transaction.

NOTE: This event is called from the afterEach_hook as it is not
and event directly run from Dredd.

=cut

sub after_hook {
    my ($self, $transaction) = @_;

    return $self->_run_hooks(
        $self->_hooks->{after}{$transaction->{name}},
        $transaction
    )
}

# *All hooks recieve and arrayref of hook transaction objects

=head2 beforeAll (transactions ArrayRef[transaction] -> transactions ArrayRef[transaction])

Handles the beforeAll event from Dredd. Receives an arrayref of transaction hashrefs and
returns the modified version.

=cut

sub beforeAll_hook {
    my ($self, $transactions) = @_;

    return $self->_run_hooks(
        $self->_hooks->{beforeAll},
        $transactions
    );
}

=head2 afterAll (transactions ArrayRef[transaction] -> transactions ArrayRef[transaction])

Handles the afterAll event from Dredd. Receives an arrayref of transaction hashrefs and
returns the modified version.

=cut

sub afterAll_hook {
    my ($self, $transactions) = @_;

    return $self->_run_hooks(
        $self->_hooks->{afterAll},
        $transactions
    );
}

1;
__END__

=head1 BUGS AND REQUESTS

This modules source is stored in L<GitHub|https://github.com/ungrim97/Dredd-Hooks>
and any issues or suggestions should be posted there.

=head1 LICENSE

Copyright (C) Mike Eve.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Mike Eve E<lt>ungrim97@gmail.comE<gt>

=cut

