package Lingua::Diversity::SamplingScheme;

use Moose;

our $VERSION = '0.02';

use Lingua::Diversity::Subtype;


#=============================================================================
# Attributes.
#=============================================================================

has 'mode' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::SamplingMode',
    reader      => 'get_mode',
    writer      => 'set_mode',
    default     => 'random',
);

has 'subsample_size' => (
    is          => 'rw',
    isa         => 'Num',
    reader      => 'get_subsample_size',
    writer      => 'set_subsample_size',
    required    => 1,
);

has 'num_subsamples' => (
    is          => 'rw',
    isa         => 'Num',
    reader      => 'get_num_subsamples',
    writer      => 'set_num_subsamples',
    default     => 100,
);



#=============================================================================
# Standard Moose cleanup.
#=============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::Diversity::SamplingScheme - storing the parameters of a sampling
scheme

=head1 VERSION

This documentation refers to Lingua::Diversity::SamplingScheme version 0.02.

=head1 SYNOPSIS

    # Lingua::Diversity::SamplingScheme is used by Lingua::Diversity::Variety.
    use Lingua::Diversity::Variety;
    
    # Create a new sampling scheme...
    my $sampling_scheme = Lingua::Diversity::SamplingScheme->new(
        'mode'              => 'segmental',
        'subsample_size'    => 100,
    );
    
    # ... Then apply it to a Lingua::Diversity::Variety object.
    Lingua::Diversity::Variety->new(
        'transform'         => 'type_token_ratio',
        'sampling_scheme'   => $sampling_scheme,
    );


=head1 DESCRIPTION

This class serves as storage for a set of parameters defining a sampling
scheme (to be used with a L<Lingua::Diversity::Variety> object). Such a scheme
is meant to describe the kind of resampling that should be applied as well as
the number of subsamples and their size.

=head1 CREATOR

The creator (C<new()>) returns a new Lingua::Diversity::SamplingScheme object.
It takes one required and two optional named parameters:

=over 4

=item subsample_size (required)

The requested number of unit tokens per subsample (a positive integer).

=item num_subsamples

The number of subsamples to be drawn (a positive integer). Default is
100. Note that this parameter has no effect in I<segmental> mode (see below),
since in this case the number of subsamples is the result of the integer
division of text length by requested subsample size.

=item mode

Either I<random> (default) or I<segmental>.

Value 'random' means that (i) the order of unit tokens in the text
should not be modified in a given subsample, and (ii) the probability for a
unit token to occur in a given subsample depends only on the requested
subsample size (see I<subsample_size> above). E.g. from text I<say you say
me>, the following subsamples of size 3 (and only them) could be generated
(with uniform probability): I<say you say>, I<say you me>, I<say say me>, and
I<you say me>.

Value 'segmental' means that subsamples should be continuous, non-overlapping
sequences of units in the original text. For example, text I<say you say me>
would give rise to exactly two subsamples of size 2: I<say you> and I<say me>.
Incomplete subsamples at the end of the text are ignored, so that a subsample
size of 3 would produce a single subsample in this example (i.e. I<say you
say>). Note that in this mode, it is assumed that the unit and category arrays
are in the text's order.

=back

=head1 ACCESSORS

=over 4

=item get_subsample_size() and set_subsample_size()

Getter and setter for the I<subsample_size> attribute.

=item get_num_subsamples() and set_num_subsamples()

Getter and setter for the I<num_subsamples> attribute.

=item get_mode() and set_mode()

Getter and setter for the I<mode> attribute.

=back

=head1 DEPENDENCIES

This module is part of the L<Lingua::Diversity> distribution.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Aris Xanthos (aris.xanthos@unil.ch)

Patches are welcome.

=head1 AUTHOR

Aris Xanthos  (aris.xanthos@unil.ch)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Aris Xanthos (aris.xanthos@unil.ch).

This program is released under the GPL license (see
L<http://www.gnu.org/licenses/gpl.html>).

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Lingua::Diversity> and L<Lingua::Diversity::Variety>

