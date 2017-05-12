use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ClassesArray;
use Moo;

# ABSTRACT: Parsing an array of class

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::Class;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted" => sub { $_[0]->exhausted },
          'class$'      => sub { $_[0]->inc_nbDone }
         }
}

sub _class {
  # my ($self, $inner_class_info_index, $outer_class_info_index, $inner_name_index, $inner_class_access_flags) = @_;

  MarpaX::Java::ClassFile::Struct::Class->new(
                                              _constant_pool           => $_[0]->constant_pool,
                                              inner_class_info_index   => $_[1],
                                              outer_class_info_index   => $_[2],
                                              inner_name_index         => $_[3],
                                              inner_class_access_flags => $_[4]
                                             )
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ClassesArray - Parsing an array of class

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
event 'class$' = completed class

classesArray ::= class*
class ::= inner_class_info_index outer_class_info_index inner_name_index inner_class_access_flags action => _class
inner_class_info_index   ::= U2 action => u2
outer_class_info_index   ::= U2 action => u2
inner_name_index         ::= U2 action => u2
inner_class_access_flags ::= U2 action => u2
