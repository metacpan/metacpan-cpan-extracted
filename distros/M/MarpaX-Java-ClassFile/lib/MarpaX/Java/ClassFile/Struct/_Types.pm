use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::_Types;
use Types::Common::Numeric qw/PositiveInt/;

# ABSTRACT: Type helpers

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Type::Library
  -base,
  -declare => qw/
                  U1 U2 U4
                  ClassFile

                  ConstantClassInfo
                  ConstantFieldrefInfo
                  ConstantMethodrefInfo
                  ConstantInterfaceMethodrefInfo
                  ConstantStringInfo
                  ConstantIntegerInfo
                  ConstantFloatInfo
                  ConstantLongInfo
                  ConstantDoubleInfo
                  ConstantNameAndTypeInfo
                  ConstantUtf8Info
                  ConstantMethodHandleInfo
                  ConstantMethodTypeInfo
                  ConstantInvokeDynamicInfo
                  CpInfo

                  FieldInfo
                  MethodInfo

                  AttributeInfo
                  UnmanagedAttribute
                  ConstantValueAttribute
                  CodeAttribute
                  StackMapTableAttribute
                  ExceptionsAttribute
                  InnerClassesAttribute
                  EnclosingMethodAttribute
                  SyntheticAttribute
                  SignatureAttribute
                  SourceFileAttribute
                  SourceDebugExtensionAttribute
                  LineNumberTableAttribute
                  LocalVariableTableAttribute
                  LocalVariableTypeTableAttribute
                  DeprecatedAttribute
                  RuntimeVisibleAnnotationsAttribute
                  RuntimeInvisibleAnnotationsAttribute
                  RuntimeVisibleParameterAnnotationsAttribute
                  RuntimeInvisibleParameterAnnotationsAttribute
                  RuntimeVisibleTypeAnnotationsAttribute
                  RuntimeInvisibleTypeAnnotationsAttribute
                  AnnotationDefaultAttribute
                  BootstrapMethodsAttribute
                  MethodParametersAttribute

                  ExceptionTable

                  SameFrame
                  SameLocals1StackItemFrame
                  SameLocals1StackItemFrameExtended
                  ChopFrame
                  SameFrameExtended
                  AppendFrame
                  FullFrame
                  StackMapFrame

                  TopVariableInfo
                  IntegerVariableInfo
                  FloatVariableInfo
                  NullVariableInfo
                  UninitializedThisVariableInfo
                  ObjectVariableInfo
                  UninitializedVariableInfo
                  LongVariableInfo
                  DoubleVariableInfo
                  VerificationTypeInfo

                  LineNumber
                  LocalVariable
                  LocalVariableType
                  Annotation

                  ConstValueIndex
                  EnumConstValue
                  ClassInfoIndex
                  ArrayValue
                  ElementValuePair
                  ElementValue

                  ParameterAnnotation

                  TypeParameterTarget
                  SupertypeTarget
                  TypeParameterBoundTarget
                  EmptyTarget
                  FormalParameterTarget
                  ThrowsTarget
                  LocalvarTarget
                  CatchTarget
                  OffsetTarget
                  TypeArgumentTarget
                  TargetInfo

                  Table

                  TypeAnnotation

                  Path
                  TypePath

                  BootstrapMethod
                  Parameter

                  OpCode
                /;
use Type::Utils qw/declare as where inline_as class_type/;
use Types::Standard qw/Int Undef/;

declare U1, as Int, where { ($_ >= 0) && ($_ <= 255)   },      inline_as { my $varname = $_[1]; "($varname >= 0) && ($varname <= 255)"   };
declare U2, as Int, where { ($_ >= 0) && ($_ <= 65535) },      inline_as { my $varname = $_[1]; "($varname >= 0) && ($varname <= 65535)" };
declare U4, as Int, where { ($_ >= 0) && ($_ <= 4294967295) }, inline_as { my $varname = $_[1]; "($varname >= 0) && ($varname <= 4294967295)" };

class_type ClassFile,                      { class => 'MarpaX::Java::ClassFile::Struct::ClassFile' };
class_type ConstantClassInfo,              { class => 'MarpaX::Java::ClassFile::Struct::ConstantClassInfo' };
class_type ConstantFieldrefInfo,           { class => 'MarpaX::Java::ClassFile::Struct::ConstantFieldrefInfo' };
class_type ConstantMethodrefInfo,          { class => 'MarpaX::Java::ClassFile::Struct::ConstantMethodrefInfo' };
class_type ConstantInterfaceMethodrefInfo, { class => 'MarpaX::Java::ClassFile::Struct::ConstantInterfaceMethodrefInfo' };
class_type ConstantStringInfo,             { class => 'MarpaX::Java::ClassFile::Struct::ConstantStringInfo' };
class_type ConstantIntegerInfo,            { class => 'MarpaX::Java::ClassFile::Struct::ConstantIntegerInfo' };
class_type ConstantFloatInfo,              { class => 'MarpaX::Java::ClassFile::Struct::ConstantFloatInfo' };
class_type ConstantLongInfo,               { class => 'MarpaX::Java::ClassFile::Struct::ConstantLongInfo' };
class_type ConstantDoubleInfo,             { class => 'MarpaX::Java::ClassFile::Struct::ConstantDoubleInfo' };
class_type ConstantNameAndTypeInfo,        { class => 'MarpaX::Java::ClassFile::Struct::ConstantNameAndTypeInfo' };
class_type ConstantUtf8Info,               { class => 'MarpaX::Java::ClassFile::Struct::ConstantUtf8Info' };
class_type ConstantMethodHandleInfo,       { class => 'MarpaX::Java::ClassFile::Struct::ConstantMethodHandleInfo' };
class_type ConstantMethodTypeInfo,         { class => 'MarpaX::Java::ClassFile::Struct::ConstantMethodTypeInfo' };
class_type ConstantInvokeDynamicInfo,      { class => 'MarpaX::Java::ClassFile::Struct::ConstantInvokeDynamicInfo' };
declare CpInfo, as
  ConstantClassInfo             |
  ConstantFieldrefInfo          |
  ConstantMethodrefInfo         |
  ConstantInterfaceMethodrefInfo|
  ConstantStringInfo            |
  ConstantIntegerInfo           |
  ConstantFloatInfo             |
  ConstantLongInfo              |
  ConstantDoubleInfo            |
  ConstantNameAndTypeInfo       |
  ConstantUtf8Info              |
  ConstantMethodHandleInfo      |
  ConstantMethodTypeInfo        |
  ConstantInvokeDynamicInfo     |
  Undef                                       # Because an index in constant_pool can be valid but unusable
;

class_type FieldInfo,     { class => 'MarpaX::Java::ClassFile::Struct::FieldInfo' };
class_type MethodInfo,    { class => 'MarpaX::Java::ClassFile::Struct::MethodInfo' };

class_type UnmanagedAttribute,                            { class => 'MarpaX::Java::ClassFile::Struct::UnmanagedAttribute' };
class_type ConstantValueAttribute,                        { class => 'MarpaX::Java::ClassFile::Struct::ConstantValueAttribute' };
class_type CodeAttribute,                                 { class => 'MarpaX::Java::ClassFile::Struct::CodeAttribute' };
class_type StackMapTableAttribute,                        { class => 'MarpaX::Java::ClassFile::Struct::StackMapTableAttribute' };
class_type ExceptionsAttribute,                           { class => 'MarpaX::Java::ClassFile::Struct::ExceptionsAttribute' };
class_type InnerClassesAttribute,                         { class => 'MarpaX::Java::ClassFile::Struct::InnerClassesAttribute' };
class_type EnclosingMethodAttribute,                      { class => 'MarpaX::Java::ClassFile::Struct::EnclosingMethodAttribute' };
class_type SyntheticAttribute,                            { class => 'MarpaX::Java::ClassFile::Struct::SyntheticAttribute' };
class_type SignatureAttribute,                            { class => 'MarpaX::Java::ClassFile::Struct::SignatureAttribute' };
class_type SourceFileAttribute,                           { class => 'MarpaX::Java::ClassFile::Struct::SourceFileAttribute' };
class_type SourceDebugExtensionAttribute,                 { class => 'MarpaX::Java::ClassFile::Struct::SourceDebugExtensionAttribute' };
class_type LineNumberTableAttribute,                      { class => 'MarpaX::Java::ClassFile::Struct::LineNumberTableAttribute' };
class_type LocalVariableTableAttribute,                   { class => 'MarpaX::Java::ClassFile::Struct::LocalVariableTableAttribute' };
class_type LocalVariableTypeTableAttribute,               { class => 'MarpaX::Java::ClassFile::Struct::LocalVariableTypeTableAttribute' };
class_type DeprecatedAttribute,                           { class => 'MarpaX::Java::ClassFile::Struct::DeprecatedAttribute' };
class_type RuntimeVisibleAnnotationsAttribute,            { class => 'MarpaX::Java::ClassFile::Struct::RuntimeVisibleAnnotationsAttribute' };
class_type RuntimeInvisibleAnnotationsAttribute,          { class => 'MarpaX::Java::ClassFile::Struct::RuntimeInvisibleAnnotationsAttribute' };
class_type RuntimeVisibleParameterAnnotationsAttribute,   { class => 'MarpaX::Java::ClassFile::Struct::RuntimeVisibleParameterAnnotationsAttribute' };
class_type RuntimeInvisibleParameterAnnotationsAttribute, { class => 'MarpaX::Java::ClassFile::Struct::RuntimeInvisibleParameterAnnotationsAttribute' };
class_type RuntimeVisibleTypeAnnotationsAttribute,        { class => 'MarpaX::Java::ClassFile::Struct::RuntimeVisibleTypeAnnotationsAttribute' };
class_type RuntimeInvisibleTypeAnnotationsAttribute,      { class => 'MarpaX::Java::ClassFile::Struct::RuntimeInvisibleTypeAnnotationsAttribute' };
class_type AnnotationDefaultAttribute,                    { class => 'MarpaX::Java::ClassFile::Struct::AnnotationDefaultAttribute' };
class_type BootstrapMethodsAttribute,                     { class => 'MarpaX::Java::ClassFile::Struct::BootstrapMethodsAttribute' };
class_type MethodParametersAttribute,                     { class => 'MarpaX::Java::ClassFile::Struct::MethodParametersAttribute' };
declare AttributeInfo, as
  UnmanagedAttribute                           |
  ConstantValueAttribute                       |
  CodeAttribute                                |
  StackMapTableAttribute                       |
  ExceptionsAttribute                          |
  InnerClassesAttribute                        |
  EnclosingMethodAttribute                     |
  SyntheticAttribute                           |
  SignatureAttribute                           |
  SourceFileAttribute                          |
  SourceDebugExtensionAttribute                |
  LineNumberTableAttribute                     |
  LocalVariableTableAttribute                  |
  LocalVariableTypeTableAttribute              |
  DeprecatedAttribute                          |
  RuntimeVisibleAnnotationsAttribute           |
  RuntimeInvisibleAnnotationsAttribute         |
  RuntimeVisibleParameterAnnotationsAttribute  |
  RuntimeInvisibleParameterAnnotationsAttribute|
  RuntimeVisibleTypeAnnotationsAttribute       |
  RuntimeInvisibleTypeAnnotationsAttribute     |
  AnnotationDefaultAttribute                   |
  BootstrapMethodsAttribute                    |
  MethodParametersAttribute
  ;


class_type ExceptionTable,  { class => 'MarpaX::Java::ClassFile::Struct::ExceptionTable' };

class_type SameFrame,                         { class => 'MarpaX::Java::ClassFile::Struct::SameFrame' };
class_type SameLocals1StackItemFrame,         { class => 'MarpaX::Java::ClassFile::Struct::SameLocals1StackItemFrame' };
class_type SameLocals1StackItemFrameExtended, { class => 'MarpaX::Java::ClassFile::Struct::SameLocals1StackItemFrameExtended' };
class_type ChopFrame,                         { class => 'MarpaX::Java::ClassFile::Struct::ChopFrame' };
class_type SameFrameExtended,                 { class => 'MarpaX::Java::ClassFile::Struct::SameFrameExtended' };
class_type AppendFrame,                       { class => 'MarpaX::Java::ClassFile::Struct::AppendFrame' };
class_type FullFrame,                         { class => 'MarpaX::Java::ClassFile::Struct::FullFrame' };
declare StackMapFrame, as
  SameFrame                        |
  SameLocals1StackItemFrame        |
  SameLocals1StackItemFrameExtended|
  ChopFrame                        |
  SameFrameExtended                |
  AppendFrame                      |
  FullFrame
;

class_type TopVariableInfo,               { class => 'MarpaX::Java::ClassFile::Struct::TopVariableInfo' };
class_type IntegerVariableInfo,           { class => 'MarpaX::Java::ClassFile::Struct::IntegerVariableInfo' };
class_type FloatVariableInfo,             { class => 'MarpaX::Java::ClassFile::Struct::FloatVariableInfo' };
class_type NullVariableInfo,              { class => 'MarpaX::Java::ClassFile::Struct::NullVariableInfo' };
class_type UninitializedThisVariableInfo, { class => 'MarpaX::Java::ClassFile::Struct::UninitializedThisVariableInfo' };
class_type ObjectVariableInfo,            { class => 'MarpaX::Java::ClassFile::Struct::ObjectVariableInfo' };
class_type UninitializedVariableInfo,     { class => 'MarpaX::Java::ClassFile::Struct::UninitializedVariableInfo' };
class_type LongVariableInfo,              { class => 'MarpaX::Java::ClassFile::Struct::LongVariableInfo' };
class_type DoubleVariableInfo,            { class => 'MarpaX::Java::ClassFile::Struct::DoubleVariableInfo' };
declare VerificationTypeInfo, as
  TopVariableInfo              |
  IntegerVariableInfo          |
  FloatVariableInfo            |
  NullVariableInfo             |
  UninitializedThisVariableInfo|
  ObjectVariableInfo           |
  UninitializedVariableInfo    |
  LongVariableInfo             |
  DoubleVariableInfo
;


# Class is a reserved word
# class_type Class,             { class => 'MarpaX::Java::ClassFile::Struct::Class' };
class_type LineNumber,        { class => 'MarpaX::Java::ClassFile::Struct::LineNumber' };
class_type LocalVariable,     { class => 'MarpaX::Java::ClassFile::Struct::LocalVariable' };
class_type LocalVariableType, { class => 'MarpaX::Java::ClassFile::Struct::LocalVariableType' };
class_type Annotation,        { class => 'MarpaX::Java::ClassFile::Struct::Annotation' };

class_type ConstValueIndex,    { class => 'MarpaX::Java::ClassFile::Struct::ConstValueIndex' };
class_type EnumConstValue,     { class => 'MarpaX::Java::ClassFile::Struct::EnumConstValue' };
class_type ClassInfoIndex,     { class => 'MarpaX::Java::ClassFile::Struct::ClassInfoIndex' };
class_type ArrayValue,         { class => 'MarpaX::Java::ClassFile::Struct::ArrayValue' };
class_type ElementValuePair,   { class => 'MarpaX::Java::ClassFile::Struct::ElementValuePair' };
class_type ElementValue,       { class => 'MarpaX::Java::ClassFile::Struct::ElementValue' };

class_type ParameterAnnotation,   { class => 'MarpaX::Java::ClassFile::Struct::ParameterAnnotation' };

class_type TypeParameterTarget,      { class => 'MarpaX::Java::ClassFile::Struct::TypeParameterTarget' };
class_type SupertypeTarget,          { class => 'MarpaX::Java::ClassFile::Struct::SupertypeTarget' };
class_type TypeParameterBoundTarget, { class => 'MarpaX::Java::ClassFile::Struct::TypeParameterBoundTarget' };
class_type EmptyTarget,              { class => 'MarpaX::Java::ClassFile::Struct::EmptyTarget' };
class_type FormalParameterTarget,    { class => 'MarpaX::Java::ClassFile::Struct::FormalParameterTarget' };
class_type ThrowsTarget,             { class => 'MarpaX::Java::ClassFile::Struct::ThrowsTarget' };
class_type LocalvarTarget,           { class => 'MarpaX::Java::ClassFile::Struct::LocalvarTarget' };
class_type CatchTarget,              { class => 'MarpaX::Java::ClassFile::Struct::CatchTarget' };
class_type OffsetTarget,             { class => 'MarpaX::Java::ClassFile::Struct::OffsetTarget' };
class_type TypeArgumentTarget,       { class => 'MarpaX::Java::ClassFile::Struct::TypeArgumentTarget' };
declare TargetInfo, as
  TypeParameterTarget     |
  SupertypeTarget         |
  TypeParameterBoundTarget|
  EmptyTarget             |
  FormalParameterTarget   |
  ThrowsTarget            |
  LocalvarTarget          |
  CatchTarget             |
  OffsetTarget            |
  TypeArgumentTarget
;

class_type Table, { class => 'MarpaX::Java::ClassFile::Struct::Table' };

class_type TypeAnnotation, { class => 'MarpaX::Java::ClassFile::Struct::TypeAnnotation' };

class_type Path, { class => 'MarpaX::Java::ClassFile::Struct::Path' };
class_type TypePath, { class => 'MarpaX::Java::ClassFile::Struct::TypePath' };

class_type BootstrapMethod, { class => 'MarpaX::Java::ClassFile::Struct::BootstrapMethod' };
class_type Parameter, { class => 'MarpaX::Java::ClassFile::Struct::Parameter' };

class_type OpCode, { class => 'MarpaX::Java::ClassFile::Struct::OpCode' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::_Types - Type helpers

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
