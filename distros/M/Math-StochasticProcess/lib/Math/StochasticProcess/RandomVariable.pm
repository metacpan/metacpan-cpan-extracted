package Math::StochasticProcess::RandomVariable;

use warnings;
use strict;
use Params::Validate qw(:all);
use Carp;

=head1 NAME

Math::StochasticProcess::RandomVariable - Part of the Math::StochasticProcess::Tuple model

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

See L<Math::StochasticProcess::Event::Tuple>. The C<RandomVariable> class
represents a numerical random variable. The Tuple class represents a set of
named random variables, and also controls how random variables change.

=head1 FUNCTIONS

=head2 new

A standard constructor. The possible arguments are as follows:

=over

=item value

This should be set to the initial value.

=item validate_cb

This optional coderef is run against any change of value and must always return 1.

=item internal

Internal random variables are ignored once an Event is resolved. Probably
internal random variables need not be numerical.

=back

=cut

sub new {
    my $class = shift;
    my %options = validate
    (
        @_,
        {
            # If this is too restrictive,
            # you should be deriving your own class from Event.
            value =>
            {
                type=>SCALAR,
                optional=>0
            },
            # If specified &$options{validate_cb}(current value) must always
            # return true.
            validate_cb=>
            {
                type=>CODEREF,
                optional=>1
            },
            # Variables can be external or internal.
            # Internal variables only figure in the calculation so
            # long as the event is unresolved.
            internal =>
            {
                type=>BOOLEAN,
                default=>0
            }
        }
    );
    my $self = \%options;
    bless $self, $class;
    croak "$options{value} does not meet constraint" unless $self->checkValue();

    return $self;
}

=head2 checkValue

This function checks that the value of the C<RandomVariable> satisfies its internal
constraint.

=cut

sub checkValue {
    my $self = shift;
    if (exists $self->{validate_cb}) {
        return $self->{validate_cb}($self->{value});
    }
    return 1;
}

=head2 value

This returns the current.

=cut

sub value {
    my $self = shift;
    return $self->{value};
}

=head2 signature

The signature gives an approximate value to the variable for the purposes of
event merging. The more lumpy the variable then the bigger the approximation. If
the variable has undefined lumpiness, then the signature is just the same as the
value.

=cut

sub signature {
    my $self = shift;
    return $self->{value};
}

=head2 merge

This is a utility function for Math::StochasticProcess::Event::Tuple::merge. We
choose this interface to allow for the possibility that derived classes might
want to regard "similar" values as essentially identical. In such a case the
probabilities would be required to set the new value to a weighted average.

=cut

sub merge {
    my $self = shift;
    my $other = shift;
    my $self_prob = shift;
    my $other_prob = shift;
    return;
}

=head2 copy

This is a utility function for C<Math::StochasticProcess::Event::Tuple::copy>. It
is effectively a constructor of the C<RandomVariable>. It returns a copy of the
C<RandomVariable> with a change specified by the C<$change> parameter. This might be a
new value or callback which is applied to the old value to get the new value.

=cut

sub copy {
    my $self = shift;
    my $change = shift;
    my $copy = {internal=>$self->{internal}};
    $copy->{validate_cb} = $self->{validate_cb} if exists $self->{validate_cb};
    if (!defined $change) {
        $copy->{value} = $self->{value};
    }
    elsif (ref $change eq "CODEREF") {
        $copy->{value} = &$change($self->{value});
    }
    else {
        $copy->{value} = $change;
    }
    bless $copy, ref $self;
    croak "$change does not meet constraint" unless $copy->checkValue();

    return $copy;
}

=head2 isInternal

Internal variables only figure in the calculation so long as the Event is
unresolved.

=cut

sub isInternal {
    my $self = shift;
    return $self->{internal};
}

=head1 AUTHOR

Nicholas Bamber, C<< <theabbot at silasthemonk.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-pea-randomvariable at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-StochasticProcess>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::StochasticProcess

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-StochasticProcess>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-StochasticProcess>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-StochasticProcess>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-StochasticProcess>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Nicholas Bamber, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Math::StochasticProcess::RandomVariable
