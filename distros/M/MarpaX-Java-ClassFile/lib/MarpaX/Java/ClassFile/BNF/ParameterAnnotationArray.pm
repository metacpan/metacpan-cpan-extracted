use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ParameterAnnotationArray;
use Moo;

# ABSTRACT: Parsing an array of parameter_annotation

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::BNF::ParameterAnnotation;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted"               => sub { $_[0]->exhausted },
          '^parameterAnnotationArray' => sub {
            foreach (1..$_[0]->size) {
              $_[0]->inner_silent('ParameterAnnotation');
              $_[0]->inc_nbDone
            }
          }
         }
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ParameterAnnotationArray - Parsing an array of parameter_annotation

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
event '^parameterAnnotationArray' = predicted parameterAnnotationArray

parameterAnnotationArray ::= MANAGED*
