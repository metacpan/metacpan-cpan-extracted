use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::CodeAttribute;
use Moo;

# ABSTRACT: Parsing of a Code_attribute

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::CodeAttribute;
require MarpaX::Java::ClassFile::BNF::AttributesArray;
require MarpaX::Java::ClassFile::BNF::ExceptionTableArray;
require MarpaX::Java::ClassFile::BNF::OpCodeArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"              => sub { $_[0]->exhausted },
                        'code_length$'            => sub { $_[0]->inner('OpCodeArray', originPos => $_[0]->pos, size => -1, max => $_[0]->pos + $_[0]->literalU4('code_length')) },
                        'exception_table_length$' => sub { $_[0]->inner('ExceptionTableArray', size => $_[0]->literalU2('exception_table_length')) },
                        'attributes_count$'       => sub { $_[0]->inner('AttributesArray', size => $_[0]->literalU2('attributes_count')) }
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _Code_attribute {
  # my ($self, $attribute_name_index, $attribute_length, $max_stack, $max_locals, $code_length, $code, $exception_table_length, $exception_table, $attributes_count, $attributes) = @_;

  MarpaX::Java::ClassFile::Struct::CodeAttribute->new(
                                                      _constant_pool          => $_[ 0]->constant_pool,
                                                      attribute_name_index    => $_[ 1],
                                                      attribute_length        => $_[ 2],
                                                      max_stack               => $_[ 3],
                                                      max_locals              => $_[ 4],
                                                      code_length             => $_[ 5],
                                                      code                    => $_[ 6],
                                                      exception_table_length  => $_[ 7],
                                                      exception_table         => $_[ 8],
                                                      attributes_count        => $_[ 9],
                                                      attributes              => $_[10]
                                                     )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::CodeAttribute - Parsing of a Code_attribute

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
event 'code_length$'            = completed code_length
event 'exception_table_length$' = completed exception_table_length
event 'attributes_count$'       = completed attributes_count

Code_attribute         ::= attribute_name_index attribute_length max_stack max_locals code_length code exception_table_length exception_table attributes_count attributes action => _Code_attribute
attribute_name_index   ::= U2                                                                                                                                             action => u2
attribute_length       ::= U4                                                                                                                                             action => u4
max_stack              ::= U2                                                                                                                                             action => u2
max_locals             ::= U2                                                                                                                                             action => u2
code_length            ::= U4                                                                                                                                             action => u4
code                   ::= MANAGED                                                                                                                                        action => ::first
exception_table_length ::= U2                                                                                                                                             action => u2
exception_table        ::= MANAGED                                                                                                                                        action => ::first
attributes_count       ::= U2                                                                                                                                             action => u2
attributes             ::= MANAGED                                                                                                                                        action => ::first
