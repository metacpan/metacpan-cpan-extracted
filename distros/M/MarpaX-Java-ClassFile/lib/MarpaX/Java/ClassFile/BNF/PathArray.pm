use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::PathArray;
use Moo;

# ABSTRACT: Parsing an array of path

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Carp qw/croak/;
use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::Path;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted" => sub { $_[0]->exhausted },
                        'path$'      => sub { $_[0]->inc_nbDone }
                       }
}

# ---------------
# Grammar actions
# ---------------
sub _path {
  # my ($self, $type_path_kind, $type_argument_index) = @_;

  MarpaX::Java::ClassFile::Struct::Path->new(
                                             type_path_kind      => $_[1],
                                             type_argument_index => $_[2]
                                            )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::PathArray - Parsing an array of path

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
event 'path$' = completed path
:default            ::= action => [values]
pathArray           ::= path*
path                ::= type_path_kind type_argument_index action => _path
type_path_kind      ::= U1                    action => u1
type_argument_index ::= U1                    action => u1
