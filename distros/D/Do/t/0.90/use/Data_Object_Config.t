use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Config

=abstract

Data-Object Package Configuration

=synopsis

  use Data::Object::Config 'Core';

=libraries

Data::Object::Library

=description

This package is used to configure the consuming package based on arguments
passed to the import statement.

+=head1 CONFIGURATIONS

This package is used by both L<Do> and L<Data::Object> to configure the calling
namespace.

+=head2 core

  package main;

  use Data::Object::Config 'Core';

  fun main() {
    # ...
  }

  1;

The core configuration enables strict, warnings, Perl's 5.14 features, and
configures the core type library, method signatures, and autoboxing.

+=head2 library

  package App::Library;

  use Data::Object::Config 'Library';

  our $User = declare 'User',
    as InstanceOf["App::User"];

  1;

The library configuration established a L<Type::Library> compliant type
library, as well as configuring L<Type::Utils> in the calling package.  Read
more at L<Data::Object::Library>.

+=head2 class

  package App::User;

  use Data::Object::Config 'Class';

  has 'fname';
  has 'lname';

  1;

The class configuration configures the calling package as a Moo class, having
the "has", "with", and "extends" keywords available. Read more at
L<Data::Object::Class>.

+=head2 role

  package App::Queuer;

  use Data::Object::Config 'Role';

  has 'queue';

  method dequeue() {
    # ...
  }

  method enqueue($job) {
    # ...
  }

  1;

The role configuration configures the calling package as a Moo role, having the
"has", "with", and "extends" keywords available. Read more at
L<Data::Object::Role>.

+=head2 rule

  package App::Queueable;

  use Data::Object::Config 'Rule';

  requires 'dequeue';
  requires 'enqueue';

  1;

The rule configuration configures the calling package as a Moo role, intended
to be used to classify interfaces. Read more at L<Data::Object::Rule>.

+=head2 state

  package App::Env;

  use Data::Object::Config 'State';

  has 'vars';
  has 'args';
  has 'opts';

  1;

The state configuration configures the calling package as a singleton class
with global state. Read more at L<Data::Object::State>.

+=head2 struct

  package App::Data;

  use Data::Object::Config 'Struct';

  has 'auth';
  has 'user';
  has 'args';

  1;

The struct configuration configures the calling package as a class whose state
becomes immutable after instantiation. Read more at L<Data::Object::Struct>.

+=head2 args

  package App::Args;

  use Data::Object::Config 'Args';

  method validate() {
    # ...
  }

  1;

The args configuration configures the calling package as a class representation
of the C<@ARGV> variable. Read more at L<Data::Object::Args>.

+=head2 array

  package App::Args;

  use Data::Object::Config 'Array';

  method command() {
    return $self->get(0);
  }

  1;

The array configuration configures the calling package as a class which extends
the Array class. Read more at L<Data::Object::Array>.

+=head2 code

  package App::Func;

  use Data::Object::Config 'Code';

  around BUILD($args) {
    $self->$orig($args);

    # ...
  }

  1;

The code configuration configures the calling package as a class which extends
the Code class. Read more at L<Data::Object::Code>.

+=head2 cli

  package App::Cli;

  use Data::Object::Config 'Cli';

  method main(%args) {
    # ...
  }

  1;

The cli configuration configures the calling package as a class capable of
acting as a command-line interface. Read more at L<Data::Object::Cli>.

+=head2 data

  package App::Data;

  use Data::Object::Config 'Data';

  method generate() {
    # ...
  }

  1;

The data configuration configures the calling package as a class capable of
parsing POD. Read more at L<Data::Object::Data>.

+=head2 float

  package App::Amount;

  use Data::Object::Config 'Float';

  method currency(Str $code) {
    # ...
  }

  1;

The float configuration configures the calling package as a class which extends
the Float class. Read more at L<Data::Object::Float>.

+=head2 hash

  package App::Data;

  use Data::Object::Config 'Hash';

  method logline() {
    # ...
  }

  1;

The hash configuration configures the calling package as a class which extends
the Hash class. Read more at L<Data::Object::Hash>.

+=head2 number

  package App::ID;

  use Data::Object::Config 'Number';

  method find() {
    # ...
  }

  1;

The number configuration configures the calling package as a class which
extends the Number class. Read more at L<Data::Object::Number>.

+=head2 opts

  package App::Opts;

  use Data::Object::Config 'Opts';

  method validate() {
    # ...
  }

  1;

The opts configuration configures the calling package as a class representation
of the command-line arguments. Read more at L<Data::Object::Opts>.

+=head2 regexp

  package App::Path;

  use Data::Object::Config 'Regexp';

  method match() {
    # ...
  }

  1;

The regexp configuration configures the calling package as a class which
extends the Regexp class. Read more at L<Data::Object::Regexp>.

+=head2 scalar

  package App::OID;

  use Data::Object::Config 'Scalar';

  method find() {
    # ...
  }

  1;

The scalar configuration configures the calling package as a class which
extends the Scalar class. Read more at L<Data::Object::Scalar>.

+=head2 string

  package App::Title;

  use Data::Object::Config 'String';

  method generate() {
    # ...
  }

  1;

The string configuration configures the calling package as a class which
extends the String class. Read more at L<Data::Object::String>.

+=head2 undef

  package App::Fail;

  use Data::Object::Config 'Undef';

  method explain() {
    # ...
  }

  1;

The undef configuration configures the calling package as a class which extends
the Undef class. Read more at L<Data::Object::Undef>.

+=head2 vars

  package App::Vars;

  use Data::Object::Config 'Vars';

  method config() {
    # ...
  }

  1;

The vars configuration configures the calling package as a class representation
of the C<%ENV> variable. Read more at L<Data::Object::Vars>.

+=head2 with

  package App::Error;

  use Data::Object::Config 'Class';
  use Data::Object::Config 'WithStashable';

  1;

The with configuration configures the calling package to consume the core role
denoted in the name, e.g. the name C<WithStashable> configures the package to
consume the core role L<Data::Object::Role::Stashable>. Using roles requires
that the package have previously been declared a class or role itself.

=cut

use_ok "Data::Object::Config";

ok 1 and done_testing;
