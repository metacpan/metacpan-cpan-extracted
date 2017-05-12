use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::FullFrame;
use Moo;

# ABSTRACT: Parsing of a full_frame

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
require MarpaX::Java::ClassFile::Struct::FullFrame;
require MarpaX::Java::ClassFile::BNF::VerificationTypeInfoArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

has preloaded_frame_type => (is => 'ro', required => 1, prod_isa(U1));

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"             => sub { $_[0]->exhausted },
                        'number_of_locals$'      => sub { $_[0]->inner('VerificationTypeInfoArray', size => $_[0]->literalU2('number_of_locals')) },
                        'number_of_stack_items$' => sub { $_[0]->inner('VerificationTypeInfoArray', size => $_[0]->literalU2('number_of_stack_items')) }
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _full_frame {
  # my ($self, $frame_type, $offset_delta, $number_of_locals, $locals, $number_of_stack_items, $stack) = @_;

  MarpaX::Java::ClassFile::Struct::FullFrame->new(
                                                  frame_type            => $_[1],
                                                  offset_delta          => $_[2],
                                                  number_of_locals      => $_[3],
                                                  locals                => $_[4],
                                                  number_of_stack_items => $_[5],
                                                  stack                 => $_[6]
                                                 )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::FullFrame - Parsing of a full_frame

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
event 'number_of_locals$'      = completed number_of_locals
event 'number_of_stack_items$' = completed number_of_stack_items
full_frame            ::= frame_type offset_delta number_of_locals locals number_of_stack_items stack action => _full_frame
frame_type            ::= U1                                                                          action => u1
offset_delta          ::= U2                                                                          action => u2
number_of_locals      ::= U2                                                                          action => u2
locals                ::= MANAGED                                                                     action => ::first
number_of_stack_items ::= U2                                                                          action => u2
stack                 ::= MANAGED                                                                     action => ::first
