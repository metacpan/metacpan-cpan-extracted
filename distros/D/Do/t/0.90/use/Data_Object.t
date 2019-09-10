use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object

=abstract

Development Framework

=synopsis

  package User;

  use Data::Object 'Class';

  extends 'Identity';

  has 'fname';
  has 'lname';

  1;

=description

This package aims to provide a modern Perl development framework and
foundational set of types, functions, classes, patterns, and interfaces for
jump-starting application development. This package inherits all behavior from
L<Data::Object::Config>.

=headers

+=head1 CONVENTION

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

+=head1 FRAMEWORK

Do (aka Data-Object) is a robust modern Perl development framework, embracing
Perl's multi-paradigm programming nature, flexibility and vast ecosystem that
many engineers already know and love.

+=head2 core

  package main;

  use Do;

  fun main() {
    # ...
  }

  1;

The framework's core configuration enables strict, warnings, Perl's 5.14
features, and configures the core type library, method signatures, and
autoboxing.

+=head2 library

  package App::Library;

  use Do 'Library';

  our $User = declare 'User',
    as InstanceOf["App::User"];

  1;

The framework's library configuration established a L<Type::Library> compliant
type library, as well as configuring L<Type::Utils> in the calling package.
Read more at L<Data::Object::Library>.

+=head2 class

  package App::User;

  use Do 'Class';

  has 'fname';
  has 'lname';

  1;

The framework's class configuration configures the calling package as a L<Moo>
class, having the "has", "with", and "extends" keywords available. Read more at
L<Data::Object::Class>.

+=head2 role

  package App::Queuer;

  use Do 'Role';

  has 'queue';

  method dequeue() {
    # ...
  }

  method enqueue($job) {
    # ...
  }

  1;

The framework's role configuration configures the calling package as a L<Moo>
role, having the "has", "with", and "extends" keywords available. Read more at
L<Data::Object::Role>.

+=head2 rule

  package App::Queueable;

  use Do 'Rule';

  requires 'dequeue';
  requires 'enqueue';

  1;

The framework's rule configuration configures the calling package as a L<Moo>
role, intended to be used to classify interfaces. Read more at
L<Data::Object::Rule>.

+=head2 state

  package App::Env;

  use Do 'State';

  has 'vars';
  has 'args';
  has 'opts';

  1;

The framework's state configuration configures the calling package as a
singleton class with global state. Read more at L<Data::Object::State>.

+=head2 struct

  package App::Data;

  use Do 'Struct';

  has 'auth';
  has 'user';
  has 'args';

  1;

The framework's struct configuration configures the calling package as a class
whose state becomes immutable after instantiation. Read more at
L<Data::Object::Struct>.

+=head2 args

  package App::Args;

  use Do 'Args';

  method validate() {
    # ...
  }

  1;

The framework's args configuration configures the calling package as a class
representation of the C<@ARGV> variable. Read more at L<Data::Object::Args>.

+=head2 array

  package App::Args;

  use Do 'Array';

  method command() {
    return $self->get(0);
  }

  1;

The framework's array configuration configures the calling package as a class
which extends the Array class. Read more at L<Data::Object::Array>.

+=head2 code

  package App::Func;

  use Do 'Code';

  around BUILD($args) {
    $self->$orig($args);

    # ...
  }

  1;

The framework's code configuration configures the calling package as a class
which extends the Code class. Read more at L<Data::Object::Code>.

+=head2 cli

  package App::Cli;

  use Do 'Cli';

  method main(%args) {
    # ...
  }

  1;

The framework's cli configuration configures the calling package as a class
capable of acting as a command-line interface. Read more at
L<Data::Object::Cli>.

+=head2 data

  package App::Data;

  use Do 'Data';

  method generate() {
    # ...
  }

  1;

The framework's data configuration configures the calling package as a class
capable of parsing POD. Read more at L<Data::Object::Data>.

+=head2 float

  package App::Amount;

  use Do 'Float';

  method currency(Str $code) {
    # ...
  }

  1;

The framework's float configuration configures the calling package as a class
which extends the Float class. Read more at L<Data::Object::Float>.

+=head2 hash

  package App::Data;

  use Do 'Hash';

  method logline() {
    # ...
  }

  1;

The framework's hash configuration configures the calling package as a class
which extends the Hash class. Read more at L<Data::Object::Hash>.

+=head2 number

  package App::ID;

  use Do 'Number';

  method find() {
    # ...
  }

  1;

The framework's number configuration configures the calling package as a class
which extends the Number class. Read more at L<Data::Object::Number>.

+=head2 opts

  package App::Opts;

  use Do 'Opts';

  method validate() {
    # ...
  }

  1;

The framework's opts configuration configures the calling package as a class
representation of the command-line arguments. Read more at
L<Data::Object::Opts>.

+=head2 regexp

  package App::Path;

  use Do 'Regexp';

  method match() {
    # ...
  }

  1;

The framework's regexp configuration configures the calling package as a class
which extends the Regexp class. Read more at L<Data::Object::Regexp>.

+=head2 scalar

  package App::OID;

  use Do 'Scalar';

  method find() {
    # ...
  }

  1;

The framework's scalar configuration configures the calling package as a class
which extends the Scalar class. Read more at L<Data::Object::Scalar>.

+=head2 string

  package App::Title;

  use Do 'String';

  method generate() {
    # ...
  }

  1;

The framework's string configuration configures the calling package as a class
which extends the String class. Read more at L<Data::Object::String>.

+=head2 undef

  package App::Fail;

  use Do 'Undef';

  method explain() {
    # ...
  }

  1;

The framework's undef configuration configures the calling package as a class
which extends the Undef class. Read more at L<Data::Object::Undef>.

+=head2 vars

  package App::Vars;

  use Do 'Vars';

  method config() {
    # ...
  }

  1;

The framework's vars configuration configures the calling package as a class
representation of the C<%ENV> variable. Read more at L<Data::Object::Vars>.

=cut

use_ok 'Data::Object';

ok 1 and done_testing;
