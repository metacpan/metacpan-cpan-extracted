use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::StackMapFrameArray;
use Moo;

# ABSTRACT: Parsing an array of stack_map_frame

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::BNF::SameFrame;
require MarpaX::Java::ClassFile::BNF::SameLocals1StackItemFrame;
require MarpaX::Java::ClassFile::BNF::SameLocals1StackItemFrameExtended;
require MarpaX::Java::ClassFile::BNF::ChopFrame;
require MarpaX::Java::ClassFile::BNF::SameFrameExtended;
require MarpaX::Java::ClassFile::BNF::AppendFrame;
require MarpaX::Java::ClassFile::BNF::FullFrame;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted"      => sub { $_[0]->exhausted },
          'stack_map_frame$' => sub { $_[0]->inc_nbDone },
          '^U1' => sub {
            my $tag = $_[0]->pauseU1;
            if    ($tag >=  0  && $tag <=  63) { $_[0]->inner('SameFrame', preloaded_frame_type => $tag) }
            elsif ($tag >= 64  && $tag <= 127) { $_[0]->inner('SameLocals1StackItemFrame', preloaded_frame_type => $tag) }
            elsif (               $tag == 247) { $_[0]->inner('SameLocals1StackItemFrameExtended', preloaded_frame_type => $tag) }
            elsif ($tag >= 248 && $tag <= 250) { $_[0]->inner('ChopFrame', preloaded_frame_type => $tag) }
            elsif (               $tag == 251) { $_[0]->inner('SameFrameExtended', preloaded_frame_type => $tag) }
            elsif ($tag >= 252 && $tag <= 254) { $_[0]->inner('AppendFrame', preloaded_frame_type => $tag) }
            elsif (               $tag == 255) { $_[0]->inner('FullFrame', preloaded_frame_type => $tag) }
            else                               { $_[0]->fatalf('Unmanaged frame type %s', $tag) }
          }
         }
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::StackMapFrameArray - Parsing an array of stack_map_frame

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
:lexeme ~ <U1> pause => before event => '^U1'
event 'stack_map_frame$' = completed stack_map_frame

stackMapFrameArray ::= stack_map_frame*
stack_map_frame    ::= U1
                     | MANAGED   action => ::first
