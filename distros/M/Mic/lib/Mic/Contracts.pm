package Mic::Contracts;
use strict;

sub import {
    my (undef, %contract_for) = @_;

    foreach my $class ( keys %contract_for ) {
        $Mic::Contracts_for{$class} = $contract_for{$class};
        if ( $Mic::Contracts_for{$class}{all} ) {
            $Mic::Contracts_for{$class} = { map { $_ => 1 } qw/pre post invariant/ };
        }
    }
    strict->import();
}

1;

__END__

=head1 NAME

Mic::Contracts

=head1 SYNOPSIS

    # example.pl

    use Mic::Contracts
        'Foo' => { all => 1 }, # all contracts are run
        'Bar' => { pre => 1 }, # only preconditions are run

    use Foo;
    use Bar;

    # do stuff with Foo and Bar

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

Contracts are not run by default, because they can result in many additional subroutine calls.

To enable them, use L<Mic::Contracts>, e.g. to activate contracts
for the Example::Contracts::BoundedQueue class, the following can be done:

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { all => 1 };

This turns on preconditions, postconditions and invariants.

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { pre => 1 };

turns on preconditions only.

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { post => 1 };

turns on postconditions only.

    use Mic::Contracts 'Example::Contracts::BoundedQueue' => { invariant => 1 };

turns on invariants only.

=head1 See Also

Mic::Contracts are inspired by Design by Contract in L<Eiffel|https://www.eiffel.com/values/design-by-contract/introduction/>
