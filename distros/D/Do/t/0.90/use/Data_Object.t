use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object

=abstract

Development Framework Entrypoint

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
jump-starting application development.

+=head1 RATIONALE

This framework provides a framework for modern Perl development, embracing
Perl's multi-paradigm programming nature, flexibility and vast ecosystem that
many of engineers already know and love.

The power of this framework comes from the extendable (yet fully optional) type
library which is integrated into the object system and type-constrainable
subroutine signatures (supporting functions, methods and method modifiers). We
also provide classes which wrap Perl 5 native data types and provides methods
for operating on the data.

+=head1 USAGE

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

  #!/usr/bin/perl

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
user-defined type constraints will be stored and retrieved (and reified).

The C<main> program (namespace) initializes the framework and specifies the
user-defined type library to use in the creation of a single function
C<greetings> which takes two arguments which must both be instances of the
class we just created.

+=head1 NOTES

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

use_ok 'Data::Object';

ok 1 and done_testing;
