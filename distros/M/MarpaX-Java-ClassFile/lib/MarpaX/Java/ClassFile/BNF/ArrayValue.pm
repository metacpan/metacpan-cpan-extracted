use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ArrayValue;
use Moo;

# ABSTRACT: Parsing of an array value

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ArrayValue;
require MarpaX::Java::ClassFile::BNF::ElementValueArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted" => sub { $_[0]->exhausted },
          'num_values$' => sub { $_[0]->inner('ElementValueArray', size => $_[0]->literalU2('num_values')) }
         }
}

sub _ArrayValue {
  # my ($self, $num_values, $values) = @_;

  MarpaX::Java::ClassFile::Struct::ArrayValue->new(
                                                   num_values => $_[1],
                                                   values     => $_[2]
                                                  )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ArrayValue - Parsing of an array value

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ bnf ]__
event 'num_values$' = completed num_values

ArrayValue ::= num_values values action => _ArrayValue
num_values ::= U2                action => u2
values     ::= MANAGED           action => ::first
