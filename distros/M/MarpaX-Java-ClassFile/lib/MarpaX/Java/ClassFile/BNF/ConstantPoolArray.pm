use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::ConstantPoolArray;
use Moo;

# ABSTRACT: Parsing an array of constant pool

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/:all/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::BNF::ConstantUtf8Info;
require MarpaX::Java::ClassFile::BNF::ConstantIntegerInfo;
require MarpaX::Java::ClassFile::BNF::ConstantFloatInfo;
require MarpaX::Java::ClassFile::BNF::ConstantLongInfo;
require MarpaX::Java::ClassFile::BNF::ConstantDoubleInfo;
require MarpaX::Java::ClassFile::BNF::ConstantClassInfo;
require MarpaX::Java::ClassFile::BNF::ConstantStringInfo;
require MarpaX::Java::ClassFile::BNF::ConstantFieldrefInfo;
require MarpaX::Java::ClassFile::BNF::ConstantMethodrefInfo;
require MarpaX::Java::ClassFile::BNF::ConstantInterfaceMethodrefInfo;
require MarpaX::Java::ClassFile::BNF::ConstantNameAndTypeInfo;
require MarpaX::Java::ClassFile::BNF::ConstantMethodHandleInfo;
require MarpaX::Java::ClassFile::BNF::ConstantMethodTypeInfo;
require MarpaX::Java::ClassFile::BNF::ConstantInvokeDynamicInfo;

use constant {
  CONSTANT_Utf8               =>  1,
  CONSTANT_Integer            =>  3,
  CONSTANT_Float              =>  4,
  CONSTANT_Long               =>  5,
  CONSTANT_Double             =>  6,
  CONSTANT_Class              =>  7,
  CONSTANT_String             =>  8,
  CONSTANT_Fieldref           =>  9,
  CONSTANT_Methodref          => 10,
  CONSTANT_InterfaceMethodref => 11,
  CONSTANT_NameAndType        => 12,
  CONSTANT_MethodHandle       => 15,
  CONSTANT_MethodType         => 16,
  CONSTANT_InvokeDynamic      => 18
};

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted" => sub { $_[0]->exhausted },
          'cpInfo$'     => sub { $_[0]->inc_nbDone },
          '^U1' => sub {
            my $tag = $_[0]->pauseU1;
            #
            # Inject a fake entry at position 0
            #
            $_[0]->lexeme_read_managed(0, 1) if (! $_[0]->nbDone);  # Last argument means ignore events => no increase on nbDone

            if    ($tag == CONSTANT_Utf8)               { $_[0]->inner('ConstantUtf8Info') }
            elsif ($tag == CONSTANT_Integer)            { $_[0]->inner('ConstantIntegerInfo') }
            elsif ($tag == CONSTANT_Float)              { $_[0]->inner('ConstantFloatInfo') }
            elsif ($tag == CONSTANT_Long)               { $_[0]->inner('ConstantLongInfo');
                                                          #
                                                          # Inject an unusable entry if this is not the last one
                                                          #
                                                          $_[0]->lexeme_read_managed if ($_[0]->nbDone < $_[0]->size)
                                                        }
            elsif ($tag == CONSTANT_Double)             { $_[0]->inner('ConstantDoubleInfo');
                                                          #
                                                          # Inject an unusable entry if this is not the last one
                                                          #
                                                          $_[0]->lexeme_read_managed if ($_[0]->nbDone < $_[0]->size)
                                                        }
            elsif ($tag == CONSTANT_Class)              { $_[0]->inner('ConstantClassInfo') }
            elsif ($tag == CONSTANT_String)             { $_[0]->inner('ConstantStringInfo') }
            elsif ($tag == CONSTANT_Fieldref)           { $_[0]->inner('ConstantFieldrefInfo') }
            elsif ($tag == CONSTANT_Methodref)          { $_[0]->inner('ConstantMethodrefInfo') }
            elsif ($tag == CONSTANT_InterfaceMethodref) { $_[0]->inner('ConstantInterfaceMethodrefInfo') }
            elsif ($tag == CONSTANT_NameAndType)        { $_[0]->inner('ConstantNameAndTypeInfo') }
            elsif ($tag == CONSTANT_MethodHandle)       { $_[0]->inner('ConstantMethodHandleInfo') }
            elsif ($tag == CONSTANT_MethodType)         { $_[0]->inner('ConstantMethodTypeInfo') }
            elsif ($tag == CONSTANT_InvokeDynamic)      { $_[0]->inner('ConstantInvokeDynamicInfo') }
            else                                        { $_[0]->fatalf('Unmanaged constant pool entry, tag=%d', $tag) }
          }
         }
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::ConstantPoolArray - Parsing an array of constant pool

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
:lexeme ~ <U1> pause => before event => '^U1'
event 'cpInfo$' = completed cpInfo

cpInfoArray ::= cpInfo*
cpInfo ::= U1
         | MANAGED          action => ::first
