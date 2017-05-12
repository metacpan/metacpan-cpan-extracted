use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ElementValue;
use Moo;

# ABSTRACT: Parsing of a element_value

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

#
# Note: this union is easy, no need to subclass the BNFs
#

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::Struct::ElementValue;
require MarpaX::Java::ClassFile::BNF::ConstValueIndex;
require MarpaX::Java::ClassFile::BNF::EnumConstValue;
require MarpaX::Java::ClassFile::BNF::ClassInfoIndex;
require MarpaX::Java::ClassFile::BNF::Annotation;
require MarpaX::Java::ClassFile::BNF::ArrayValue;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------------
# What role MarpaX::Java::ClassFile::Role::Parser requires
# --------------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks { return {
                        "'exhausted"  => sub { $_[0]->exhausted },
                        'tag$'        => sub {
                          my $tag = $_[0]->literalU1('tag');
                          if    ($tag == ord('B')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('C')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('D')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('F')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('I')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('J')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('S')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('Z')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('s')) { $_[0]->inner('ConstValueIndex') }
                          elsif ($tag == ord('e')) { $_[0]->inner('EnumConstValue') }
                          elsif ($tag == ord('c')) { $_[0]->inner('ClassInfoIndex') }
                          elsif ($tag == ord('@')) { $_[0]->inner('Annotation') }
                          elsif ($tag == ord('[')) { $_[0]->inner('ArrayValue') }
                          else                { $_[0]->fatalf('Unmanaged element value tag %d', $tag) }
                        }
                       }
              }

# ---------------
# Grammar actions
# ---------------
sub _ElementValue {
  # my ($self, $tag, $value) = @_;

  MarpaX::Java::ClassFile::Struct::ElementValue->new(
                                                     tag   => $_[1],
                                                     value => $_[2]
                                                    )
}

with 'MarpaX::Java::ClassFile::Role::Parser';

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ElementValue - Parsing of a element_value

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
event 'tag$' = completed tag
ElementValue ::= tag managed action => _ElementValue
tag          ::= U1          action => u1
managed      ::= MANAGED     action => ::first
