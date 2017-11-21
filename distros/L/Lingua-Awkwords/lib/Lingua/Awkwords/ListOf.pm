# -*- Perl -*-
#
# instances of this object hold a list of choices that are all rendered
# together as a string

package Lingua::Awkwords::ListOf;

use strict;
use warnings;

use Moo;
use namespace::clean;

our $VERSION = '0.07';

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

########################################################################
#
# METHODS

sub add {
    my $self = shift;
    push @{ $self->terms }, @_;
    return $self;
}

sub add_filters { my $self = shift; push @{ $self->filters }, @_; return $self }

sub render {
    my ($self) = @_;

    my $str = '';
    for my $term ( @{ $self->terms } ) {
        $str .= $term->render;
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

Lingua::Awkwords::ListOf - container for a list of items

=head1 SYNOPSIS

This module is not typically used directly, as it will be created
and called as part of the pattern parse and then render phases of
other code.

=head1 DESCRIPTION

Container object for a list of items; upon B<render> these items will
each have B<render> call on them and that concatenated result (minus
anything excluded by filters) will be returned as a string.

=head1 ATTRIBUTES

=over 4

=item I<filters>

List of filters, if any.

=item I<filter_with>

String to replaced filtered values with, the empty string by default.

=item I<terms>

Items of the list are held here as an array reference.

=back

=head1 METHODS

=over 4

=item B<add> I<value> ..

Adds the given list of I<value> to the I<terms>.

=item B<add_filters> I<filter> ..

Adds one or more strings as a filter for the B<render> phase. These
limit what a unit can generate e.g. to remove repeated vowels from a
C<[VV]> pattern via C<[VV]^aa>.

=item B<new>

Constructor.

=item B<render>

Calls B<render> on turn on each item in the I<terms> list, joins those
results together, applies any filters, and returns that string result.

=item B<walk> I<callback>

Calls the I<callback> function with itself as the argument, then calls
B<walk> on all of the available I<terms>.

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

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
