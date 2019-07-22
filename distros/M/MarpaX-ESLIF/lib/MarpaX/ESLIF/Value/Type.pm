use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Value::Type;

# ABSTRACT: ESLIF Value Types

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

MarpaX::ESLIF::Value::Type - ESLIF Value Types

=head1 VERSION

version 3.0.14

=head1 SYNOPSIS

  use MarpaX::ESLIF;

  my $valueType;
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_UNDEF;         #  0
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_CHAR;          #  1
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_SHORT;         #  2
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_INT;           #  3
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_LONG;          #  4
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_FLOAT;         #  5
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_DOUBLE;        #  6
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_PTR;           #  7
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_ARRAY;         #  8
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_BOOL;          #  9
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_STRING;        #  10
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_ROW;           #  11
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_TABLE;         #  12
  $valueType = MarpaX::ESLIF::Value::Type->MARPAESLIF_VALUE_TYPE_LONG_DOUBLE;   #  13

=head1 DESCRIPTION

ESLIF values are mapped to constants. This module is giving access to them, although they have no use in the perl interface.

=head1 CONSTANTS

=head2 MARPAESLIF_VALUE_TYPE_UNDEF

Undefined value.

=head2 MARPAESLIF_VALUE_TYPE_CHAR

I<C>'s C<char>.

=head2 MARPAESLIF_VALUE_TYPE_SHORT

I<C>'s C<short>.

=head2 MARPAESLIF_VALUE_TYPE_INT

I<C>'s C<int>.

=head2 MARPAESLIF_VALUE_TYPE_LONG

I<C>'s C<long>.

=head2 MARPAESLIF_VALUE_TYPE_FLOAT

I<C>'s C<float>.

=head2 MARPAESLIF_VALUE_TYPE_DOUBLE

I<C>'s C<double>.

=head2 MARPAESLIF_VALUE_TYPE_PTR

I<C>'s C<void *>.

=head2 MARPAESLIF_VALUE_TYPE_ARRAY

I<C>'s pointer to a C<{void *, size_t}> structure.

=head2 MARPAESLIF_VALUE_TYPE_BOOL

I<C>'s C<short> where any value different than zero means a true value.

=head2 MARPAESLIF_VALUE_TYPE_STRING

A string. Encoding is contextual and depend on the action that generated that string. Lexemes that comes from a grammar running in character mode are guaranteed to be in UTF-8.

=head2 MARPAESLIF_VALUE_TYPE_ROW

An array of values.

=head2 MARPAESLIF_VALUE_TYPE_TABLE

An array of values, where number of values is even.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
