# -*- Perl -*-
#
# instances of this object hold a list of choices one of which is
# randomly picked upon render

package Lingua::Awkwords::OneOf;

use strict;
use warnings;

use Carp qw(croak confess);
use Math::Random::Discrete;
use Moo;
use namespace::clean;

our $VERSION = '0.04';

my $DEFAULT_WEIGHT = 1;

has filters => (
    is      => 'rwp',
    default => sub { [] },
);
has filter_with => (
    is      => 'rw',
    default => sub { '' },
);
has terms => (
    is      => 'rwp',
    default => sub { [] },
);
has picker => ( is => 'rwp', clearer => 1 );
has weights => (
    is      => 'rwp',
    default => sub { [] },
);

########################################################################
#
# METHODS

sub add_choice {
    croak "add_choice requires a value" if @_ < 2;
    my ( $self, $value, $weight ) = @_;
    push @{ $self->terms }, $value;
    push @{ $self->weights }, $weight // $DEFAULT_WEIGHT;
    $self->clear_picker;
    return $self;
}

sub add_filters { my $self = shift; push @{ $self->filters }, @_; return $self }

sub render {
    my $self = shift;
    my $str;

    my $terms = $self->terms;
    if ( !@$terms ) {
        # in theory this shouldn't happen. could also instead set the
        # empty string here...
        confess "no choices to pick from";
    } elsif ( @$terms == 1 ) {
        $str = $terms->[0]->render;
    } else {
        my $picker = $self->picker;
        if ( !defined $picker ) {
            $picker = Math::Random::Discrete->new( $self->weights, $terms );
            $self->_set_picker($picker);
        }
        $str = $picker->rand->render;
    }

    my $filter_with = $self->filter_with // '';
    for my $filter ( @{ $self->filters } ) {
        $str =~ s/\Q$filter/$filter_with/g;
    }
    return $str;
}

sub walk {
    my ($self, $callback) = @_;
    $callback->($self);
    for my $term ( @{ $self->terms } ) {
        $term->walk($callback);
    }
    return;
}

1;
__END__

=head1 NAME

Lingua::Awkwords::OneOf - random choice from a list of items

=head1 SYNOPSIS

This module is not typically used directly, as it will be created
and called as part of the pattern parse and then render phases of
other code.

=head1 DESCRIPTION

Container object for a list of items; upon B<render> one of these items
will be picked at random and have B<render> called on it. Whatever that
returns will be returned, minus whatever any filters may remove.

=head1 ATTRIBUTES

=over 4

=item I<filters>

List of filters, if any. Use B<add_filters> to set these.

=item I<filter_with>

String to replaced filtered values with, the empty string by default.

=item I<picker>

Where the L<Math::Random::Discrete> object to provide weighted random
choices is stored.

=item I<terms>

Choices are stored here as an array reference.

=item I<weights>

List of weights for each of the choices.

=back

=head1 METHODS

=over 4

=item B<add_choice> I<value> I<weight>

Adds the given I<value> and its I<weight> to the choices.

=item B<add_filters> I<filter> ..

Adds one or more strings as a filter for the B<render> phase. These
limit what a unit can generate, e.g. C<[x/y/z]^x> would replace a result
of C<x> with the empty string.

=item B<clear_picker>

This is used by the B<add> method to invalidate the picker object; call
this method if you have manually fiddled with the I<alts> or I<weights>
after making a B<render> call.

=item B<new>

Constructor.

=item B<render>

Picks a random choice and in turn calls B<render> on that, then applies
any filters present on that result.

=item B<walk> I<callback>

Calls the I<callback> function with itself as the argument, then calls
B<walk> on all of the available choices.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-lingua-awkwords at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Awkwords>.

Patches might best be applied towards:

L<https://github.com/thrig/Lingua-Awkwords>

=head2 Known Issues

None at this time.

=head1 SEE ALSO

L<Lingua::Awkwords>, L<Lingua::Awkwords::Parser>

L<Math::Random::Discrete>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
