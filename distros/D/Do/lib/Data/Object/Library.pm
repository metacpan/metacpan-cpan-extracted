package Data::Object::Library;

use 5.014;

use strict;
use warnings;

use base 'Type::Library';

use Scalar::Util ();
use Type::Coercion ();
use Type::Tiny ();
use Type::Utils ();
use Types::TypeTiny ();

our $VERSION = '1.88'; # VERSION

Type::Utils::extends('Types::Standard');
Type::Utils::extends('Types::TypeTiny');
Type::Utils::extends('Types::Common::Numeric');
Type::Utils::extends('Types::Common::String');

# TYPES

RegisterAll(DoArgs());
RegisterAll(DoData());
RegisterAll(DoDumpable());
RegisterAll(DoArray());
RegisterAll(DoBoolean());
RegisterAll(DoCli());
RegisterAll(DoCode());
RegisterAll(DoException());
RegisterAll(DoFloat());
RegisterAll(DoFunc());
RegisterAll(DoHash());
RegisterAll(DoImmutable());
RegisterAll(DoNumber());
RegisterAll(DoOpts());
RegisterAll(DoRegexp());
RegisterAll(DoReplace());
RegisterAll(DoScalar());
RegisterAll(DoSearch());
RegisterAll(DoSpace());
RegisterAll(DoStashable());
RegisterAll(DoState());
RegisterAll(DoString());
RegisterAll(DoStruct());
RegisterAll(DoThrowable());
RegisterAll(DoUndef());
RegisterAll(DoVars());

# FUNCTIONS

sub DoArgs {
  {
    name => 'DoArgs',
    aliases => [
      'ArgsObj',
      'ArgsObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Args');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoArray {
  {
    name => 'DoArray',
    aliases => [
      'ArrayObj',
      'ArrayObject'
    ],
    coercions => [
      'ArrayRef', sub {
        require Data::Object::Array;
        Data::Object::Array->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Array');
      return 1;
    },
    explaination => sub {
      my ($data, $type, $name) = @_;

      my $param = $type->parameters->[0];

      for my $i (0 .. $#$data) {
        next if $param->check($data->[$i]);

        my $indx = sprintf('%s->[%d]', $name, $i);
        my $desc = $param->validate_explain($data->[$i], $indx);
        my $text = '"%s" constrains each value in the array object with "%s"';

        return [sprintf($text, $type, $param), @{$desc}];
      }

      return;
    },
    parameterize_constraint => sub {
      my ($data, $type) = @_;

      $type->check($_) || return for @$data;

      return !!1;
    },
    parameterize_coercions => sub {
      my ($data, $type, $anon) = @_;

      my $coercions = [];

      push @$coercions, 'ArrayRef', sub {
        my $value = @_ ? $_[0] : $_;
        my $items = [];

        for (my $i = 0; $i < @$value; $i++) {
          return $value unless $anon->check($value->[$i]);
          $items->[$i] = $data->coerce($value->[$i]);
        }

        return $type->coerce($items);
      };

      return $coercions;
    },
    parent => 'Object'
  }
}

sub DoBoolean {
  {
    name => 'DoBoolean',
    aliases => [
      'BoolObj',
      'BoolObject',
      'BooleanObj',
      'BooleanObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Boolean');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoCli {
  {
    name => 'DoCli',
    aliases => [
      'CliObj',
      'CliObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Cli');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoCode {
  {
    name => 'DoCode',
    aliases => [
      'CodeObj',
      'CodeObject'
    ],
    coercions => [
      'CodeRef', sub {
        require Data::Object::Code;
        Data::Object::Code->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Code');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoData {
  {
    name => 'DoData',
    aliases => [
      'DataObj',
      'DataObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Data');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoDumpable {
  {
    name => 'DoDumpable',
    aliases => [
      'Dumpable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Dumpable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoException {
  {
    name => 'DoException',
    aliases => [
      'ExceptionObj',
      'ExceptionObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Exception');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoFloat {
  {
    name => 'DoFloat',
    aliases => [
      'FloatObj',
      'FloatObject'
    ],
    coercions => [
      'Str', sub {
        require Data::Object::Float;
        Data::Oject::Float->new($_[0]);
      },
      'Num', sub {
        require Data::Object::Float;
        Data::Oject::Float->new($_[0]);
      },
      'LaxNum', sub {
        require Data::Object::Float;
        Data::Oject::Float->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Float');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoFunc {
  {
    name => 'DoFunc',
    aliases => [
      'FuncObj',
      'FuncObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Func');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoHash {
  {
    name => 'DoHash',
    aliases => [
      'HashObj',
      'HashObject'
    ],
    coercions => [
      'HashRef', sub {
        require Data::Object::Hash;
        Data::Object::Hash->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Hash');
      return 1;
    },
    explaination => sub {
      my ($data, $type, $name) = @_;

      my $param = $type->parameters->[0];

      for my $k (sort keys %$data) {
        next if $param->check($data->{$k});

        my $indx = sprintf('%s->{%s}', $name, B::perlstring($k));
        my $desc = $param->validate_explain($data->{$k}, $indx);
        my $text = '"%s" constrains each value in the hash object with "%s"';

        return [sprintf($text, $type, $param), @{$desc}];
      }

      return;
    },
    parameterize_constraint => sub {
      my ($data, $type) = @_;

      $type->check($_) || return for values %$data;

      return !!1;
    },
    parameterize_coercions => sub {
      my ($data, $type, $anon) = @_;

      my $coercions = [];

      push @$coercions, 'HashRef', sub {
        my $value = @_ ? $_[0] : $_;
        my $items = {};

        for my $k (sort keys %$value) {
          return $value unless $anon->check($value->{$k});
          $items->{$k} = $data->coerce($value->{$k});
        }

        return $type->coerce($items);
      };

      return $coercions;
    },
    parent => 'Object'
  }
}

sub DoImmutable {
  {
    name => 'DoImmutable',
    aliases => [
      'Immutable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Immutable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoNumber {
  {
    name => 'DoNum',
    aliases => [
      'NumObj',
      'NumObject',
      'NumberObj',
      'NumberObject'
    ],
    coercions => [
      'Int', sub {
        require Data::Object::Number;
        Data::Object::Number->new($_[0]);
      },
      'Num', sub {
        require Data::Object::Number;
        Data::Object::Number->new($_[0]);
      },
      'LaxNum', sub {
        require Data::Object::Number;
        Data::Object::Number->new($_[0]);
      },
      'StrictNum', sub {
        require Data::Object::Number;
        Data::Object::Number->new($_[0]);
      },
      'Str', sub {
        require Data::Object::Number;
        Data::Object::Number->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Number');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoOpts {
  {
    name => 'DoOpts',
    aliases => [
      'OptsObj',
      'OptsObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Opts');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoRegexp {
  {
    name => 'DoRegexp',
    aliases => [
      'RegexpObj',
      'RegexpObject'
    ],
    coercions => [
      'RegexpRef', sub {
        require Data::Object::Regexp;
        Data::Object::Regexp->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Regexp');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoReplace {
  {
    name => 'DoReplace',
    aliases => [
      'ReplaceObj',
      'ReplaceObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Replace');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoScalar {
  {
    name => 'DoScalar',
    aliases => [
      'ScalarObj',
      'ScalarObject'
    ],
    coercions => [
      'ScalarRef', sub {
        require Data::Object::Scalar;
        Data::Object::Scalar->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Scalar');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoSearch {
  {
    name => 'DoSearch',
    aliases => [
      'SearchObj',
      'SearchObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Search');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoSpace {
  {
    name => 'DoSpace',
    aliases => [
      'SpaceObj',
      'SpaceObject'
    ],
    coercions => [
      'Str', sub {
        require Data::Object::Space;
        Data::Object::Space->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Space');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoStashable {
  {
    name => 'DoStashable',
    aliases => [
      'Stashable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Stashable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoState {
  {
    name => 'DoState',
    aliases => [
      'StateObj',
      'StateObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::State');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoString {
  {
    name => 'DoStr',
    aliases => [
      'StrObj',
      'StrObject',
      'StringObj',
      'StringObject'
    ],
    coercions => [
      'Str', sub {
        require Data::Object::String;
        Data::Object::String->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::String');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoStruct {
  {
    name => 'DoStruct',
    aliases => [
      'StructObj',
      'StructObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Struct');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoThrowable {
  {
    name => 'DoThrowable',
    aliases => [
      'Throwable'
    ],
    validation => sub {
      return 0 if !$_[0]->does('Data::Object::Role::Throwable');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoUndef {
  {
    name => 'DoUndef',
    aliases => [
      'UndefObj',
      'UndefObject'
    ],
    coercions => [
      'Undef', sub {
        require Data::Object::Undef;
        Data::Object::Undef->new($_[0]);
      }
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Undef');
      return 1;
    },
    parent => 'Object'
  }
}

sub DoVars {
  {
    name => 'DoVars',
    aliases => [
      'VarsObj',
      'VarsObject'
    ],
    validation => sub {
      return 0 if !$_[0]->isa('Data::Object::Vars');
      return 1;
    },
    parent => 'Object'
  }
}

sub Library {
  __PACKAGE__->meta;
}

sub Register {
  my ($type) = @_;

  my $library = Library();

  my $name = $type->{name};
  my $aliases = $type->{aliases};
  my $parent = $type->{parent};
  my $coercions = $type->{coercions};
  my $validation = $type->{validation};

  return if $library->get_type($name);

  my $tinytype = Type::Tiny->new(Options($type));

  if ($type->{coercions}) {
    my $coercions = $type->{coercions};

    for (my $i = 0; $i < @$coercions; $i+=2) {
      if (!ref($coercions->[$i])) {
        $coercions->[$i] = $library->get_type($coercions->[$i]);
      }
    }

    $tinytype->coercion->add_type_coercions(@$coercions);
  }

  $library->add_type($tinytype);

  return $tinytype;
}

sub Options {
  my ($type) = @_;

  my $library = Library();
  my %options;

  $options{name} = $type->{name};
  $options{parent} = $type->{parent};
  $options{constraint} = sub { $type->{validation}->(@_) };

  if ($type->{explaination}) {
    $options{deep_explanation} = sub {
      GenerateExplanation($type, @_)
    };
  }

  if ($type->{parameterize_coercions}) {
    $options{coercion_generator} = sub {
      GenerateCoercion($type, @_)
    };
  }

  if ($type->{parameterize_constraint}) {
    $options{constraint_generator} = sub {
      GenerateConstraint($type, @_)
    };
  }

  if (!ref($options{parent})) {
    $options{parent} = $library->get_type($options{parent});
  }

  return %options;
}

sub RegisterAll {
  my ($type) = @_;

  my $registered = Register($type);

  Register({%{$type}, name => $_, aliases => []}) for @{$type->{aliases}};

  return $registered;
}

sub GenerateCoercion {
  my ($type, @args) = @_;

  my ($type1, $xtype, $type2) = @args;

  my $library = Library();

  if (!$type2->has_coercion) {
    return $type1->coercion;
  }

  my $anon = $type2->coercion->_source_type_union;
  my $coercion = Type::Coercion->new(type_constraint => $xtype);
  my $generated = $type->{parameterize_coercions}->($type2, $type1, $anon);

  for (my $i = 0; $i < @$generated; $i+=2) {
    my $item = $generated->[$i];

    $generated->[$i] = $library->get_type($item) if !ref($item);
  }

  $coercion->add_type_coercions(@$generated);

  return $coercion;
}

sub GenerateConstraint {
  my ($type, @args) = @_;

  return $type->{validator} if !@args;

  my $sign = "@{[$type->{name}]}\[`a\]";
  my $text = "Parameter to $sign expected to be a type constraint";
  my @list = map Types::TypeTiny::to_TypeTiny($_), @args;

  for my $item (@list) {
    if ($item->isa('Type::Tiny')) {
      next;
    }
    if (!Types::TypeTiny::TypeTiny->check($item)) {
      Types::Standard::_croak("$text; got $item");
    }
  }

  return sub { my ($data) = @_; $type->{parameterize_constraint}->($data, @list) };
}

sub GenerateExplanation {
  my ($type, @args) = @_;

  return $type->{explaination}->($_[2], $_[1], $_[3]);
}

# ONE-OFFS

Type::Utils::declare('RegexpLike', Type::Utils::as(Object(), Type::Utils::where(sub {
  return !!re::is_regexp($_[0]) || (Scalar::Util::blessed($_[0]) &&
    ($_[0]->isa('Regexp') || $_[0]->isa('Data::Object::Regexp')));
})));

Type::Utils::declare('NumberLike', Type::Utils::as(StringLike(), Type::Utils::where(sub {
  return Scalar::Util::looks_like_number("$_[0]");
})));

1;

=encoding utf8

=head1 NAME

Data::Object::Library

=cut

=head1 ABSTRACT

Data-Object Type Library

=cut

=head1 SYNOPSIS

  use Data::Object::Library;

=cut

=head1 DESCRIPTION

This package provides a core type library for the L<Do> framework.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Type::Library>

L<Types::Standard>

L<Types::Common::String>

L<Types::Common::Numeric>

=cut

=head1 FUNCTIONS

This package implements the following functions.

=cut

=head2 doargs

  DoArgs() : HashRef

This function returns the type configuration for a L<Data::Object::Args>
object.

=over 4

=item DoArgs example

  Data::Object::Library::DoArgs();

=back

=cut

=head2 doarray

  DoArray() : HashRef

This function returns the type configuration for a L<Data::Object::Array>
object.

=over 4

=item DoArray example

  Data::Object::Library::DoArray();

=back

=cut

=head2 doboolean

  DoBoolean() : HashRef

This function returns the type configuration for a L<Data::OBject::Code>
object.

=over 4

=item DoBoolean example

  Data::Object::Library::DoBoolean();

=back

=cut

=head2 docli

  DoCli() : HashRef

This function returns the type configuration for a L<Data::Object::Cli>
object.

=over 4

=item DoCli example

  Data::Object::Library::DoCli();

=back

=cut

=head2 docode

  DoCode() : HashRef

This function returns the type configuration for a L<Data::Object::Code>
object.

=over 4

=item DoCode example

  Data::Object::Library::DoCode();

=back

=cut

=head2 dodata

  DoData() : HashRef

This function returns the type configuration for a L<Data::Object::Data>
object.

=over 4

=item DoData example

  Data::Object::Library::DoData();

=back

=cut

=head2 dodumpable

  DoDumpable() : HashRef

This function returns the type configuration for an object with the
L<Data::Object::Role::Dumpable> role.

=over 4

=item DoDumpable example

  Data::Object::Library::DoDumpable();

=back

=cut

=head2 doexception

  DoException() : HashRef

This function returns the type configuration for a L<Data::Object::Exception>
object.

=over 4

=item DoException example

  Data::Object::Library::DoException();

=back

=cut

=head2 dofloat

  DoFloat() : HashRef

This function returns the type configuration for a L<Data::Object::Float>
object.

=over 4

=item DoFloat example

  Data::Object::Library::DoFloat();

=back

=cut

=head2 dofunc

  DoFunc() : HashRef

This function returns the type configuration for a L<Data::Object::Func>
object.

=over 4

=item DoFunc example

  Data::Object::Library::DoFunc();

=back

=cut

=head2 dohash

  DoHash() : HashRef

This function returns the type configuration for a L<Data::Object::Hash>
object.

=over 4

=item DoHash example

  Data::Object::Library::DoHash();

=back

=cut

=head2 doimmutable

  DoImmutable() : HashRef

This function returns the type configuration for an object with the
L<Data::Object::Role::Immutable> role.

=over 4

=item DoImmutable example

  Data::Object::Library::DoImmutable();

=back

=cut

=head2 donumber

  DoNumber() : HashRef

This function returns the type configuration for a L<Data::Object::Number>
object.

=over 4

=item DoNumber example

  Data::Object::Library::DoNumber();

=back

=cut

=head2 doopts

  DoOpts() : HashRef

This function returns the type configuration for a L<Data::Object::Opts>
object.

=over 4

=item DoOpts example

  Data::Object::Library::DoOpts();

=back

=cut

=head2 doregexp

  DoRegexp() : HashRef

This function returns the type configuration for a L<Data::Object::Regexp>
object.

=over 4

=item DoRegexp example

  Data::Object::Library::DoRegexp();

=back

=cut

=head2 doreplace

  DoReplace() : HashRef

This function returns the type configuration for a L<Data::Object::Replace>
object.

=over 4

=item DoReplace example

  Data::Object::Library::DoReplace();

=back

=cut

=head2 doscalar

  DoScalar() : HashRef

This function returns the type configuration for a L<Data::Object::Scalar>
object.

=over 4

=item DoScalar example

  Data::Object::Library::DoScalar();

=back

=cut

=head2 dosearch

  DoSearch() : HashRef

This function returns the type configuration for a L<Data::Object::Search>
object.

=over 4

=item DoSearch example

  Data::Object::Library::DoSearch();

=back

=cut

=head2 dospace

  DoSpace() : HashRef

This function returns the type configuration for a L<Data::Object::Space>
object.

=over 4

=item DoSpace example

  Data::Object::Library::DoSpace();

=back

=cut

=head2 dostashable

  DoStashable() : HashRef

This function returns the type configuration for an object with the
L<Data::Object::Role::Stashable> role.

=over 4

=item DoStashable example

  Data::Object::Library::DoStashable();

=back

=cut

=head2 dostate

  DoState() : HashRef

This function returns the type configuration for a L<Data::Object::State>
object.

=over 4

=item DoState example

  Data::Object::Library::DoState();

=back

=cut

=head2 dostring

  DoString() : HashRef

This function returns the type configuration for a L<Data::Object::String>
object.

=over 4

=item DoString example

  Data::Object::Library::DoString();

=back

=cut

=head2 dostruct

  DoStruct() : HashRef

This function returns the type configuration for a L<Data::Object::Struct>
object.

=over 4

=item DoStruct example

  Data::Object::Library::DoStruct();

=back

=cut

=head2 dothrowable

  DoThrowable() : HashRef

This function returns the type configuration for an object with the
L<Data::Object::Role::Throwable> role.

=over 4

=item DoThrowable example

  Data::Object::Library::DoThrowable();

=back

=cut

=head2 doundef

  DoUndef() : HashRef

This function returns the type configuration for a L<Data::Object::Undef>
object.

=over 4

=item DoUndef example

  Data::Object::Library::DoUndef();

=back

=cut

=head2 dovars

  DoVars() : HashRef

This function returns the type configuration for a L<Data::Object::Vars>
object.

=over 4

=item DoVars example

  Data::Object::Library::DoVars();

=back

=cut

=head2 generatecoercion

  GenerateCoercion(HashRef $config) : InstanceOf["Type::Coercion"]

This function takes a type configuration hashref, then generates and returns a
type coercion based on its configuration.

=over 4

=item GenerateCoercion example

  Data::Object::Library::GenerateCoercion({...});

=back

=cut

=head2 generateconstraint

  GenerateConstraint(HashRef $config) : CodeRef

This function takes a type configuration hashref, then generates and returns a
coderef which validates the type based on its configuration.

=over 4

=item GenerateConstraint example

  Data::Object::Library::GenerateConstraint({...});

=back

=cut

=head2 generateexplanation

  GenerateExplanation(HashRef $config) : CodeRef

This function takes a type configuration hashref, then generates and returns a
coderef which returns a deep-explanation of the type failure based on its
configuration.

=over 4

=item GenerateExplanation example

  Data::Object::Library::GenerateExplanation({...});

=back

=cut

=head2 library

  Library() : InstanceOf["Type::Library"]

This function returns the core type library object.

=over 4

=item Library example

  Data::Object::Library::Library();

=back

=cut

=head2 options

  Options(HashRef $config) : (Any)

This function takes a type configuration hashref, then generates and returns a
set of options relevant to creating L<Type::Tiny> objects.

=over 4

=item Options example

  Data::Object::Library::Options({...});

=back

=cut

=head2 register

  Register(HashRef $config) : InstanceOf["Type::Tiny"]

This function takes a type configuration hashref, then generates and returns a
L<Type::Tiny> object based on its configuration.

=over 4

=item Register example

  Data::Object::Library::Register({...});

=back

=cut

=head2 registerall

  RegisterAll(HashRef $config) : InstanceOf["Type::Tiny"]

This function takes a type configuration hashref, then generates and returns a
L<Type::Tiny> object based on its configuration. This method also registers
aliases as stand-alone types in the library.

=over 4

=item RegisterAll example

  Data::Object::Library::RegisterAll({...});

=back

=cut

=head1 CONSTRAINTS

This package provides the following type constraints.

=head2 any

  # Any

The C<Any> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Any> function can be
used to throw an exception is the argument can not be validated. The C<is_Any>
function can be used to return true or false if the argument can not be
validated.

=head2 arraylike

  # ArrayLike

The C<ArrayLike> type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_ArrayLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayLike> function can be used to return true or false if
the argument can not be validated.

=head2 argsobj

  # ArgsObj

The C<ArgsObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Args> object. The
C<assert_ArgsObj> function can be used to throw an exception if the argument
can not be validated. The C<is_ArgsObj> function can be used to return true or
false if the argument can not be validated.

=head2 argsobject

  # ArgsObject

The C<ArgsObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Args> object. The
C<assert_ArgsObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ArgsObject> function can be used to return true
or false if the argument can not be validated.

=head2 arrayobj

  # ArrayObj

The C<ArrayObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ArrayObj> function can be used to return true or false
if the argument can not be validated.

=head2 arrayobject

  # ArrayObject

The C<ArrayObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ArrayObject> function can be used to return true or
false if the argument can not be validated.

=head2 arrayref

  # ArrayRef

The C<ArrayRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ArrayRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayRef> function can be used to return true or false if the
argument can not be validated.

=head2 bool

  # Bool

The C<Bool> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Bool> function can be
used to throw an exception if the argument can not be validated. The C<is_Bool>
function can be used to return true or false if the argument can not be
validated.

=head2 boolobj

  # BoolObj

The C<BoolObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Boolean> object. The
C<assert_BoolObj> function can be used to throw an exception if the argument
can not be validated. The C<is_BoolObj> function can be used to return true or
false if the argument can not be validated.

=head2 boolobject

  # BoolObject

The C<BoolObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Boolean> object. The
C<assert_BoolObject> function can be used to throw an exception if the argument
can not be validated. The C<is_BoolObject> function can be used to return true
or false if the argument can not be validated.

=head2 booleanobj

  # BooleanObj

The C<BooleanObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Boolean> object. The
C<assert_BooleanObj> function can be used to throw an exception if the argument
can not be validated. The C<is_BooleanObj> function can be used to return true
or false if the argument can not be validated.

=head2 booleanobject

  # BooleanObject

The C<BooleanObject> type constraint is provided by this library and accepts
any object that is, or is derived from, a L<Data::Object::Boolean> object. The
C<assert_BooleanObject> function can be used to throw an exception if the
argument can not be validated. The C<is_BooleanObject> function can be used to
return true or false if the argument can not be validated.

=head2 classname

  # ClassName["MyClass"]

The C<ClassName> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ClassName>
function can be used to throw an exception if the argument can not be
validated. The C<is_ClassName> function can be used to return true or false if the
argument can not be validated.

=head2 codelike

  # CodeLike

The C<CodeLike> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_CodeLike> function can be
used to throw an exception if the argument can not be validated. The C<is_CodeLike>
function can be used to return true or false if the argument can not be
validated.

=head2 cliobj

  # CliObj

The C<CliObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Cli> object. The C<assert_CliObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_CliObj> function can be used to return true or false if the
argument can not be validated.

=head2 cliobject

  # CliObject

The C<CliObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Cli> object. The
C<assert_CliObject> function can be used to throw an exception if the argument
can not be validated. The C<is_CliObject> function can be used to return true or
false if the argument can not be validated.

=head2 codeobj

  # CodeObj

The C<CodeObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Code> object. The C<assert_CodeObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_CodeObj> function can be used to return true or false if the
argument can not be validated.

=head2 codeobject

  # CodeObject

The C<CodeObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Code> object. The
C<assert_CodeObject> function can be used to throw an exception if the argument
can not be validated. The C<is_CodeObject> function can be used to return true or
false if the argument can not be validated.

=head2 coderef

  # CodeRef

The C<CodeRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_CodeRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_CodeRef> function can be used to return true or false if the argument can not
be validated.

=head2 consumerof

  # ConsumerOf["MyRole"]

The C<ConsumerOf> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ConsumerOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_ConsumerOf> function can be used to return true or false if
the argument can not be validated.

=head2 dataobj

  # DataObj

The C<DataObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObj> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObj> function can be used to return true or
false if the argument can not be validated.

=head2 dataobject

  # DataObject

The C<DataObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObject> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObject> function can be used to return true
or false if the argument can not be validated.

=head2 defined

  # Defined

The C<Defined> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Defined> function
can be used to throw an exception if the argument can not be validated. The
C<is_Defined> function can be used to return true or false if the argument can not
be validated.

=head2 dict

  # Dict

The C<Dict> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Dict> function can be
used to throw an exception if the argument can not be validated. The C<is_Dict>
function can be used to return true or false if the argument can not be
validated.

=head2 dumpable

  # Dumpable

The C<Dumpable> type constraint is provided by this library and accepts any
object that is a consumer of the L<Data::Object::Role::Dumpable> role. The
C<assert_Dumpable> function can be used to throw an exception if the argument
can not be validated. The C<is_Dumpable> function can be used to return true or
false if the argument can not be validated.

=head2 enum

  # Enum[qw(A B C)]

The C<Enum> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Enum> function can be
used to throw an exception if the argument can not be validated. The C<is_Enum>
function can be used to return true or false if the argument can not be
validated.

=head2 exceptionobj

  # ExceptionObj

The C<ExceptionObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObj> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObj> function can be used to
return true or false if the argument can not be validated.

=head2 exceptionobject

  # ExceptionObject

The C<ExceptionObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObject> function can be used
to return true or false if the argument can not be validated.

=head2 filehandle

  # FileHandle

The C<FileHandle> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_FileHandle>
function can be used to throw an exception if the argument can not be
validated. The C<is_FileHandle> function can be used to return true or false if
the argument can not be validated.

=head2 floatobj

  # FloatObj

The C<FloatObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObj> function can be used to throw an exception if the argument can
not be validated. The C<is_FloatObj> function can be used to return true or false
if the argument can not be validated.

=head2 floatobject

  # FloatObject

The C<FloatObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FloatObject> function can be used to return true or
false if the argument can not be validated.

=head2 funcobj

  # FuncObj

The C<FuncObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObj> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObj> function can be used to return true or
false if the argument can not be validated.

=head2 funcobject

  # FuncObject

The C<FuncObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObject> function can be used to return true
or false if the argument can not be validated.

=head2 globref

  # GlobRef

The C<GlobRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_GlobRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_GlobRef> function can be used to return true or false if the argument can not
be validated.

=head2 hasmethods

  # HasMethods["new"]

The C<HasMethods> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HasMethods>
function can be used to throw an exception if the argument can not be
validated. The C<is_HasMethods> function can be used to return true or false if
the argument can not be validated.

=head2 hashlike

  # HashLike

The C<HashLike> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_HashLike> function can be
used to throw an exception if the argument can not be validated. The C<is_HashLike>
function can be used to return true or false if the argument can not be
validated.

=head2 hashobj

  # HashObj

The C<HashObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Hash> object. The C<assert_HashObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_HashObj> function can be used to return true or false if the
argument can not be validated.

=head2 hashobject

  # HashObject

The C<HashObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Hash> object. The
C<assert_HashObject> function can be used to throw an exception if the argument
can not be validated. The C<is_HashObject> function can be used to return true or
false if the argument can not be validated.

=head2 hashref

  # HashRef

The C<HashRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HashRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_HashRef> function can be used to return true or false if the argument can not
be validated.

=head2 immutable

  # Immutable

The C<Immutable> type constraint is provided by this library and accepts any
object that is a consumer of the L<Data::Object::Role::Immutable> role. The
C<assert_Immutable> function can be used to throw an exception if the argument
can not be validated. The C<is_Immutable> function can be used to return true or
false if the argument can not be validated.

=head2 instanceof

  # InstanceOf[MyClass]

The C<InstanceOf> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_InstanceOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_InstanceOf> function can be used to return true or false if
the argument can not be validated.

=head2 int

  # Int

The C<Int> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Int> function can be
used to throw an exception if the argument can not be validated. The C<is_Int>
function can be used to return true or false if the argument can not be
validated.

=head2 intobj

  # IntObj

The C<IntObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObj> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObj> function can be used to return true or false if
the argument can not be validated.

=head2 intobject

  # IntObject

The C<IntObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObject> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObject> function can be used to return true or false
if the argument can not be validated.

=head2 intrange

  # IntRange[0, 25]

The C<IntRange> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_IntRange> function can be
used to throw an exception if the argument can not be validated. The C<is_IntRange>
function can be used to return true or false if the argument can not be
validated.

=head2 integerobj

  # IntegerObj

The C<IntegerObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObj> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObj> function can be used to return true or
false if the argument can not be validated.

=head2 integerobject

  # IntegerObject

The C<IntegerObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObject> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObject> function can be used to return true
or false if the argument can not be validated.

=head2 item

  # Item

The C<Item> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Item> function can be
used to throw an exception if the argument can not be validated. The C<is_Item>
function can be used to return true or false if the argument can not be
validated.

=head2 laxnum

  # LaxNum

The C<LaxNum> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_LaxNum> function
can be used to throw an exception if the argument can not be validated. The
C<is_LaxNum> function can be used to return true or false if the argument can not
be validated.

=head2 lowercasesimplestr

  # LowerCaseSimpleStr

The C<LowerCaseSimpleStr> type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_LowerCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_LowerCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

=head2 lowercasestr

  # LowerCaseStr

The C<LowerCaseStr> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The C<assert_type>
function can be used to throw an exception if the argument can not be
validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.

=head2 map

  # Map[Int, HashRef]

The C<Map> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Map> function can be
used to throw an exception if the argument can not be validated. The C<is_Map>
function can be used to return true or false if the argument can not be
validated.

=head2 maybe

  # Maybe[Object]

The C<Maybe> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Maybe> function can be
used to throw an exception if the argument can not be validated. The C<is_Maybe>
function can be used to return true or false if the argument can not be
validated.

=head2 negativeint

  # NegativeInt

The C<NegativeInt> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeInt> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeInt> function can be used to return true or
false if the argument can not be validated.

=head2 negativenum

  # NegativeNum

The C<NegativeNum> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeNum> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeNum> function can be used to return true or
false if the argument can not be validated.

=head2 negativeorzeroint

  # NegativeOrZeroInt

The C<NegativeOrZeroInt> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_NegativeOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_NegativeOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

=head2 negativeorzeronum

  # NegativeOrZeroNum

The C<NegativeOrZeroNum> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=head2 nonemptysimplestr

  # NonEmptySimpleStr

The C<NonEmptySimpleStr> type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=head2 nonemptystr

  # NonEmptyStr

The C<NonEmptyStr> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_type> function
can be used to throw an exception if the argument can not be validated. The
C<is_type> function can be used to return true or false if the argument can not be
validated.

=head2 num

  # Num

The C<Num> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Num> function can be
used to throw an exception if the argument can not be validated. The C<is_Num>
function can be used to return true or false if the argument can not be
validated.

=head2 numberlike

  # NumberLike

The C<NumberLike> type constraint is provided by the this library and accepts
any value that looks like a number, or object that overloads stringification
and looks like a number stringified. Please see that documentation for more
information. The C<assert_NumberLike> function can be used to throw an
exception if the argument can not be validated. The C<is_NumberLike> function
can be used to return true or false if the argument can not be validated.

=head2 numobj

  # NumObj

The C<NumObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObj> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObj> function can be used to return true or false if
the argument can not be validated.

=head2 numobject

  # NumObject

The C<NumObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObject> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObject> function can be used to return true or false
if the argument can not be validated.

=head2 numrange

  # NumRange[0, 25]

The C<NumRange> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_NumRange> function can be
used to throw an exception if the argument can not be validated. The C<is_NumRange>
function can be used to return true or false if the argument can not be
validated.

=head2 numberobject

  # NumberObject

The C<NumberObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumberObject> function can be used to throw an exception if the argument
can not be validated. The C<is_NumberObject> function can be used to return true
or false if the argument can not be validated.

=head2 numericcode

  # NumericCode

The C<NumericCode> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_NumericCode> function can be used to throw an exception if the argument
can not be validated. The C<is_NumericCode> function can be used to return true or
false if the argument can not be validated.

=head2 object

  # Object

The C<Object> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Object> function
can be used to throw an exception if the argument can not be validated. The
C<is_Object> function can be used to return true or false if the argument can not
be validated.

=head2 optsobj

  # OptsObj

The C<OptsObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Opts> object. The
C<assert_OptsObj> function can be used to throw an exception if the argument
can not be validated. The C<is_OptsObj> function can be used to return true or
false if the argument can not be validated.

=head2 optsobject

  # OptsObject

The C<OptsObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Opts> object. The
C<assert_OptsObject> function can be used to throw an exception if the argument
can not be validated. The C<is_OptsObject> function can be used to return true
  or false if the argument can not be validated.

=head2 optlist

  # OptList

The C<OptList> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_OptList> function
can be used to throw an exception if the argument can not be validated. The
C<is_OptList> function can be used to return true or false if the argument can not
be validated.

=head2 optional

  # Dict[id => Optional[Int]]

The C<Optional> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Optional>
function can be used to throw an exception if the argument can not be
validated. The C<is_Optional> function can be used to return true or false if the
argument can not be validated.

=head2 overload

  # Overload[qw("")]

The C<Overload> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Overload>
function can be used to throw an exception if the argument can not be
validated. The C<is_Overload> function can be used to return true or false if the
argument can not be validated.

=head2 password

  # Password

The C<Password> type constraint is provided by the L<Types::Common::String>
library.  Please see that documentation for more information. The
C<assert_Password> function can be used to throw an exception if the argument
can not be validated. The C<is_Password> function can be used to return true or
false if the argument can not be validated.

=head2 positiveint

  # PositiveInt

The C<PositiveInt> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveInt> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveInt> function can be used to return true or
false if the argument can not be validated.

=head2 positivenum

  # PositiveNum

The C<PositiveNum> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveNum> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveNum> function can be used to return true or
false if the argument can not be validated.

=head2 positiveorzeroint

  # PositiveOrZeroInt

The C<PositiveOrZeroInt> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_PositiveOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_PositiveOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

=head2 positiveorzeronum

  # PositiveOrZeroNum

The C<PositiveOrZeroNum> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=head2 ref

  # Ref["SCALAR"]

The C<Ref> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_type> function can be
used to throw an exception if the argument can not be validated. The C<is_type>
function can be used to return true or false if the argument can not be
validated.

=head2 regexpobj

  # RegexpObj

The C<RegexpObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObj> function can be used to throw an exception if the argument can
not be validated. The C<is_RegexpObj> function can be used to return true or false
if the argument can not be validated.

=head2 regexpobject

  # RegexpObject

The C<RegexpObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObject> function can be used to throw an exception if the argument
can not be validated. The C<is_RegexpObject> function can be used to return true
or false if the argument can not be validated.

=head2 regexpref

  # RegexpRef

The C<RegexpRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RegexpRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_RegexpRef> function can be used to return true or false if the
argument can not be validated.

=head2 replaceobj

  # ReplaceObj

The C<ReplaceObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_ReplaceObj> function can be used to return true
or false if the argument can not be validated.

=head2 replaceobject

  # ReplaceObject

The C<ReplaceObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ReplaceObject> function can be used to
return true or false if the argument can not be validated.

=head2 rolename

  # RoleName

The C<RoleName> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RoleName>
function can be used to throw an exception if the argument can not be
validated. The C<is_RoleName> function can be used to return true or false if the
argument can not be validated.

=head2 scalarobj

  # ScalarObj

The C<ScalarObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ScalarObj> function can be used to return true or false
if the argument can not be validated.

=head2 scalarobject

  # ScalarObject

The C<ScalarObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ScalarObject> function can be used to return true
or false if the argument can not be validated.

=head2 scalarref

  # ScalarRef

The C<ScalarRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ScalarRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ScalarRef> function can be used to return true or false if the
argument can not be validated.

=head2 searchobj

  # SearchObj

The C<SearchObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SearchObj> function can be used to return true
or false if the argument can not be validated.

=head2 searchobject

  # SearchObject

The C<SearchObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SearchObject> function can be used to
return true or false if the argument can not be validated.

=head2 simplestr

  # SimpleStr

The C<SimpleStr> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_SimpleStr> function can be used to throw an exception if the argument can
not be validated. The C<is_SimpleStr> function can be used to return true or false
if the argument can not be validated.

=head2 singledigit

  # SingleDigit

The C<SingleDigit> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_SingleDigit> function can be used to throw an exception if the argument
can not be validated. The C<is_SingleDigit> function can be used to return true or
false if the argument can not be validated.

=head2 spaceobj

  # SpaceObj

The C<SpaceObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SpaceObj> function can be used to return true or
false if the argument can not be validated.

=head2 spaceobject

  # SpaceObject

The C<SpaceObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SpaceObject> function can be used to
return true or false if the argument can not be validated.

=head2 stashable

  # Stashable

The C<Stashable> type constraint is provided by this library and accepts any
object that is a consumer of the L<Data::Object::Role::Stashable> role. The
C<assert_Stashable> function can be used to throw an exception if the argument
can not be validated. The C<is_Stashable> function can be used to return true or
false if the argument can not be validated.

=head2 stateobj

  # StateObj

The C<StateObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::State> object. The
C<assert_StateObj> function can be used to throw an exception if the argument
can not be validated. The C<is_StateObj> function can be used to return true or
false if the argument can not be validated.

=head2 stateobject

  # StateObject

The C<StateObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::State> object. The
C<assert_StateObject> function can be used to throw an exception if the
argument can not be validated. The C<is_StateObject> function can be used to
return true or false if the argument can not be validated.

=head2 str

  # Str

The C<Str> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Str> function can be
used to throw an exception if the argument can not be validated. The C<is_Str>
function can be used to return true or false if the argument can not be
validated.

=head2 strmatch

  # StrMatch[qr/^[A-Z]+$/]

The C<StrMatch> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrMatch>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrMatch> function can be used to return true or false if the
argument can not be validated.

=head2 strobj

  # StrObj

The C<StrObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObj> function can be used to return true or false if
the argument can not be validated.

=head2 strobject

  # StrObject

The C<StrObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObject> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObject> function can be used to return true or false
if the argument can not be validated.

=head2 strictnum

  # StrictNum

The C<StrictNum> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrictNum>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrictNum> function can be used to return true or false if the
argument can not be validated.

=head2 stringlike

  # StringLike

The C<StringLike> type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_StringLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_StringLike> function can be used to return true or false if
the argument can not be validated.

=head2 stringobj

  # StringObj

The C<StringObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StringObj> function can be used to return true or false
if the argument can not be validated.

=head2 stringobject

  # StringObject

The C<StringObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObject> function can be used to throw an exception if the argument
can not be validated. The C<is_StringObject> function can be used to return true
or false if the argument can not be validated.

=head2 strongpassword

  # StrongPassword

The C<StrongPassword> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_StrongPassword> function can be used to throw an exception if the
argument can not be validated. The C<is_StrongPassword> function can be used to
return true or false if the argument can not be validated.

=head2 structobj

  # StructObj

The C<StructObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Struct> object. The
C<assert_StructObj> function can be used to throw an exception if the argument
can not be validated. The C<is_StructObj> function can be used to return true
  or false if the argument can not be validated.

=head2 structobject

  # StructObject

The C<StructObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Struct> object. The
C<assert_StructObject> function can be used to throw an exception if the
argument can not be validated. The C<is_StructObject> function can be used to
return true or false if the argument can not be validated.

=head2 throwable

  # Throwable

The C<Throwable> type constraint is provided by this library and accepts any
object that is a consumer of the L<Data::Object::Role::Throwable> role. The
C<assert_Throwable> function can be used to throw an exception if the argument
can not be validated. The C<is_Throwable> function can be used to return true or
false if the argument can not be validated.

=head2 tied

  # Tied["MyClass"]

The C<Tied> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tied> function can be
used to throw an exception if the argument can not be validated. The C<is_Tied>
function can be used to return true or false if the argument can not be
validated.

=head2 tuple

  # Tuple[Int, Str, Str]

The C<Tuple> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tuple> function can be
used to throw an exception if the argument can not be validated. The C<is_Tuple>
function can be used to return true or false if the argument can not be
validated.

=head2 typetiny

  # TypeTiny

The C<TypeTiny> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_TypeTiny> function can be
used to throw an exception if the argument can not be validated. The C<is_TypeTiny>
function can be used to return true or false if the argument can not be
validated.

=head2 undef

  # Undef

The C<Undef> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Undef> function can be
used to throw an exception if the argument can not be validated. The C<is_Undef>
function can be used to return true or false if the argument can not be
validated.

=head2 undefobj

  # UndefObj

The C<UndefObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObj> function can be used to throw an exception if the argument can
not be validated. The C<is_UndefObj> function can be used to return true or false
if the argument can not be validated.

=head2 undefobject

  # UndefObject

The C<UndefObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObject> function can be used to throw an exception if the argument
can not be validated. The C<is_UndefObject> function can be used to return true or
false if the argument can not be validated.

=head2 uppercasesimplestr

  # UpperCaseSimpleStr

The C<UpperCaseSimpleStr> type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_UpperCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

=head2 uppercasestr

  # UpperCaseStr

The C<UpperCaseStr> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_UpperCaseStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseStr> function can be used to
return true or false if the argument can not be validated.

=head2 value

  # Value

The C<Value> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Value> function can be
used to throw an exception if the argument can not be validated. The C<is_Value>
function can be used to return true or false if the argument can not be
validated.

=head2 varsobj

  # VarsObj

The C<VarsObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Vars> object. The
C<assert_VarsObj> function can be used to throw an exception if the argument
can not be validated. The C<is_VarsObj> function can be used to return true or
false if the argument can not be validated.

=head2 varsobject

  # VarsObject

The C<VarsObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Vars> object. The
C<assert_VarsObject> function can be used to throw an exception if the argument
can not be validated. The C<is_VarsObject> function can be used to return true
  or false if the argument can not be validated.

=head1 CREDITS

Al Newkirk, C<+319>

Anthony Brummett, C<+10>

Adam Hopkins, C<+2>

José Joaquín Atria, C<+1>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated here,
https://github.com/iamalnewkirk/do/blob/master/LICENSE.

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