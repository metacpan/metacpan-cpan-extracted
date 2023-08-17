use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::LocalVariableTypeArray;
use Moo;

# ABSTRACT: Parsing an array of local variable type

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::LocalVariableType;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted"          => sub { $_[0]->exhausted  },
          'local_variable_type$' => sub { $_[0]->inc_nbDone }
         }
}

sub _local_variable_type {
  # my ($self, $start_pc, $length, $name_index, $signature_index, $index) = @_;

  MarpaX::Java::ClassFile::Struct::LocalVariableType->new(
                                                          _constant_pool => $_[0]->constant_pool,
                                                          start_pc        => $_[1],
                                                          length          => $_[2],
                                                          name_index      => $_[3],
                                                          signature_index => $_[4],
                                                          index           => $_[5]
                                                         )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::LocalVariableTypeArray - Parsing an array of local variable type

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
event 'local_variable_type$' = completed local_variable_type

localVariableTypeArray ::= local_variable_type*
local_variable_type     ::= start_pc length name_index signature_index index action => _local_variable_type
start_pc                ::= U2                                               action => u2
length                  ::= U2                                               action => u2
name_index              ::= U2                                               action => u2
signature_index         ::= U2                                               action => u2
index                   ::= U2                                               action => u2
