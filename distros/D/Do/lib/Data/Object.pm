package Data::Object;

use 5.014;

use strict;
use warnings;

use parent 'Data::Object::Config';

our $VERSION = '1.07'; # VERSION

# METHODS

sub new {
  my ($class, $name) = @_;

  die "Invalid argument" unless ($name || '') =~ /^[a-zA-Z]\w*/;

  require Data::Object::Space;

  return Data::Object::Space->new(join '::', __PACKAGE__, $name);
}

sub any {
  my ($class, $data) = @_;

  return $class->new('Any')->build($data);
}

sub array {
  my ($class, $data) = @_;

  return $class->new('Array')->build($data);
}

sub code {
  my ($class, $data) = @_;

  return $class->new('Code')->build($data);
}

sub exception {
  my ($class, $data) = @_;

  return $class->new('Exception')->build($data);
}

sub float {
  my ($class, $data) = @_;

  return $class->new('Float')->build($data);
}

sub hash {
  my ($class, $data) = @_;

  return $class->new('Hash')->build($data);
}

sub integer {
  my ($class, $data) = @_;

  return $class->new('Integer')->build($data);
}

sub number {
  my ($class, $data) = @_;

  return $class->new('Number')->build($data);
}

sub regexp {
  my ($class, $data) = @_;

  return $class->new('Regexp')->build($data);
}

sub scalar {
  my ($class, $data) = @_;

  return $class->new('Scalar')->build($data);
}

sub string {
  my ($class, $data) = @_;

  return $class->new('String')->build($data);
}

sub undef {
  my ($class, $data) = @_;

  return $class->new('Undef')->build($data);
}

1;

=encoding utf8

=head1 NAME

Data::Object

=cut

=head1 ABSTRACT

Development Framework Entrypoint

=cut

=head1 SYNOPSIS

  package User;

  use Data::Object 'Class';

  extends 'Identity';

  has 'fname';
  has 'lname';

  1;

=cut

=head1 DESCRIPTION

This package aims to provide a modern Perl development framework and
foundational set of types, functions, classes, patterns, and interfaces for
jump-starting application development.

=head1 RATIONALE

This framework provides a framework for modern Perl development, embracing
Perl's multi-paradigm programming nature, flexibility and vast ecosystem that
many of engineers already know and love. The power of this framework comes from
the extendable (yet fully optional) type library which is integrated into the
object system and type-constrainable subroutine signatures (supporting
functions, methods and method modifiers). We also provide classes which wrap
Perl 5 native data types and provides methods for operating on the data.

=head1 CONVENTION

Contrary to the opinion of some, modern Perl programming can be extremely
well-structured and beautiful, leveraging many advanced concepts found in other
languages, and some which aren't. Abilities like method modification also
referred to as augmentation, reflection, advanced object-orientation,
type-constrainable object attributes, type-constrainable subroutine signatures
(with named and positional arguments), as well roles (similar to mixins or
interfaces in other languages). This framework aims to serve as an entrypoint
to leveraging those abilities.

  use Do;

The "Do" package is an alias and subclass of this package. It encapsulates all
of the framework's features, is minimalist, and is meant to be the first import
in a new class or module.

  use Data::Object;

Both import statements are funcationally equivalent, enable the same
functionality, and can be configured equally. This is what's enabled whenever
you import the "Do" or "Data::Object" package into your namespace.

  # basics
  use strict;
  use warnings;

  # loads say, state, switch, etc
  use feature ':5.14';

  # loads type constraints
  use Data::Object::Library;

  # loads function/method signatures
  use Data::Object::Signatures;

  # imports keywords and super "do" function, etc
  use Data::Object::Export;

  # enables method calls on native data types
  use Data::Object::Autobox;

To explain by way of example: The following established a user-defined type
library where user-defined classes, roles, etc, will be automatically
registered.

  package App;

  use Do 'Library';

  1;

The following creates a class representing a user which has the ability to
greet another person. This class is type-library aware and will register itself
as a type constraint.

  package App::User;

  use Do 'Class', 'App';

  has name => (
    is  => 'ro',
    isa => 'Str',
    req => 1
  );

  method hello(AppUser $user) {
    return 'Hello '. $user->name .'. How are you?';
  }

  1;

The following is a script which is type-library aware that creates a function
that returns how one user greets another user.

  package main;

  use App::User;

  use Do 'Core', 'App';

  fun greetings(AppUser $u1, AppUser $u2) {
    return $u1->hello($u2);
  }

  my $u1 = User->new(name => 'Jane');
  my $u2 = User->new(name => 'June');

  say(greetings($u1, $u2)); # Hello June ...

This demonstrates much of the power of this framework in one simple example. If
you're new to Perl, the code above creates a class with a single (read-only
string) attribute called C<name> and a single method called C<hello>, then
registers the class in a user-defined type-library called C<App> where all
user-defined type constraints will be stored and retrieved (and reified). The
C<main> program (namespace) initializes the framework and specifies the
user-defined type library to use in the creation of a single function
C<greetings> which takes two arguments which must both be instances of the
class we just created.

=head1 DISCRETIONARY

It's also important to note that while the example showcases much of what's
possible with this framework, all of the sophistication is totally optional.
For example, method and function signatures are optionally typed, so the
declarations would work just as well without the types specified. In fact, you
could then remove the C<App> type library declarations and even resort
rewriting the method and function as plain-old Perl subroutines.  This
flexibility to be able to enable more advanced capabilities is common in the
Perl ecosystem and is one of the things we love most. The wiring-up of things!
If you're familiar with Perl, this framework is in-part the wiring up of L<Moo>
(with L<Moose> support), L<Type::Tiny>, L<Function::Parameters>, L<Try::Tiny>
and data objects in a cooperative and cohesive way that feels like it's native
to the language.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 any

  any(Any $arg) : AnyObject

The C<any> constructor function returns a L<Data::Object::Any> object for given
argument.

=over 4

=item any example

  # given \*main

  my $object = Data::Object->any(\*main);

=back

=cut

=head2 array

  array(ArrayRef $arg) : ArrayObject

The C<array> constructor function returns a L<Data::Object::Array> object for
given argument.

=over 4

=item array example

  # given [1..4]

  my $object = Data::Object->array([1..4]);

=back

=cut

=head2 code

  code(CodeRef $arg) : CodeObject

The C<code> constructor function returns a L<Data::Object::Code> object for
given argument.

=over 4

=item code example

  # given sub { shift + 1 }

  my $object = Data::Object->code(sub { $_[0] + 1 });

=back

=cut

=head2 exception

  exception(HashRef $arg) : ExceptionObject

The C<exception> constructor function returns a L<Data::Object::Exception>
object for given argument.

=over 4

=item exception example

  # given { message => 'Oops' }

  my $object = Data::Object->exception({ message => 'Oops' });

=back

=cut

=head2 float

  float(Num $arg) : FloatObject

The C<float> constructor function returns a L<Data::Object::Float> object for given
argument.

=over 4

=item float example

  # given 1.23

  my $object = Data::Object->float(1.23);

=back

=cut

=head2 hash

  hash(HashRef $arg) : HashObject

The C<hash> constructor function returns a L<Data::Object::Hash> object for given
argument.

=over 4

=item hash example

  # given {1..4}

  my $object = Data::Object->hash({1..4});

=back

=cut

=head2 integer

  integer(Int $arg) : IntegerObject

The C<integer> constructor function returns a L<Data::Object::Integer> object for given
argument.

=over 4

=item integer example

  # given -123

  my $object = Data::Object->integer(-123);

=back

=cut

=head2 new

  new(Str $arg) : SpaceObject

The new method expects a string representing a class name under the
Data::Object namespace and returns a L<Data::Object::Space> object.

=over 4

=item new example

  # given 'String'

  my $space = Data::Object->new('String');

  my $string = $space->build('hello world');

=back

=cut

=head2 number

  number(Num $arg) : NumberObject

The C<number> constructor function returns a L<Data::Object::Number> object for given
argument.

=over 4

=item number example

  # given 123

  my $object = Data::Object->number(123);

=back

=cut

=head2 regexp

  regexp(Regexp $arg) : RegexpObject

The C<regexp> constructor function returns a L<Data::Object::Regexp> object for given
argument.

=over 4

=item regexp example

  # given qr(\w+)

  my $object = Data::Object->regexp(qr(\w+));

=back

=cut

=head2 scalar

  scalar(Any $arg) : ScalarObject

The C<scalar> constructor function returns a L<Data::Object::Scalar> object for given
argument.

=over 4

=item scalar example

  # given \*main

  my $object = Data::Object->scalar(\*main);

=back

=cut

=head2 string

  string(Str $arg) : ScalarObject

The C<string> constructor function returns a L<Data::Object::String> object for given
argument.

=over 4

=item string example

  # given 'hello'

  my $object = Data::Object->string('hello');

=back

=cut

=head2 undef

  undef(Maybe[Undef] $arg) : UndefObject

The C<undef> constructor function returns a L<Data::Object::Undef> object for given
argument.

=over 4

=item undef example

  # given undef

  my $object = Data::Object->undef(undef);

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 PROJECT

L<On GitHub|https://github.com/iamalnewkirk/do>

L<Initiatives|https://github.com/iamalnewkirk/do/projects>

L<Contributing|https://github.com/iamalnewkirk/do/blob/master/CONTRIBUTE.mkdn>

L<Reporting|https://github.com/iamalnewkirk/do/issues>

=head1 SEE ALSO

To get the most out of this distribution, consider reading the following:

L<Data::Object::Class>

L<Data::Object::Role>

L<Data::Object::Rule>

L<Data::Object::Library>

L<Data::Object::Signatures>

=cut