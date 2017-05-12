use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::BNF::AttributesArray;
use Moo;

# ABSTRACT: Parsing an array of attribute

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Carp qw/croak/;
use Data::Section -setup;
use MarpaX::Java::ClassFile::Util::BNF qw/bnf/;
use Scalar::Util qw/blessed/;
#
# require because we do not import ANYTHING from these module, just require they are loaded
#
require Marpa::R2;
require MarpaX::Java::ClassFile::BNF::ConstantValueAttribute;
require MarpaX::Java::ClassFile::BNF::CodeAttribute;
require MarpaX::Java::ClassFile::BNF::StackMapTableAttribute;
require MarpaX::Java::ClassFile::BNF::ExceptionsAttribute;
require MarpaX::Java::ClassFile::BNF::InnerClassesAttribute;
require MarpaX::Java::ClassFile::BNF::EnclosingMethodAttribute;
require MarpaX::Java::ClassFile::BNF::SyntheticAttribute;
require MarpaX::Java::ClassFile::BNF::SignatureAttribute;
require MarpaX::Java::ClassFile::BNF::SourceFileAttribute;
require MarpaX::Java::ClassFile::BNF::SourceDebugExtensionAttribute;
require MarpaX::Java::ClassFile::BNF::LineNumberTableAttribute;
require MarpaX::Java::ClassFile::BNF::LocalVariableTableAttribute;
require MarpaX::Java::ClassFile::BNF::LocalVariableTypeTableAttribute;
require MarpaX::Java::ClassFile::BNF::DeprecatedAttribute;
require MarpaX::Java::ClassFile::BNF::RuntimeVisibleAnnotationsAttribute;
require MarpaX::Java::ClassFile::BNF::RuntimeInvisibleAnnotationsAttribute;
require MarpaX::Java::ClassFile::BNF::RuntimeVisibleParameterAnnotationsAttribute;
require MarpaX::Java::ClassFile::BNF::RuntimeInvisibleParameterAnnotationsAttribute;
require MarpaX::Java::ClassFile::BNF::RuntimeVisibleTypeAnnotationsAttribute;
require MarpaX::Java::ClassFile::BNF::RuntimeInvisibleTypeAnnotationsAttribute;
require MarpaX::Java::ClassFile::BNF::AnnotationDefaultAttribute;
require MarpaX::Java::ClassFile::BNF::BootstrapMethodsAttribute;
require MarpaX::Java::ClassFile::BNF::MethodParametersAttribute;
require MarpaX::Java::ClassFile::BNF::UnmanagedAttribute;

my $_data      = ${ __PACKAGE__->section_data('bnf') };
my $_grammar   = Marpa::R2::Scanless::G->new( { source => \__PACKAGE__->bnf($_data) } );

# --------------------------------------------------
# What role MarpaX::Java::ClassFile::Common requires
# --------------------------------------------------
sub grammar   { $_grammar    }
sub callbacks {
  return {
           "'exhausted" => sub { $_[0]->exhausted },
          'attribute_info$' => sub { $_[0]->inc_nbDone },
          '^U2' => sub {
            #
            # There is a subtility here: All known attributes DO fit in the ASCII table.
            # From perl point of view, input is a sequence of Bytes, which is Str compatible.
            # There is no need to do modified UTF-8 to Perl's UTF8 conversion when we want
            # to check that a sequence of Bytes is equal to a Str Containing only ASCII things,
            # because ASCII characters all fit in a single byte.
            #
            my $u2 = $_[0]->pauseU2;
            my $attribute_name = '';
            if (($u2 >= 1) && ($u2 <= $_[0]->constant_pool_count)) {
              my $constant = $_[0]->constant_pool->[$u2];
              my $blessed = blessed($constant) // '';
              if ($blessed eq 'MarpaX::Java::ClassFile::Struct::ConstantUtf8Info') {
                $attribute_name = $constant->bytes;
              }
            }
            if    ($attribute_name eq 'ConstantValue')                        { $_[0]->inner('ConstantValueAttribute') }
            elsif ($attribute_name eq 'Code')                                 { $_[0]->inner('CodeAttribute') }
            elsif ($attribute_name eq 'StackMapTable')                        { $_[0]->inner('StackMapTableAttribute') }
            elsif ($attribute_name eq 'Exceptions')                           { $_[0]->inner('ExceptionsAttribute') }
            elsif ($attribute_name eq 'InnerClasses')                         { $_[0]->inner('InnerClassesAttribute') }
            elsif ($attribute_name eq 'EnclosingMethod')                      { $_[0]->inner('EnclosingMethodAttribute') }
            elsif ($attribute_name eq 'Synthetic')                            { $_[0]->inner('SyntheticAttribute') }
            elsif ($attribute_name eq 'Signature')                            { $_[0]->inner('SignatureAttribute') }
            elsif ($attribute_name eq 'SourceFile')                           { $_[0]->inner('SourceFileAttribute') }
            elsif ($attribute_name eq 'SourceDebugExtension')                 { $_[0]->inner('SourceDebugExtensionAttribute') }
            elsif ($attribute_name eq 'LineNumberTable')                      { $_[0]->inner('LineNumberTableAttribute') }
            elsif ($attribute_name eq 'LocalVariableTable')                   { $_[0]->inner('LocalVariableTableAttribute') }
            elsif ($attribute_name eq 'LocalVariableTypeTable')               { $_[0]->inner('LocalVariableTypeTableAttribute') }
            elsif ($attribute_name eq 'Deprecated')                           { $_[0]->inner('DeprecatedAttribute') }
            elsif ($attribute_name eq 'RuntimeVisibleAnnotations')            { $_[0]->inner('RuntimeVisibleAnnotationsAttribute') }
            elsif ($attribute_name eq 'RuntimeInvisibleAnnotations')          { $_[0]->inner('RuntimeInvisibleAnnotationsAttribute') }
            elsif ($attribute_name eq 'RuntimeVisibleParameterAnnotations')   { $_[0]->inner('RuntimeVisibleParameterAnnotationsAttribute') }
            elsif ($attribute_name eq 'RuntimeInvisibleParameterAnnotations') { $_[0]->inner('RuntimeInvisibleParameterAnnotationsAttribute') }
            elsif ($attribute_name eq 'RuntimeVisibleTypeAnnotations')        { $_[0]->inner('RuntimeVisibleTypeAnnotationsAttribute') }
            elsif ($attribute_name eq 'RuntimeInvisibleTypeAnnotations')      { $_[0]->inner('RuntimeInvisibleTypeAnnotationsAttribute') }
            elsif ($attribute_name eq 'AnnotationDefault')                    { $_[0]->inner('AnnotationDefaultAttribute') }
            elsif ($attribute_name eq 'BootstrapMethods')                     { $_[0]->inner('BootstrapMethodsAttribute') }
            elsif ($attribute_name eq 'MethodParameters')                     { $_[0]->inner('MethodParametersAttribute') }
            else {
              $_[0]->infof('Unmanaged attribute %s', $attribute_name);
              $_[0]->inner('UnmanagedAttribute')
            }
          }
         }
}

with qw/MarpaX::Java::ClassFile::Role::Parser::InnerGrammar/;

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::BNF::AttributesArray - Parsing an array of attribute

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
:lexeme ~ <U2> pause => before event => '^U2'
event 'attribute_info$' = completed attribute_info

attributesArray ::= attribute_info*
attribute_info ::= U2
                 | MANAGED   action => ::first
