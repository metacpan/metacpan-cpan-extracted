use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Symbol::Type;

# ABSTRACT: ESLIF Symbol Type

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

MarpaX::ESLIF::Symbol::Type - ESLIF Symbol Type

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $symbolType;
  $symbolType = MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_TERMINAL;      #  0
  $symbolType = MarpaX::ESLIF::Symbol::Type->MARPAESLIF_SYMBOLTYPE_META;          #  1

=head1 DESCRIPTION

ESLIF symbol type is made of constants. This module is giving access to them.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
