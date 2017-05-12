use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::SameLocals1StackItemFrame;
use Moo;

# ABSTRACT: Parsing of a same_locals_1_stack_item_frame

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
use MarpaX::Java::ClassFile::Struct::_Types qw/U1/;
use MarpaX::Java::ClassFile::Util::ProductionMode qw/prod_isa/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::SameLocals1StackItemFrame;
require MarpaX::Java::ClassFile::BNF::VerificationTypeInfoArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

has preloaded_frame_type => (is => 'ro', required => 1, prod_isa(U1));

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"  => sub { $_[0]->exhausted },
                        'frame_type$' => sub { $_[0]->inner('VerificationTypeInfoArray', size => 1) },
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _same_locals_1_stack_item_frame {
  # my ($self, $frame_type, $stack) = @_;

  MarpaX::Java::ClassFile::Struct::SameLocals1StackItemFrame->new(
                                                                  frame_type => $_[1],
                                                                  stack      => $_[2]
                                                                 )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::SameLocals1StackItemFrame - Parsing of a same_locals_1_stack_item_frame

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
event 'frame_type$' = completed frame_type
same_locals_1_stack_item_frame ::= frame_type stack action => _same_locals_1_stack_item_frame
frame_type                     ::= U1               action => u1
stack                          ::= MANAGED          action => ::first
