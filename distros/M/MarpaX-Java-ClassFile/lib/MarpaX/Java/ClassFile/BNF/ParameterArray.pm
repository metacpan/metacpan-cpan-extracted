use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ParameterArray;
use Moo;

# ABSTRACT: Parsing of an array of parameter

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::Parameter;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"        => sub { $_[0]->exhausted },
                        'parameter$'        => sub { $_[0]->inc_nbDone },
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _Parameter {
  # my ($self, $name_index, $access_flags) = @_;

  MarpaX::Java::ClassFile::Struct::Parameter->new(
                                                  _constant_pool => $_[0]->constant_pool,
                                                  name_index     => $_[1],
                                                  access_flags   => $_[2]
                                                 )
}

with 'MarpaX::Java::ClassFile::Role::Parser::InnerGrammar';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ParameterArray - Parsing of an array of parameter

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
event 'parameter$' = completed parameter
:default          ::= action => [values]
ParameterArray    ::= parameter*
parameter         ::= name_index access_flags action => _BootstrapMethod
name_index        ::= U2                      action => u2
access_flags      ::= U2                      action => u2
