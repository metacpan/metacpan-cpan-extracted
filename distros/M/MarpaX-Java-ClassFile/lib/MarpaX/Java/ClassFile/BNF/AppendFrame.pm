use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::AppendFrame;
use Moo;

# ABSTRACT: Parsing of a append_frame

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
use MarpaX::Java::ClassFile::Struct::_Types qw/U1/;
use MarpaX::Java::ClassFile::Util::ProductionMode qw/prod_isa/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::AppendFrame;
require MarpaX::Java::ClassFile::BNF::VerificationTypeInfoArray;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

has preloaded_frame_type => (is => 'ro', required => 1, prod_isa(U1));

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"    => sub { $_[0]->exhausted },
                        'offset_delta$' => sub { $_[0]->inner('VerificationTypeInfoArray', size => $_[0]->preloaded_frame_type - 251) }
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _append_frame {
  # my ($self, $frame_type, $offset_delta, $locals) = @_;

  MarpaX::Java::ClassFile::Struct::AppendFrame->new(
                                                    frame_type   => $_[1],
                                                    offset_delta => $_[2],
                                                    locals       => $_[3]
                                                   )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::AppendFrame - Parsing of a append_frame

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
event 'offset_delta$' = completed offset_delta
append_frame ::= frame_type offset_delta locals action => _append_frame
frame_type          ::= U1                      action => u1
offset_delta        ::= U2                      action => u2
locals              ::= MANAGED                 action => ::first
