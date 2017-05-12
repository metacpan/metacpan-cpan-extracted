use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::LocalVariableArray;
use Moo;

# ABSTRACT: Parsing an array of local variable

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::LocalVariable;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted"     => sub { $_[0]->exhausted  },
          'local_variable$' => sub { $_[0]->inc_nbDone }
         }
}

sub _local_variable {
  # my ($self, $start_pc, $length, $name_index, $descriptor_index, $index) = @_;

  MarpaX::Java::ClassFile::Struct::LocalVariable->new(
                                                      _constant_pool   => $_[0]->constant_pool,
                                                      start_pc         => $_[1],
                                                      length           => $_[2],
                                                      name_index       => $_[3],
                                                      descriptor_index => $_[4],
                                                      index            => $_[5]
                                                     )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::LocalVariableArray - Parsing an array of local variable

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
:default ::= action => [values]
event 'local_variable$' = completed local_variable

localVariableArray ::= local_variable*
local_variable     ::= start_pc length name_index descriptor_index index action => _local_variable
start_pc           ::= U2                                                action => u2
length             ::= U2                                                action => u2
name_index         ::= U2                                                action => u2
descriptor_index   ::= U2                                                action => u2
index              ::= U2                                                action => u2
