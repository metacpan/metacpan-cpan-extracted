use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Rule::PropertyBitSet;

# ABSTRACT: ESLIF Rule Property Bit Set

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


use Carp qw/croak/;

our $VERSION = '3.0.14'; # VERSION

# This section should be replaced on-the-fly at build time
# AUTOLOAD

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Rule::PropertyBitSet - ESLIF Rule Property Bit Set

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $rulePropertyBitSet;
  $rulePropertyBitSet = MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_ACCESSIBLE;     #  0x01
  $rulePropertyBitSet = MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_NULLABLE;       #  0x02
  $rulePropertyBitSet = MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_NULLING;        #  0x04
  $rulePropertyBitSet = MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_LOOP;           #  0x08
  $rulePropertyBitSet = MarpaX::ESLIF::Rule::PropertyBitSet->MARPAESLIF_RULE_IS_PRODUCTIVE;     #  0x10

=head1 DESCRIPTION

ESLIF rule property bitset is made of constants, mapping the low-level Marpa view of rule capabilities. This module is giving access to them.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
