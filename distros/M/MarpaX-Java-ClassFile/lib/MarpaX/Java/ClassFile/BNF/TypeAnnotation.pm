use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::TypeAnnotation;
use Moo;

# ABSTRACT: Parsing of a type_annotation

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

#
# Note: this union is easy, no need to subclass the BNFs
#

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::TypeAnnotation;
require MarpaX::Java::ClassFile::BNF::TypeParameterTarget;
require MarpaX::Java::ClassFile::BNF::SupertypeTarget;
require MarpaX::Java::ClassFile::BNF::TypeParameterBoundTarget;
# require MarpaX::Java::ClassFile::BNF::EmptyTarget;                   Special case: nothing to parse
require MarpaX::Java::ClassFile::Struct::EmptyTarget;
require MarpaX::Java::ClassFile::BNF::FormalParameterTarget;
require MarpaX::Java::ClassFile::BNF::ThrowsTarget;
require MarpaX::Java::ClassFile::BNF::LocalvarTarget;
require MarpaX::Java::ClassFile::BNF::CatchTarget;
require MarpaX::Java::ClassFile::BNF::OffsetTarget;
require MarpaX::Java::ClassFile::BNF::TypeArgumentTarget;
require MarpaX::Java::ClassFile::BNF::TypePath;
require MarpaX::Java::ClassFile::BNF::ElementValuePairArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"   => sub { $_[0]->exhausted },
                        'target_type$' => sub {
                          my $target_type = $_[0]->literalU1('target_type');
                          if    ($target_type == 0x00) { $_[0]->inner('TypeParameterTarget') }
                          elsif ($target_type == 0x01) { $_[0]->inner('TypeParameterTarget') }
                          elsif ($target_type == 0x10) { $_[0]->inner('SupertypeTarget') }
                          elsif ($target_type == 0x11) { $_[0]->inner('TypeParameterBoundTarget') }
                          elsif ($target_type == 0x12) { $_[0]->inner('TypeParameterBoundTarget') }
                          elsif ($target_type == 0x13) { $_[0]->lexeme_read('MANAGED', 0, MarpaX::Java::ClassFile::Struct::EmptyTarget->new) }
                          elsif ($target_type == 0x14) { $_[0]->lexeme_read('MANAGED', 0, MarpaX::Java::ClassFile::Struct::EmptyTarget->new) }
                          elsif ($target_type == 0x15) { $_[0]->lexeme_read('MANAGED', 0, MarpaX::Java::ClassFile::Struct::EmptyTarget->new) }
                          elsif ($target_type == 0x16) { $_[0]->inner('FormalParameterTarget') }
                          elsif ($target_type == 0x17) { $_[0]->inner('ThrowsTarget') }
                          elsif ($target_type == 0x40) { $_[0]->inner('LocalvarTarget') }
                          elsif ($target_type == 0x41) { $_[0]->inner('LocalvarTarget') }
                          elsif ($target_type == 0x42) { $_[0]->inner('CatchTarget') }
                          elsif ($target_type == 0x43) { $_[0]->inner('OffsetTarget') }
                          elsif ($target_type == 0x44) { $_[0]->inner('OffsetTarget') }
                          elsif ($target_type == 0x45) { $_[0]->inner('OffsetTarget') }
                          elsif ($target_type == 0x46) { $_[0]->inner('OffsetTarget') }
                          elsif ($target_type == 0x47) { $_[0]->inner('TypeArgumentTarget') }
                          elsif ($target_type == 0x48) { $_[0]->inner('TypeArgumentTarget') }
                          elsif ($target_type == 0x49) { $_[0]->inner('TypeArgumentTarget') }
                          elsif ($target_type == 0x4A) { $_[0]->inner('TypeArgumentTarget') }
                          elsif ($target_type == 0x4B) { $_[0]->inner('TypeArgumentTarget') }
                          else                         { $_[0]->fatalf('Unmanaged target tye %d', $target_type) }
                        },
                        '^target_path' => sub {
                          $_[0]->inner('TypePath')
                        },
                        'num_element_value_pairs$' => sub {
                          $_[0]->inner('ElementValuePairArray', size => $_[0]->literalU2('num_element_value_pairs'))
                        }
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _typeAnnotation {
  # my ($self, $target_type, $target_info, $target_path, $type_index, $num_element_value_pairs, $element_value_pairs) = @_;

  MarpaX::Java::ClassFile::Struct::TypeAnnotation->new(
                                                       _constant_pool           => $_[0]->constant_pool,
                                                       target_type              => $_[1],
                                                       target_info              => $_[2],
                                                       target_path              => $_[3],
                                                       type_index               => $_[4],
                                                       num_element_value_pairs  => $_[5],
                                                       element_value_pairs      => $_[6]
                                                    )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::TypeAnnotation - Parsing of a type_annotation

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
event 'target_type$'             = completed target_type
event '^target_path'             = predicted target_path
event 'num_element_value_pairs$' = completed num_element_value_pairs
type_annotation         ::= target_type target_info target_path type_index num_element_value_pairs action => _typeAnnotation
target_type             ::= U1                                                                     action => u1
target_info             ::= MANAGED                                                                action => ::first
target_path             ::= MANAGED                                                                action => ::first
type_index              ::= U2                                                                     action => u2
num_element_value_pairs ::= U2
element_value_pairs     ::= MANAGED                                                                action => ::first
