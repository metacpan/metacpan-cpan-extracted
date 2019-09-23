package Data::Object::Utility;

use 5.014;

use strict;
use warnings;

use Memoize qw(memoize);
use Scalar::Util qw(blessed looks_like_number reftype);

our $VERSION = '1.85'; # VERSION

# FUNCTIONS

sub NameFile {
  require Data::Object::Name;

  my ($string) = @_;

  my $name = Data::Object::Name->new($string);

  return $name->file;
}

sub NameLabel {
  require Data::Object::Name;

  my ($string) = @_;

  my $name = Data::Object::Name->new($string);

  return $name->label;
}

sub NamePackage {
  require Data::Object::Name;

  my ($string) = @_;

  my $name = Data::Object::Name->new($string);

  return $name->package;
}

sub NamePath {
  require Data::Object::Name;

  my ($string) = @_;

  my $name = Data::Object::Name->new($string);

  return $name->path;
}

sub Namespace {
  my ($package, $argument) = @_;

  my $registry = Registry();

  my $namespace = NamePackage($argument);

  $registry->set($package, $namespace);

  return $namespace;
}

sub Registry {
  require Data::Object::Registry;

  my $point = Data::Object::Registry->can('new');

  unshift @_, 'Data::Object::Registry' and goto $point;
}

sub Reify {
  my ($from, $expr) = @_;

  my $class = Registry()->obj($from);
  my $point = $class->can('lookup');

  @_ = ($class, $expr) and goto $point;
}

sub TypeArray {
  require Data::Object::Array;

  my $class = 'Data::Object::Array';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeCode {
  require Data::Object::Code;

  my $class = 'Data::Object::Code';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeData {
  require Data::Object::Data;

  my $class = 'Data::Object::Data';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeDispatch {
  require Data::Object::Dispatch;

  my $class = 'Data::Object::Dispatch';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeException {
  require Data::Object::Exception;

  my $class = 'Data::Object::Exception';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeFloat {
  require Data::Object::Float;

  my $class = 'Data::Object::Float';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeHash {
  require Data::Object::Hash;

  my $class = 'Data::Object::Hash';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeNumber {
  require Data::Object::Number;

  my $class = 'Data::Object::Number';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeRegexp {
  require Data::Object::Regexp;

  my $class = 'Data::Object::Regexp';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeScalar {
  require Data::Object::Scalar;

  my $class = 'Data::Object::Scalar';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeSpace {
  require Data::Object::Space;

  my $class = 'Data::Object::Space';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeString {
  require Data::Object::String;

  my $class = 'Data::Object::String';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

sub TypeUndef {
  require Data::Object::Undef;

  my $class = 'Data::Object::Undef';
  my $point = $class->can('new');

  unshift @_, $class and goto $point;
}

# DEDUCERS

sub Deduce {
  my ($data) = @_;

  return TypeUndef($data) if not(defined($data));
  return DeduceBlessed($data) if blessed($data);
  return DeduceDefined($data);
}

sub DeduceDefined {
  my ($data) = @_;

  return DeduceReferences($data) if ref($data);
  return DeduceNumberlike($data) if looks_like_number($data);
  return DeduceStringLike($data);
}

sub DeduceBlessed {
  my ($data) = @_;

  return TypeRegexp($data) if $data->isa('Regexp');
  return $data;
}

sub DeduceReferences {
  my ($data) = @_;

  return TypeArray($data) if 'ARRAY' eq ref $data;
  return TypeCode($data) if 'CODE' eq ref $data;
  return TypeHash($data) if 'HASH' eq ref $data;
  return TypeScalar($data); # glob, etc
}

sub DeduceNumberlike {
  my ($data) = @_;

  return TypeFloat($data) if $data =~ /\./;
  return TypeNumber($data);
}

sub DeduceStringLike {
  my ($data) = @_;

  return TypeString($data);
}

sub DeduceDeep {
  my @data = map Deduce($_), @_;

  for my $data (@data) {
    my $type = TypeName($data);

    if ($type and $type eq 'HASH') {
      for my $i (keys %$data) {
        my $val = $data->{$i};
        $data->{$i} = ref($val) ? DeduceDeep($val) : Deduce($val);
      }
    }
    if ($type and $type eq 'ARRAY') {
      for (my $i = 0; $i < @$data; $i++) {
        my $val = $data->[$i];
        $data->[$i] = ref($val) ? DeduceDeep($val) : Deduce($val);
      }
    }
  }

  return wantarray ? (@data) : $data[0];
}

sub TypeName {
  my ($data) = (Deduce($_[0]));

  return "ARRAY" if $data->isa("Data::Object::Array");
  return "BOOLEAN" if $data->isa("Data::Object::Boolean");
  return "HASH" if $data->isa("Data::Object::Hash");
  return "CODE" if $data->isa("Data::Object::Code");
  return "FLOAT" if $data->isa("Data::Object::Float");
  return "NUMBER" if $data->isa("Data::Object::Number");
  return "STRING" if $data->isa("Data::Object::String");
  return "SCALAR" if $data->isa("Data::Object::Scalar");
  return "REGEXP" if $data->isa("Data::Object::Regexp");
  return "UNDEF" if $data->isa("Data::Object::Undef");

  return undef;
}

# DETRACTORS

sub Detract {
  my ($data) = (Deduce($_[0]));

  my $type = TypeName($data);

INSPECT:
  return $data unless $type;

  return [@$data] if $type eq 'ARRAY';
  return {%$data} if $type eq 'HASH';
  return $$data if $type eq 'BOOLEAN';
  return $$data if $type eq 'REGEXP';
  return $$data if $type eq 'FLOAT';
  return $$data if $type eq 'NUMBER';
  return $$data if $type eq 'STRING';
  return undef  if $type eq 'UNDEF';

  if ($type eq 'ANY' or $type eq 'SCALAR') {
    $type = reftype($data) // '';

    return [@$data] if $type eq 'ARRAY';
    return {%$data} if $type eq 'HASH';
    return $$data if $type eq 'BOOLEAN';
    return $$data if $type eq 'FLOAT';
    return $$data if $type eq 'NUMBER';
    return $$data if $type eq 'REGEXP';
    return $$data if $type eq 'SCALAR';
    return $$data if $type eq 'STRING';
    return undef  if $type eq 'UNDEF';

    if ($type eq 'REF') {
      $type = TypeName($data = $$data) and goto INSPECT;
    }
  }

  if ($type eq 'CODE') {
    return sub { goto $data };
  }

  return undef;
}

sub DetractDeep {
  my @data = map Detract($_), @_;

  for my $data (@data) {
    if ($data and 'HASH' eq ref $data) {
      for my $i (keys %$data) {
        my $val = $data->{$i};
        $data->{$i} = ref($val) ? DetractDeep($val) : Detract($val);
      }
    }
    if ($data and 'ARRAY' eq ref $data) {
      for (my $i = 0; $i < @$data; $i++) {
        my $val = $data->[$i];
        $data->[$i] = ref($val) ? DetractDeep($val) : Detract($val);
      }
    }
  }

  return wantarray ? (@data) : $data[0];
}

memoize 'Namespace';
memoize 'Reify';

1;

=encoding utf8

=head1 NAME

Data::Object::Utility

=cut

=head1 ABSTRACT

Data-Object Utility Functions

=cut

=head1 SYNOPSIS

  use Data::Object::Utility;

  my $array = Data::Object::Utility::Deduce []; # Data::Object::Array
  my $value = Data::Object::Utility::Detract $array; # [,...]

=cut

=head1 DESCRIPTION

This package provides a suite of utility functions designed to be used
internally across core packages.

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 deduce

  Deduce(Any $arg1) : Any

The C<Deduce> function returns a data type object instance based upon the
deduced type of data provided.

=over 4

=item Deduce example

  # given ...

  Data::Object::Utility::Deduce(...);

=back

=cut

=head2 deduceblessed

  DeduceBlessed(Any $arg1) : Int

The C<DeduceBlessed> function returns truthy if the argument is blessed.

=over 4

=item DeduceBlessed example

  # given ...

  Data::Object::Utility::DeduceBlessed(...);

=back

=cut

=head2 deducedeep

  DeduceDeep(Any $arg1) : Any

The C<DeduceDeep> function returns a data type object. If the data provided is
complex, this function traverses the data converting all nested data to
objects. Note: Blessed objects are not traversed.

=over 4

=item DeduceDeep example

  # given ...

  Data::Object::Utility::DeduceDeep(...);

=back

=cut

=head2 deducedefined

  DeduceDefined(Any $arg1) : Int

The C<DeduceDefined> function returns truthy if the argument is defined.

=over 4

=item DeduceDefined example

  # given ...

  Data::Object::Utility::DeduceDefined(...);

=back

=cut

=head2 deducenumberlike

  DeduceNumberlike(Any $arg1) : Int

The C<DeduceNumberlike> function returns truthy if the argument is numberlike.

=over 4

=item DeduceNumberlike example

  # given ...

  Data::Object::Utility::DeduceNumberlike(...);

=back

=cut

=head2 deducereferences

  DeduceReferences(Any $arg1) : Int

The C<DeduceReferences> function returns a data object based on the type of
argument reference provided.

=over 4

=item DeduceReferences example

  # given ...

  Data::Object::Utility::DeduceReferences(...);

=back

=cut

=head2 deducestringlike

  DeduceStringLike(Any $arg1) : Int

The C<DeduceStringLike> function returns truthy if the argument is stringlike.

=over 4

=item DeduceStringLike example

  # given ...

  Data::Object::Utility::DeduceStringLike(...);

=back

=cut

=head2 detract

  Detract(Any $arg1) : Any

The C<Detract> function returns a value of native type, based upon the
underlying reference of the data type object provided.

=over 4

=item Detract example

  # given ...

  Data::Object::Utility::Detract(...);

=back

=cut

=head2 detractdeep

  DetractDeep(Any $arg1) : Any

The C<DetractDeep> function returns a value of native type. If the data
provided is complex, this function traverses the data converting all nested
data type objects into native values using the objects underlying reference.
Note: Blessed objects are not traversed.

=over 4

=item DetractDeep example

  # given ...

  Data::Object::Utility::DetractDeep(...);

=back

=cut

=head2 namefile

  NameFile(Str $arg1) : Str

The C<NameFile> function returns the file representation for a given string.

=over 4

=item NameFile example

  # given ...

  Data::Object::Utility::NameFile(...);

=back

=cut

=head2 namelabel

  NameLabel(Str $arg1) : Str

The C<NameLabel> function returns the label representation for a given string.

=over 4

=item NameLabel example

  # given ...

  Data::Object::Utility::NameLabel(...);

=back

=cut

=head2 namepackage

  NamePackage(Str $arg1) : Str

The C<NamePackage> function returns the package representation for a give
string.

=over 4

=item NamePackage example

  # given ...

  Data::Object::Utility::NamePackage(...);

=back

=cut

=head2 namepath

  NamePath(Str $arg1) : Str

The C<NamePath> function returns the path representation for a given string.

=over 4

=item NamePath example

  # given ...

  Data::Object::Utility::NamePath(...);

=back

=cut

=head2 namespace

  Namespace(Str $arg1) : Str

The C<Namespace> function registers a type library with a namespace in the
registry so that typed operations know where to look for type context-specific
constraints.

=over 4

=item Namespace example

  # given ...

  Data::Object::Utility::Namespace(...);

=back

=cut

=head2 registry

  Registry() : Object

The C<Registry> function returns the global L<Data::Object::Registry> object,
which holds mappings between namespaces and type registries.

=over 4

=item Registry example

  # given ...

  Data::Object::Utility::Registry(...);

=back

=cut

=head2 reify

  Reify(Str $namespace, Str $expression) : Maybe[Object]

The C<Reify> function returns a type constraint for a given namespace and
expression.

=over 4

=item Reify example

  # given ...

  Data::Object::Utility::Reify(...);

=back

=cut

=head2 typearray

  TypeArray(ArrayRef $arg1) : ArrayObject

The C<TypeArray> function returns a L<Data::Object::Array> instance which wraps
the provided data type and can be used to perform operations on the data.

=over 4

=item TypeArray example

  # given ...

  Data::Object::Utility::TypeArray(...);

=back

=cut

=head2 typecode

  TypeCode(CodeRef $arg1) : CodeObject

The C<TypeCode> function returns a L<Data::Object::Code> instance which wraps
the provided data type and can be used to perform operations on the data.

=over 4

=item TypeCode example

  # given ...

  Data::Object::Utility::TypeCode(...);

=back

=cut

=head2 typedata

  TypeData(Str $arg1) : Object

The C<TypeData> function returns a L<Data::Object::Data> instance which parses
pod-ish data in files and packages.

=over 4

=item TypeData example

  # given ...

  Data::Object::Utility::TypeData(...);

=back

=cut

=head2 typedispatch

  TypeDispatch(Str $arg1) : Object

The C<TypeDispatch> function return a L<Data::Object::Dispatch> object which is
a handle that let's you call into other packages.

=over 4

=item TypeDispatch example

  # given ...

  Data::Object::Utility::TypeDispatch(...);

=back

=cut

=head2 typeexception

  TypeException(Any @args) : Object

The C<TypeException> function returns a L<Data::Object::Exception> instance
which can be thrown.

=over 4

=item TypeException example

  # given ...

  Data::Object::Utility::TypeException(...);

=back

=cut

=head2 typefloat

  TypeFloat(Str $arg1) : FloatObject

The C<TypeFloat> function returns a L<Data::Object::Float> instance which wraps
the provided data type and can be used to perform operations on the data.

=over 4

=item TypeFloat example

  # given ...

  Data::Object::Utility::TypeFloat(...);

=back

=cut

=head2 typehash

  TypeHash(HashRef $arg1) : HashObject

The C<TypeHash> function returns a L<Data::Object::Hash> instance which wraps
the provided data type and can be used to perform operations on the data.

=over 4

=item TypeHash example

  # given ...

  Data::Object::Utility::TypeHash(...);

=back

=cut

=head2 typename

  TypeName(Any $arg1) : Str

The C<TypeName> function returns a data type description for the type of data
provided, represented as a string in capital letters.

=over 4

=item TypeName example

  # given ...

  Data::Object::Utility::TypeName(...);

=back

=cut

=head2 typenumber

  TypeNumber(Num $arg1) : NumObject

The C<TypeNumber> function returns a L<Data::Object::Number> instance which
wraps the provided data type and can be used to perform operations on the data.

=over 4

=item TypeNumber example

  # given ...

  Data::Object::Utility::TypeNumber(...);

=back

=cut

=head2 typeregexp

  TypeRegexp(RegexpRef $arg1) : RegexpObject

The C<TypeRegexp> function returns a L<Data::Object::Regexp> instance which
wraps the provided data type and can be used to perform operations on the data.

=over 4

=item TypeRegexp example

  # given ...

  Data::Object::Utility::TypeRegexp(...);

=back

=cut

=head2 typescalar

  TypeScalar(Any $arg1) : ScalarObject

The C<TypeScalar> function returns a L<Data::Object::Scalar> instance which
wraps the provided data type and can be used to perform operations on the data.

=over 4

=item TypeScalar example

  # given ...

  Data::Object::Utility::TypeScalar(...);

=back

=cut

=head2 typespace

  TypeSpace(Str $arg1) : Object

The C<TypeSpace> function returns a L<Data::Object::Space> instance which
provides methods for operating on package and namespaces.

=over 4

=item TypeSpace example

  # given ...

  Data::Object::Utility::TypeSpace(...);

=back

=cut

=head2 typestring

  TypeString(Str $arg1) : StrObject

The C<TypeString> function returns a L<Data::Object::String> instance which
wraps the provided data type and can be used to perform operations on the data.

=over 4

=item TypeString example

  # given ...

  Data::Object::Utility::TypeString(...);

=back

=cut

=head2 typeundef

  TypeUndef(Undef $arg1) : UndefObject

The C<TypeUndef> function returns a L<Data::Object::Undef> instance which wraps
the provided data type and can be used to perform operations on the data.

=over 4

=item TypeUndef example

  # given ...

  Data::Object::Utility::TypeUndef(...);

=back

=cut

=head1 CREDITS

Al Newkirk, C<+309>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/do/wiki>

L<Project|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Milestones|https://github.com/iamalnewkirk/do/milestones>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Issues|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Do>

L<Data::Object>

L<Data::Object::Class>

L<Data::Object::ClassHas>

L<Data::Object::Role>

L<Data::Object::RoleHas>

L<Data::Object::Library>

=cut