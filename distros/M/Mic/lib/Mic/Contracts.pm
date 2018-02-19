package Mic::Contracts;
use strict;
use Mic::ContractConfig;

sub import {
    my (undef, %contract_for) = @_;

    Mic::ContractConfig::configure(\ %contract_for);
    strict->import();
}

1;

__END__

=head1 NAME

Mic::Contracts

=head1 SYNOPSIS

    # example.pl

    use Mic::Contracts
        'Foo' => { all  => 1 }, # all contracts are run
        'Bar' => { post => 1 }, # postconditions (and preconditions) are run
        'Baz' => { pre  => 0 }; # all contracts are skipped

    use Foo;
    use Bar;
    use Baz;

    # do stuff with Foo, Bar and Baz

=head1 DESCRIPTION

Allows contracts to be enabled for a given class or interface.

=head1 An Example

The following example illustrates the use of contracts, which are assertions that constrain the visible behaviour of objects.

    package Example::Contracts::BoundedQueue;

    use Mic::Class
        interface => {
            class => {
                new => {
                    require => {
                        positive_int_size => sub {
                            my (undef, $arg) = @_;
                            $arg->{max_size} =~ /^\d+$/ && $arg->{max_size} > 0;
                        },
                    },
                    ensure => {
                        zero_sized => sub {
                            my ($obj) = @_;
                            $obj->size == 0;
                        },
                    }
                },
            },
            object => {
                head => {},
                tail => {},
                size => {},
                max_size => {},

                push => {
                    ensure => {
                        size_increased => sub {
                            my ($self, $old) = @_;

                            return $self->size < $self->max_size
                              ? $self->size == $old->size + 1
                              : 1;
                        },
                        tail_updated => sub {
                            my ($self, $old, $results, $item) = @_;
                            $self->tail == $item;
                        },
                    }
                },

                pop => {
                    require => {
                        not_empty => sub {
                            my ($self) = @_;
                            $self->size > 0;
                        },
                    },
                    ensure => {
                        returns_old_head => sub {
                            my ($self, $old, $results) = @_;
                            $results->[0] == $old->head;
                        },
                    }
                },
            },
            invariant => {
                max_size_not_exceeded => sub {
                    my ($self) = @_;
                    $self->size <= $self->max_size;
                },
            },
        },

        implementation => 'Example::Contracts::Acme::BoundedQueue_v1',
    ;

    1;

The contract constrains the behaviour of its implementation in various ways:

=over

=item *

The precondition on C<new> requires that its argument is a positive integer.

=item *

The postconditions on C<push> ensure that the queue size increases by one after a push, and that the newly pushed item is at the back of the queue.

=item *

The postcondition on C<pop> ensures that a popped item was previously at the front of the queue.

=item *

The invariant ensures that the queue never exceeds its maximum size.

=back

=head1 Types of Contracts

=head2 Preconditions (require)

A precondition is an assertion that is run before a given method, that defines one or more conditions that must
be met in order for the given method to be callable.

Preconditions are specified using the C<require> key of a contract definition. The corresponding value is a hash
of description => subroutine pairs.

Each such subroutine is a method that receives the same parameters as the method the precondition is attached to,
and returns either a true or false result. If false is returned, an exception is raised indicating which precondition
was violated.

=head2 Postconditions (ensure)

A postcondition is an assertion that is run after a given method, that defines one or more conditions that must
be met after the given method has been called.

Postconditions are specified using the C<ensure> key of a contract definition. The corresponding value is a hash
of description => subroutine pairs.

Each such subroutine is a method that receives the following parameters: the object as it is after the method call,
the object as it was before the method call, the results of the method call stored in array ref, and any parameters
that were passed to the method.

The subroutine should return either a true or false result. If false is returned, an exception is raised indicating which postcondition was violated.

=head2 Invariants

An invariant is an assertion that is run before and after every method in the interface, that defines one or more conditions that must
be met before and after the method has been called.

Invariants are specified using the C<invariant> key of a interface definition. The corresponding value is a hash
of description => subroutine pairs.

Each such subroutine is a method that receives the object as its only parameter,
and returns either a true or false result. If false is returned, an exception is raised indicating which invariant
was violated.

=head1 Enabling Contracts

Postconditions and invariants are not run by default, because they can result in many additional subroutine calls.

=head2 Via Code

To enable them, use L<Mic::Contracts>, e.g. to activate all contract types
for the Example::Contracts::BoundedQueue class, the following can be done:

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { all => 1 };

This turns on preconditions, postconditions and invariants. Whereas

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { post => 1 };

turns on postconditions (and preconditions). And

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { invariant => 1 };

turns on invariants (and preconditions).

Any defined preconditions will be run unless they are deactivated, which can be done with:

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { pre => 0 };

=head2 Via Configuration file

Alternatively, contracts can be controlled more dynamically by setting the environment variable C<MIC_CONTRACTS> to the name of a .ini file. 

For example, given the file my.contracts.ini with the following content

    [Example::Contracts::BoundedQueue]
    invariant = on
    pre = off

and by setting C<MIC_CONTRACTS>

    export MIC_CONTRACTS=/path/to/my.contracts.ini

Then invariant checking will be turned on for Example::Contracts::BoundedQueue.

The format of the file is simple: one section per Class/Interface. Then within each section the keys are contract types

=over

=item pre

Preconditions

=item post

Postconditions

=item invariant

Invariants

=item all

All contract types

=back

The values are interpreted as booleans, with 0, 'off' and 'false' being considered false (and anything else considered true).

=head1 See Also

Mic::Contracts are inspired by Design by Contract in L<Eiffel|https://www.eiffel.com/values/design-by-contract/introduction/>
