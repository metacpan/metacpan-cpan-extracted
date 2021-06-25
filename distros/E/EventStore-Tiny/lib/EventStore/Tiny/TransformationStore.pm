package EventStore::Tiny::TransformationStore;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Carp;

use Class::Tiny {
    _transformation => sub {{}},
};

sub names ($self) {
    my @sorted_names = sort keys %{$self->_transformation};
    return @sorted_names; # return sort is undefined in scalar context
}

sub get ($self, $name) {
    return $self->_transformation->{$name};
}

sub set ($self, $name, $transformation) {

    # Guard
    croak "Event $name cannot be replaced!\n"
        if exists $self->_transformation->{$name};

    # Replace
    $self->_transformation->{$name} = $transformation;
}

1;

=pod

=encoding utf-8

=head1 NAME

EventStore::Tiny::TransformationStore

=head1 REFERENCE

EventStore::Tiny::TransformationStore implements the following methods.

=head2 METHODS

=head3 names

    my @event_names = $ts->names;

Returns a sorted list of all stored event names.

=head3 get

    my $transformation = $ts->get('Foo');

Returns the transformation subroutine (as a coderef) for the given name. If no corresponding transformation subroutine could be found, it returns C<undef>.

=head3 set

    $ts->set(Foo => sub {
        my ($state, $data) = @_;
        # manipulate $state
    });

Registers a transformation subroutine under a given name in the store. It should change the given state argument (as a hashref) based on the given data (as a hashref) by side-effect.

=head1 SEE ALSO

L<EventStore::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018-2021 Mirko Westermeier (mail: mirko@westermeier.de)

Released under the MIT License (see LICENSE.txt for details).

=cut
