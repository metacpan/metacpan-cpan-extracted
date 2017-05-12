use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ConstantInvokeDynamicInfo;
use Moo;

# ABSTRACT: Parsing of a CONSTANT_InvokeDynamic_info

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ConstantInvokeDynamicInfo;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return { "'exhausted" => sub { $_[0]->exhausted } } }

# ---------------
# Grammar actions
# ---------------
sub _ConstantInvokeDynamicInfo {
  # my ($self, $tag, $class_index, $name_and_type_index) = @_;

  MarpaX::Java::ClassFile::Struct::ConstantInvokeDynamicInfo->new(
                                                             _constant_pool               => $_[0]->constant_pool,
                                                              tag                         => $_[1],
                                                              bootstrap_method_attr_index => $_[2],
                                                              name_and_type_index         => $_[3]
                                                             )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ConstantInvokeDynamicInfo - Parsing of a CONSTANT_InvokeDynamic_info

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
ConstantInvokeDynamicInfo   ::= tag bootstrap_method_attr_index name_and_type_index action => _ConstantInvokeDynamicInfo
tag                         ::= [\x{12}]                                            action => u1
bootstrap_method_attr_index ::= U2                                                  action => u2
name_and_type_index         ::= U2                                                  action => u2
