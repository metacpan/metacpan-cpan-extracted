use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ExceptionsAttribute;
use Moo;

# ABSTRACT: Parsing of a Exceptions_attribute

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ExceptionsAttribute;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted" => sub { $_[0]->exhausted },
                        'number_of_exceptions$' => sub {
                          my $number_of_exceptions = $_[0]->literalU2('number_of_exceptions');
                          map { $_[0]->lexeme_read_u2(1) } (1..$number_of_exceptions); # Ignore events
                          $_[0]->lexeme_read_managed(0)                                # Will trigger exhaustion
                        }
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _Exceptions_attribute {
  # my ($self, $attribute_name_index, $attribute_length, $number_of_exceptions, $exception_index_table) = @_;

  MarpaX::Java::ClassFile::Struct::ExceptionsAttribute->new(
                                                            _constant_pool        => $_[0]->constant_pool,
                                                            attribute_name_index  => $_[1],
                                                            attribute_length      => $_[2],
                                                            number_of_exceptions  => $_[3],
                                                            exception_index_table => $_[4]
                                                           )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ExceptionsAttribute - Parsing of a Exceptions_attribute

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
event 'number_of_exceptions$' = completed number_of_exceptions
Exceptions_attribute ::= attribute_name_index attribute_length number_of_exceptions exception_index_table (end) action => _Exceptions_attribute
attribute_name_index    ::= U2                                                        action => u2
attribute_length        ::= U4                                                        action => u4
number_of_exceptions    ::= U2                                                        action => u2
exception_index_table   ::= exception_index*                                          action => [values]
exception_index         ::= U2                                                        action => u2
end                     ::= MANAGED                                                   # Used to trigger the exhaustion event
