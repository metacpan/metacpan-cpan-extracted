use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Symbol::EventBitSet;

# ABSTRACT: ESLIF Symbol Event Bit Set

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

MarpaX::ESLIF::Symbol::EventBitSet - ESLIF Symbol Event Bit Set

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $symbolEventBitSet;
  $symbolEventBitSet = MarpaX::ESLIF::Symbol::EventBitSet->MARPAESLIF_SYMBOL_EVENT_COMPLETION;  #  0x01
  $symbolEventBitSet = MarpaX::ESLIF::Symbol::EventBitSet->MARPAESLIF_SYMBOL_EVENT_NULLED;      #  0x02
  $symbolEventBitSet = MarpaX::ESLIF::Symbol::EventBitSet->MARPAESLIF_SYMBOL_EVENT_PREDICTION;  #  0x04

=head1 DESCRIPTION

ESLIF symbol event bitset is made of constants, mapping the low-level Marpa view of symbol events. This module is giving access to them.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
