use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ConstantLongInfo;
use Moo;

# ABSTRACT: Parsing of a CONSTANT_Long_info

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ConstantLongInfo;

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
sub _ConstantLongInfo {
  # my ($self, $tag, $high_bytes, $low_bytes) = @_;

  MarpaX::Java::ClassFile::Struct::ConstantLongInfo->new(
                                                         tag        => $_[1],
                                                         high_bytes => $_[2],
                                                         low_bytes  => $_[3],
                                                         _perlvalue => $_[0]->long($_[2], $_[3])
                                                        )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ConstantLongInfo - Parsing of a CONSTANT_Long_info

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
ConstantLongInfo ::= tag U4 U4 action => _ConstantLongInfo
tag              ::= [\x{05}]  action => u1
