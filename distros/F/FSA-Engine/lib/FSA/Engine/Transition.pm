package FSA::Engine::Transition;
#
# A transition taking place in FSA::Engine
#
use Moose;

has 'test'  => (
    is          => 'rw',
    required    => 1,
);

has 'action'    => (
    is          => 'rw',
);

has 'state'     => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);


# Test against an input value
#
sub do_test {
    my ($self, $input) = @_;

    if ((ref $self->test) eq 'CODE') {
        my $ret_val = &{$self->test}($input);
        return $ret_val;
    }
    return $input eq $self->test;
}

1;


=head1 NAME

FSA::Engine::Transition - Transition object for FSA::Engine objects.

=head1 SYNOPSIS

A Transition object is created as part of the definition of your FSA object.

  sub _build_fsa_transitions {
    my ($self) = @_;

    my $transitions = {
        open => {
            slam_door   => FSA::Engine::Transition->new({
                test    => 'SHOVE DOOR',
                action  => sub {print "The door slams shut with a BANG\n";},
                state   => 'closed',
            }),
            close_door  => FSA::Engine::Transition->new({
                test    => sub {$self->test_door_push(@_)},
                action  => sub {print "There is a falling 'EEERRRrrrkkk' sound\n";},
                state   => 'closed',
            }),
        },
     ...
     
=head1 DESCRIPTION

This class defines a transition for your FSA class which has included the Moose Role
L<FSA::Engine>

It defines the B<test> to carry out to determine if the transition is valid, the
B<state> that is to be moved to if the B<test> succeeds and the optional B<action>
to perform when the transition is valid.

=head1 METHODS

=head2 new

Create a new instance. Takes the following attributes.

=head3 test

The B<test> to carry out to determine if the transition is to be followed.

If B<test> is a scalar, it is compared with the current B<fsa_input> attribute
of your FSA and if they are identical then the test is deemed to have passed.

Otherwise B<test> should be an anonymous subroutine which is called to determine
if the transition should be followed. This subroutine should return B<true> if
the test succeeds, otherwise undef.

=head3 state

The B<state> is simply the name of the state to move to if the B<test> succeeds.
It should be defined as a 'Str' Moose attribute.

=head3 action

This should be an anonymous subroutine reference which will be called if the
transition is followed. The subroutine will be called after any exit action
is called from the state being left and before any entry action of the state
being moved to.

=head2 do_test

This is the method called to determine if the test succeeds. It takes one parameter,
the B<fsa_input> value from your FSA.

The method looks at the B<test> attribute, if it is a code reference it calls the
anonymous subroutine passing the B<fsa_input> value as the first parameter. The
subroutine should return true or false depending upon whether the test should 
succeed or fail.

If it is not a code reference it carries out a comparison of the input value 
with the B<test> attribute returning the result of that comparison.

=head1 SUPPORT

This module is stored on an open TBD GitHub repository. Feel free to fork and contribute.

Please file bug reports via TBD or by sending email to.

=head1 AUTHOR

Ian C. Docherty <pause@iandocherty.com>

=head1 COPYRIGHT AND LICENSE

Copyright(c) 2011 Ian C. Docherty

This module is free software; you can distribute it and/or modify it under the same
terms as Perl itself.
