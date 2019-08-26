use 5.014;

use strict;
use warnings;

use Test::More;

=name

Do

=abstract

Development Framework

=synopsis

  package User;

  use Do 'Class';

  has 'fname';
  has 'lname';

  method greet(Str $name) {
    my $fname = $self->fname;
    my $lname = $self->lname;

    "Hey $name, I'm $fname $lname";
  }

  package main;

  my $user = User->new(fname => 'Al', lname => 'Newkirk');

  say $user->greet('You');

  1;

=description

This package aims to provide a modern Perl development framework and
foundational set of types, functions, classes, patterns, and interfaces for
jump-starting application development.

+=head1 FRAMEWORK

Do (aka Data-Object) is a robust modern Perl development framework, embracing
Perl's multi-paradigm programming nature, flexibility and vast ecosystem that
many engineers already know and love.

+=head1 FRAMEWORK CORE

  package main;

  use Do;

  fun main() {
    # ...
  }

  1;

The framework's core configuration enables strict, warnings, Perl's 5.14
features, and configures the core type library, method signatures, and
autoboxing.

+=head1 FRAMEWORK LIBRARY

  package App::Library;

  use Do 'Library';

  our $User = declare 'User',
    as InstanceOf["App::User"];

  1;

The framework's library configuration established a L<Type::Library> compliant
type library, as well as configuring L<Type::Utils> in the calling package.
Read more at L<Data::Object::Library>.

+=head1 FRAMEWORK CLASS

  package App::User;

  use Do 'Class';

  has 'fname';
  has 'lname';

  1;

The framework's class configuration configures the calling package as a Moo
class, having the "has", "with", and "extends" keywords available. Read more at
L<Data::Object::Class>.

+=head1 FRAMEWORK ROLE

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

The framework's role configuration configures the calling package as a Moo
role, having the "has", "with", and "extends" keywords available. Read more at
L<Data::Object::Role>.

+=head1 FRAMEWORK RULE

  package App::Queueable;

  use Do 'Rule';

  requires 'dequeue';
  requires 'enqueue';

  1;

The framework's rule configuration configures the calling package as a Moo
role, intended to be used to classify interfaces. Read more at
L<Data::Object::Rule>.

+=head1 FRAMEWORK STATE

  package App::Env;

  use Do 'State';

  has 'vars';
  has 'args';
  has 'opts';

  1;

The framework's state configuration configures the calling package as a
singleton class with global state. Read more at L<Data::Object::State>.

+=head1 FRAMEWORK STRUCT

  package App::Data;

  use Do 'Struct';

  has 'auth';
  has 'user';
  has 'args';

  1;

The framework's struct configuration configures the calling package as a class
whose state becomes immutable after instantiation. Read more at
L<Data::Object::Struct>.

+=head1 FRAMEWORK ARRAY

  package App::Args;

  use Do 'Array';

  method command() {
    return $self->get(0);
  }

  1;

The framework's array configuration configures the calling package as a class
which extends the Array class. Read more at L<Data::Object::Array>.

+=head1 FRAMEWORK CODE

  package App::Func;

  use Do 'Code';

  around BUILD($args) {
    $self->$orig($args);

    # ...
  }

  1;

The framework's code configuration configures the calling package as a class
which extends the Code class. Read more at L<Data::Object::Code>.

+=head1 FRAMEWORK FLOAT

  package App::Amount;

  use Do 'Float';

  method currency(Str $code) {
    # ...
  }

  1;

The framework's float configuration configures the calling package as a class
which extends the Float class. Read more at L<Data::Object::Float>.

+=head1 FRAMEWORK HASH

  package App::Data;

  use Do 'Hash';

  method logline() {
    # ...
  }

  1;

The framework's hash configuration configures the calling package as a class
which extends the Hash class. Read more at L<Data::Object::Hash>.

+=head1 FRAMEWORK INTEGER

  package App::Phone;

  use Do 'Integer';

  method format(Str $code) {
    # ...
  }

  1;

The framework's integer configuration configures the calling package as a class
which extends the Integer class. Read more at L<Data::Object::Integer>.

+=head1 FRAMEWORK NUMBER

  package App::ID;

  use Do 'Number';

  method find() {
    # ...
  }

  1;

The framework's number configuration configures the calling package as a class
which extends the Number class. Read more at L<Data::Object::Number>.

+=head1 FRAMEWORK REGEXP

  package App::Path;

  use Do 'Regexp';

  method match() {
    # ...
  }

  1;

The framework's regexp configuration configures the calling package as a class
which extends the Regexp class. Read more at L<Data::Object::Regexp>.

+=head1 FRAMEWORK SCALAR

  package App::OID;

  use Do 'Scalar';

  method find() {
    # ...
  }

  1;

The framework's scalar configuration configures the calling package as a class
which extends the Scalar class. Read more at L<Data::Object::Scalar>.

+=head1 FRAMEWORK STRING

  package App::Title;

  use Do 'String';

  method generate() {
    # ...
  }

  1;

The framework's string configuration configures the calling package as a class
which extends the String class. Read more at L<Data::Object::String>.

+=head1 FRAMEWORK UNDEF

  package App::Fail;

  use Do 'Undef';

  method explain() {
    # ...
  }

  1;

The framework's undef configuration configures the calling package as a class
which extends the Undef class. Read more at L<Data::Object::Undef>.

+=head1 INSTALLATION

If you have cpanm, you only need one line:

  $ cpanm -qn Do

If you don't have cpanm, get it! It takes less than a minute, otherwise:

  $ curl -L https://cpanmin.us | perl - -qn Do

Add C<Do> to the list of dependencies in C<cpanfile>:

  requires "Do" => "1.00"; # 1.00 or newer

If cpanm doesn't have permission to install modules in the current Perl
installation, it will automatically set up and install to a local::lib in your
home directory.  See the L<local::lib|local::lib> documentation for details on
enabling it in your environment. We recommend using a
L<Perlbrew|https://github.com/gugod/app-perlbrew> or
L<Plenv|https://github.com/tokuhirom/plenv> environment. These tools will help
you manage multiple Perl installations in your C<$HOME> directory. They are
completely isolated Perl installations.

=cut

use_ok "Do";

ok 1 and done_testing;
