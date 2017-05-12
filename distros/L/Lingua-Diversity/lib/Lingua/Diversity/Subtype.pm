#!/usr/bin/perl

package Lingua::Diversity::Subtype;

use strict;
use warnings;
use Carp;

our $VERSION = 0.02;


#=============================================================================
# Subtype definitions
#=============================================================================

use Moose::Util::TypeConstraints;

enum 'Lingua::Diversity::Subtype::VarietyTransform', [ qw(
    none
    type_token_ratio
    mean_frequency
    guiraud
    herdan
    rubet
    maas
    dugast
    lukjanenkov_nesitoj
) ];

enum 'Lingua::Diversity::Subtype::WeightingMode', [ qw(
    within_only
    within_and_between
) ];

enum 'Lingua::Diversity::Subtype::SamplingMode', [ qw(
    random
    segmental
) ];

subtype 'Lingua::Diversity::Subtype::Natural',
    as 'Int',
    where { $_ > 0 };

subtype 'Lingua::Diversity::Subtype::PosNum',
    as 'Num',
    where { $_ > 0 };

subtype 'Lingua::Diversity::Subtype::BetweenZeroAndOneIncl',
    as 'Num',
    where { $_ >= 0 && $_ <= 1 };

subtype 'Lingua::Diversity::Subtype::BetweenZeroAndOneExcl',
    as 'Num',
    where { $_ > 0 && $_ < 1 };

no Moose::Util::TypeConstraints;





1;


__END__


=head1 NAME

Lingua::Diversity::Subtype - subtype definitions for Lingua::Diversity

=head1 VERSION

This documentation refers to Lingua::Diversity:Subtype version 0.02.

=head1 DESCRIPTION

This module provides custom Moose subtypes for the Lingua::Diversity
distribution.

=head1 DEPENDENCIES

This module is part of the Lingua::Diversity distribution. It uses
L<Moose::Utils::TypeConstraints>.

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

L<Lingua::Diversity>

