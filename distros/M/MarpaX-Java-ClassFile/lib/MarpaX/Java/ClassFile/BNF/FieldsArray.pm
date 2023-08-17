use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::FieldsArray;
use Moo;

# ABSTRACT: Parsing an array of field

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::FieldInfo;
require MarpaX::Java::ClassFile::BNF::AttributesArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted" => sub { $_[0]->exhausted },
          'field_info$' => sub { $_[0]->inc_nbDone },
          'attributes_count$' => sub { $_[0]->inner('AttributesArray', size => $_[0]->literalU2('attributes_count')) }
         }
}

sub _field_info {
  my ($self, $access_flags, $name_index, $descriptor_index, $attributes_count, $attributes) = @_;

  MarpaX::Java::ClassFile::Struct::FieldInfo->new(
                                                  _constant_pool   => $_[0]->constant_pool,
                                                  access_flags     => $access_flags,
                                                  name_index       => $name_index,
                                                  descriptor_index => $descriptor_index,
                                                  attributes_count => $attributes_count,
                                                  attributes       => $attributes
                                                 )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::FieldsArray - Parsing an array of field

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
:default ::= action => [values]
event 'attributes_count$' = completed attributes_count
event 'field_info$' = completed field_info

fieldsArray ::= field_info*

field_info ::= access_flags name_index descriptor_index attributes_count attributes action => _field_info
access_flags     ::= U2                                                             action => u2
name_index       ::= U2                                                             action => u2
descriptor_index ::= U2                                                             action => u2
attributes_count ::= U2                                                             action => u2
attributes       ::= MANAGED                                                        action => ::first
