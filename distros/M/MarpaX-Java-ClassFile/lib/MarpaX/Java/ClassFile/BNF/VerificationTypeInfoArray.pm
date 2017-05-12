use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::VerificationTypeInfoArray;
use Moo;

# ABSTRACT: Parsing of a verification_type_info

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
require MarpaX::Java::ClassFile::Struct::TopVariableInfo;
require MarpaX::Java::ClassFile::Struct::IntegerVariableInfo;
require MarpaX::Java::ClassFile::Struct::FloatVariableInfo;
require MarpaX::Java::ClassFile::Struct::NullVariableInfo;
require MarpaX::Java::ClassFile::Struct::UninitializedThisVariableInfo;
require MarpaX::Java::ClassFile::Struct::ObjectVariableInfo;
require MarpaX::Java::ClassFile::Struct::UninitializedVariableInfo;
require MarpaX::Java::ClassFile::Struct::LongVariableInfo;
require MarpaX::Java::ClassFile::Struct::DoubleVariableInfo;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"              => sub { $_[0]->exhausted },
                        'verification_type_info$' => sub { $_[0]->inc_nbDone },
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _Top_variable_info {
  # my ($self, $tag) = @_;

  MarpaX::Java::ClassFile::Struct::TopVariableInfo->new(
                                                        tag => $_[0]->u1($_[1])
                                                       )
}

sub _Integer_variable_info {
  # my ($self, $tag) = @_;

  MarpaX::Java::ClassFile::Struct::IntegerVariableInfo->new(
                                                            tag => $_[0]->u1($_[1])
                                                           )
}

sub _Float_variable_info {
  # my ($self, $tag) = @_;

  MarpaX::Java::ClassFile::Struct::FloatVariableInfo->new(
                                                          tag => $_[0]->u1($_[1])
                                                         )
}

sub _Null_variable_info {
  # my ($self, $tag) = @_;

  MarpaX::Java::ClassFile::Struct::NullVariableInfo->new(
                                                         tag => $_[0]->u1($_[1])
                                                        )
}

sub _UninitializedThis_variable_info {
  # my ($self, $tag) = @_;

  MarpaX::Java::ClassFile::Struct::UninitializedThisVariableInfo->new(
                                                                      tag => $_[0]->u1($_[1])
                                                                     )
}

sub _Object_variable_info {
  # my ($self, $tag, $cpool_index) = @_;

  MarpaX::Java::ClassFile::Struct::ObjectVariableInfo->new(
                                                           _constant_pool => $_[0]->constant_pool,
                                                           tag            => $_[0]->u1($_[1]),
                                                           cpool_index    => $_[0]->u2($_[2])
                                                          )
}

sub _Uninitialized_variable_info {
  # my ($self, $tag, $cpool_index) = @_;

  MarpaX::Java::ClassFile::Struct::UninitializedVariableInfo->new(
                                                                  tag    => $_[0]->u1($_[1]),
                                                                  offset => $_[0]->u2($_[2])
                                                                 )
}

sub _Long_variable_info {
  # my ($self, $tag) = @_;

  MarpaX::Java::ClassFile::Struct::LongVariableInfo->new(
                                                         tag => $_[0]->u1($_[1])
                                                        )
}

sub _Double_variable_info {
  # my ($self, $tag) = @_;

  MarpaX::Java::ClassFile::Struct::DoubleVariableInfo->new(
                                                           tag => $_[0]->u1($_[1])
                                                          )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::VerificationTypeInfoArray - Parsing of a verification_type_info

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
:default ::= action => ::first
event 'verification_type_info$' = completed verification_type_info
VerificationTypeInfoArray ::= verification_type_info*   action => [values]
verification_type_info          ::= Top_variable_info
                                  | Integer_variable_info
                                  | Float_variable_info
                                  | Null_variable_info
                                  | UninitializedThis_variable_info
                                  | Object_variable_info
                                  | Uninitialized_variable_info
                                  | Long_variable_info
                                  | Double_variable_info
Top_variable_info               ::= [\x{00}]     action => _Top_variable_info
Integer_variable_info           ::= [\x{01}]     action => _Integer_variable_info
Float_variable_info             ::= [\x{02}]     action => _Float_variable_info
Null_variable_info              ::= [\x{05}]     action => _Null_variable_info
UninitializedThis_variable_info ::= [\x{06}]     action => _UninitializedThis_variable_info
Object_variable_info            ::= [\x{07}] U2  action => _Object_variable_info
Uninitialized_variable_info     ::= [\x{08}] U2  action => _Uninitialized_variable_info
Long_variable_info              ::= [\x{04}]     action => _Long_variable_info
Double_variable_info            ::= [\x{03}]     action => _Double_variable_info
