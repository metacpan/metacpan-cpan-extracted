use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ClassInfoIndex;
use Moo;

# ABSTRACT: Parsing of a class_info_index

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ClassInfoIndex;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"  => sub { $_[0]->exhausted },
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _ClassInfoIndex {
  # my ($self, $const_value_index) = @_;

  MarpaX::Java::ClassFile::Struct::ClassInfoIndex->new(
                                                       _constant_pool   => $_[0]->constant_pool,
                                                       class_info_index => $_[1]
                                                      )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ClassInfoIndex - Parsing of a class_info_index

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
ClassInfoIndex   ::= class_info_index action => _ClassInfoIndex
class_info_index ::= U2               action => u2
