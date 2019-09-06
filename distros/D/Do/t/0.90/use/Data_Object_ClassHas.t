use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::ClassHas

=abstract

Data-Object Class Attribute Builder

=synopsis

  package Point;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  has 'x';
  has 'y';

  1;

=libraries

Data::Object::Library

=description

This package modifies the consuming package with behaviors useful in defining
classes. Specifically, this package wraps the C<has> attribute keyword
functions and adds shortcuts and enhancements.

=headers

+=head1 EXPORTS

This package automatically exports the following keywords.

+=head2 has

  package Person;

  use Data::Object::Class;
  use Data::Object::ClassHas;

  has 'id';

  has fname => (
    is => 'ro',
    isa => 'StrObj',
    crc => 1,
    req => 1
  );

  has lname => (
    is => 'ro',
    isa => 'StrObj',
    crc => 1,
    req => 1
  );

  1;

The C<has> keyword is used to declare class attributes, which can be accessed
and assigned to using the built-in getter/setter or by the object constructor.
See L<Moo> for more information.

+=over 4

+=item is

  is => 'ro' # read-only
  is => 'rw' # read-write

The C<is> directive is used to denote whether the attribute is read-only or
read-write. See the L<Moo> documentation for more details.

+=item isa

  # declare type constraint

  isa => 'StrObject'
  isa => 'ArrayObject'
  isa => 'CodeObject'

The C<isa> directive is used to define the type constraint to validate the
attribute against. See the L<Moo> documentation for more details.

+=item req|required

  # required attribute

  req => 1
  required => 1

The C<required> directive is used to denote if an attribute is required or
optional. See the L<Moo> documentation for more details.

+=item opt|optional

  # optional attribute

  opt => 1
  optional => 1

The C<optional> directive is used to denote if an attribute is optional or
required. See the L<Moo> documentation for more details.

+=item bld|builder

  # build value

  bld => $builder
  builder => $builder

The C<builder> directive expects a coderef and builds the attribute value if it
wasn't provided to the constructor. See the L<Moo> documentation for more
details.

+=item clr|clearer

  # create clear_${attribute}

  clr => $clearer
  clearer => $clearer

The C<clearer> directive expects a coderef and generates a clearer method. See
the L<Moo> documentation for more details.

+=item crc|coerce

  # coerce value

  crc => 1
  coerce => 1

The C<coerce> directive denotes whether an attribute's value should be
automatically coerced. See the L<Moo> documentation for more details.

+=item def|default

  # default value

  def => $default
  default => $default

The C<default> directive expects a coderef and is used to build a default value
if one is not provided to the constructor. See the L<Moo> documentation for
more details.

+=item hnd|handles

  # dispatch to value

  hnd => $handles
  handles => $handles

The C<handles> directive denotes the methods created on the object which
dispatch to methods available on the attribute's object. See the L<Moo>
documentation for more details.

+=item lzy|lazy

  # lazy attribute

  lzy => 1
  lazy => 1

The C<lazy> directive denotes whether the attribute will be constructed
on-demand, or on-construction. See the L<Moo> documentation for more details.

+=item pre|predicate

  # create has_${attribute}

  pre => 1
  predicate => 1

The C<predicate> directive expects a coderef and generates a method for
checking the existance of the attribute. See the L<Moo> documentation for more
details.

+=item rdr|reader

  # attribute reader

  rdr => $reader
  reader => $reader

The C<reader> directive denotes the name of the method to be used to "read" and
return the attribute's value. See the L<Moo> documentation for more details.

+=item tgr|trigger

  # attribute trigger

  tgr => $trigger
  trigger => $trigger

The C<trigger> directive expects a coderef and is executed whenever the
attribute's value is changed. See the L<Moo> documentation for more details.

+=item wkr|weak_ref

  # weaken ref

  wkr => 1
  weak_ref => 1

The C<weak_ref> directive is used to denote if the attribute's value should be
weakened. See the L<Moo> documentation for more details.

+=item wrt|writer

  # attribute writer

  wrt => $writer
  writer => $writer

The C<writer> directive denotes the name of the method to be used to "write"
and return the attribute's value. See the L<Moo> documentation for more
details.

+=back

=cut

use_ok "Data::Object::ClassHas";

ok 1 and done_testing;
