use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::TableArray;
use Moo;

# ABSTRACT: Parsing an array of table

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Carp qw/croak/;
use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::Table;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted" => sub { $_[0]->exhausted },
                        'table$'     => sub { $_[0]->inc_nbDone }
                       }
}

# ---------------
# Grammar actions
# ---------------
sub _table {
  # my ($self, $start_pc, $length, $index) = @_;

  MarpaX::Java::ClassFile::Struct::Table->new(
                                              start_pc => $_[1],
                                              length   => $_[2],
                                              index    => $_[3]
                                             )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::TableArray - Parsing an array of table

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
:default   ::= action => [values]
event 'table$' = completed table
tableArray ::= table*
table      ::= start_pc length index action => _table
start_pc   ::= U2                    action => u2
length     ::= U2                    action => u2
index      ::= U2                    action => u2
