use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::BootstrapMethodsAttribute;
use Moo;

# ABSTRACT: Parsing of a BootstrapMethods_attribute

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::BootstrapMethodsAttribute;
require MarpaX::Java::ClassFile::BNF::BootstrapMethodArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
          "'exhausted"             => sub { $_[0]->exhausted },
          'num_bootstrap_methods$' => sub { $_[0]->inner('BootstrapMethodArray', size => $_[0]->literalU2('num_bootstrap_methods')) }
         }
}

# ---------------
# Grammar actions
# ---------------
sub _BootstrapMethodsAttribute {
  # my ($self, $attribute_name_index, $attribute_length, $num_bootstrap_methods, $bootstrap_methods) = @_;

  MarpaX::Java::ClassFile::Struct::BootstrapMethodsAttribute->new(
                                                                  _constant_pool        => $_[0]->constant_pool,
                                                                  attribute_name_index  => $_[1],
                                                                  attribute_length      => $_[2],
                                                                  num_bootstrap_methods => $_[3],
                                                                  bootstrap_methods     => $_[4]
                                                                 )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::BootstrapMethodsAttribute - Parsing of a BootstrapMethods_attribute

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ bnf ]__
BootstrapMethodsAttribute  ::= attribute_name_index attribute_length num_bootstrap_methods bootstrap_methods action => _BootstrapMethodsAttribute
attribute_name_index       ::= U2                                                  action => u2
attribute_length           ::= U4                                                  action => u4
num_bootstrap_methods      ::= U2                                                  action => u2
bootstrap_methods          ::= MANAGED                                             action => ::first
