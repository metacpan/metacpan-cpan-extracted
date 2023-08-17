use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ConstantMethodTypeInfo;
use Moo;

# ABSTRACT: Parsing of a CONSTANT_MethodType_info

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ConstantMethodTypeInfo;

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
sub _ConstantMethodTypeInfo {
  # my ($self, $tag, $descriptor_index) = @_;

  MarpaX::Java::ClassFile::Struct::ConstantMethodTypeInfo->new(
                                                               _constant_pool  => $_[0]->constant_pool,
                                                               tag              => $_[1],
                                                               descriptor_index => $_[2]
                                                             )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ConstantMethodTypeInfo - Parsing of a CONSTANT_MethodType_info

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
ConstantMethodTypeInfo ::= tag descriptor_index action => _ConstantMethodTypeInfo
tag                    ::= [\x{0a}]             action => u1
descriptor_index       ::= U2                   action => u2
