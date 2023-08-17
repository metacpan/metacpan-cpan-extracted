use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ElementValuePairArray;
use Moo;

# ABSTRACT: Parsing an array of element value pair

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ElementValuePair;
require MarpaX::Java::ClassFile::BNF::ElementValue;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted"         => sub { $_[0]->exhausted },
          'element_value_pair$' => sub { $_[0]->inc_nbDone },
          'element_name_index$' => sub { $_[0]->inner('ElementValue') }
         }
}

sub _element_value_pair {
  # my ($self, $element_name_index, $value) = @_;

  MarpaX::Java::ClassFile::Struct::ElementValuePair->new(
                                                         _constant_pool      => $_[0]->constant_pool,
                                                         element_name_index  => $_[1],
                                                         value               => $_[2]
                                                        )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ElementValuePairArray - Parsing an array of element value pair

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
event 'element_value_pair$' = completed element_value_pair
event 'element_name_index$' = completed element_name_index

elementValuePairArray ::= element_value_pair*

element_value_pair ::= element_name_index value action => _element_value_pair
element_name_index ::= U2                       action => u2
value              ::= MANAGED                  action => ::first
