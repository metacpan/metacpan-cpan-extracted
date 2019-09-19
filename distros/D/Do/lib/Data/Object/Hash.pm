package Data::Object::Hash;

use 5.014;

use strict;
use warnings;

use Role::Tiny::With;

use overload (
  '""'     => 'detract',
  '~~'     => 'detract',
  '%{}'    => 'self',
  fallback => 1
);

with qw(
  Data::Object::Role::Dumpable
  Data::Object::Role::Functable
  Data::Object::Role::Throwable
);

use parent 'Data::Object::Hash::Base';

our $VERSION = '1.80'; # VERSION

# METHODS

sub self {
  return shift;
}

sub list {
  my ($self) = @_;

  my @args = (map $self->deduce($_), %$self);

  return wantarray ? (@args) : $self->deduce([@args]);
}

1;

=encoding utf8

=head1 NAME

Data::Object::Hash

=cut

=head1 ABSTRACT

Data-Object Hash Class

=cut

=head1 SYNOPSIS

  use Data::Object::Hash;

  my $hash = Data::Object::Hash->new({1..4});

=cut

=head1 DESCRIPTION

This package provides routines for operating on Perl 5 hash references.

=cut

=head1 INHERITANCE

This package inherits behaviors from:

L<Data::Object::Hash::Base>

=cut

=head1 INTEGRATIONS

This package integrates behaviors from:

L<Data::Object::Role::Dumpable>

L<Data::Object::Role::Functable>

L<Data::Object::Role::Throwable>

=cut

=head1 LIBRARIES

This package uses type constraints defined by:

L<Data::Object::Library>

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 clear

  clear() : ArrayObject

The clear method is an alias to the empty method. This method returns a
L<Data::Object::Hash> object. This method is an alias to the empty method.

=over 4

=item clear example

  # given {1..8}

  $hash->clear; # {}

=back

=cut

=head2 count

  count() : NumObject

The count method returns the total number of keys defined. This method returns
a L<Data::Object::Number> object.

=over 4

=item count example

  # given {1..4}

  my $count = $hash->count; # 2

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the value matching the key specified in the
argument if defined, otherwise returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given {1..8,9,undef}

  $hash->defined(1); # 1; true
  $hash->defined(0); # 0; false
  $hash->defined(9); # 0; false

=back

=cut

=head2 delete

  delete(Num $arg1) : Any

The delete method returns the value matching the key specified in the argument
and returns the value. This method returns a data type object to be determined
after execution.

=over 4

=item delete example

  # given {1..8}

  $hash->delete(1); # 2

=back

=cut

=head2 each

  each(CodeRef $arg1, Any @args) : Any

The each method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key and value at
the current position in the loop. This method returns a L<Data::Object::Hash>
object.

=over 4

=item each example

  # given {1..8}

  $hash->each(fun ($key, $value) {
      ...
  });

=back

=cut

=head2 each_key

  each(CodeRef $arg1, Any @args) : Any

The each_key method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key at the current
position in the loop. This method returns a L<Data::Object::Hash> object.

=over 4

=item each_key example

  # given {1..8}

  $hash->each_key(fun ($key) {
      ...
  });

=back

=cut

=head2 each_n_values

  each(Num $arg1, CodeRef $arg2, Any @args) : Any

The each_n_values method iterates over each element in the hash, executing the
code reference supplied in the argument, passing the routine the next n values
until all values have been seen. This method returns a L<Data::Object::Hash>
object.

=over 4

=item each_n_values example

  # given {1..8}

  $hash->each_n_values(4, fun (@values) {
      $values[1] # 2
      $values[2] # 4
      $values[3] # 6
      $values[4] # 8
      ...
  });

=back

=cut

=head2 each_value

  each(CodeRef $arg1, Any @args) : Any

The each_value method iterates over each element in the hash, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop. This method returns a L<Data::Object::Hash>
object.

=over 4

=item each_value example

  # given {1..8}

  $hash->each_value(fun ($value) {
      ...
  });

=back

=cut

=head2 empty

  empty() : Object

The empty method drops all elements from the hash. This method returns a
L<Data::Object::Hash> object. Note: This method modifies the hash.

=over 4

=item empty example

  # given {1..8}

  $hash->empty; # {}

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item eq example

  # given $hash

  $hash->eq; # exception thrown

=back

=cut

=head2 exists

  exists(Num $arg1) : DoNUm

The exists method returns true if the value matching the key specified in the
argument exists, otherwise returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item exists example

  # given {1..8,9,undef}

  $hash->exists(1); # 1; true
  $hash->exists(0); # 0; false

=back

=cut

=head2 filter_exclude

  filter_exclude(Str @args) : HashObject

The filter_exclude method returns a hash reference consisting of all key/value
pairs in the hash except for the pairs whose keys are specified in the
arguments. This method returns a L<Data::Object::Hash> object.

=over 4

=item filter_exclude example

  # given {1..8}

  $hash->filter_exclude(1,3); # {5=>6,7=>8}

=back

=cut

=head2 filter_include

  filter_include(Str @args) : HashObject

The filter_include method returns a hash reference consisting of only key/value
pairs whose keys are specified in the arguments. This method returns a
L<Data::Object::Hash> object.

=over 4

=item filter_include example

  # given {1..8}

  $hash->filter_include(1,3); # {1=>2,3=>4}

=back

=cut

=head2 fold

  fold(Str $arg1, HashRef $arg2, HashRef $arg3) : HashObject

The fold method returns a single-level hash reference consisting of key/value
pairs whose keys are paths (using dot-notation where the segments correspond to
nested hash keys and array indices) mapped to the nested values. This method
returns a L<Data::Object::Hash> object.

=over 4

=item fold example

  # given {3,[4,5,6],7,{8,8,9,9}}

  $hash->fold; # {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item ge example

  # given $hash

  $hash->ge; # exception thrown

=back

=cut

=head2 get

  get(Str $arg1) : Any

The get method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. This method returns a data
type object to be determined after execution.

=over 4

=item get example

  # given {1..8}

  $hash->get(5); # 6

=back

=cut

=head2 grep

  grep(CodeRef $arg1, Any $arg2) : ArrayObject

The grep method iterates over each key/value pair in the hash, executing the
code reference supplied in the argument, passing the routine the key and value
at the current position in the loop and returning a new hash reference
containing the elements for which the argument evaluated true. This method
returns a L<Data::Object::Hash> object.

=over 4

=item grep example

  # given {1..4}

  $hash->grep(fun ($value) {
      $value >= 3
  });

  # {3=>5}

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item gt example

  # given $hash

  $hash->gt; # exception thrown

=back

=cut

=head2 head

  head() : Any

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item head example

  # given $hash

  $hash->head; # exception thrown

=back

=cut

=head2 invert

  invert() : Any

The invert method returns the hash after inverting the keys and values
respectively. Note, keys with undefined values will be dropped, also, this
method modifies the hash. This method returns a L<Data::Object::Hash> object.
Note: This method modifies the hash.

=over 4

=item invert example

  # given {1..8,9,undef,10,''}

  $hash->invert; # {''=>10,2=>1,4=>3,6=>5,8=>7}

=back

=cut

=head2 iterator

  iterator() : CodeObject

The iterator method returns a code reference which can be used to iterate over
the hash. Each time the iterator is executed it will return the values of the
next element in the hash until all elements have been seen, at which point
the iterator will return an undefined value. This method returns a
L<Data::Object::Code> object.

=over 4

=item iterator example

  # given {1..8}

  my $iterator = $hash->iterator;
  while (my $value = $iterator->next) {
      say $value; # 2
  }

=back

=cut

=head2 join

  join() : StrObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item join example

  # given $hash

  $hash->join; # exception thrown

=back

=cut

=head2 keys

  keys() : ArrayObject

The keys method returns an array reference consisting of all the keys in the
hash. This method returns a L<Data::Object::Array> object.

=over 4

=item keys example

  # given {1..8}

  $hash->keys; # [1,3,5,7]

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item le example

  # given $hash

  $hash->le; # exception thrown

=back

=cut

=head2 length

  length() : NumObject

The length method returns the number of keys in the hash. This method
return a L<Data::Object::Number> object.

=over 4

=item length example

  # given {1..8}

  my $length = $hash->length; # 4

=back

=cut

=head2 list

  list() : ArrayObject

The list method returns a shallow copy of the underlying hash reference as an
array reference. This method return a L<Data::Object::Array> object.

=over 4

=item list example

  # given $hash

  my $list = $hash->list;

=back

=cut

=head2 lookup

  lookup(Str $arg1) : Any

The lookup method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. The key can be a string which
references (using dot-notation) nested keys within the hash. This method will
return undefined if the value is undef or the location expressed in the argument
can not be resolved. Please note, keys containing dots (periods) are not
handled. This method returns a data type object to be determined after
execution.

=over 4

=item lookup example

  # given {1..3,{4,{5,6,7,{8,9,10,11}}}}

  $hash->lookup('3.4.7'); # {8=>9,10=>11}
  $hash->lookup('3.4'); # {5=>6,7=>{8=>9,10=>11}}
  $hash->lookup(1); # 2

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item lt example

  # given $hash

  $hash->lt; # exception thrown

=back

=cut

=head2 map

  map(CodeRef $arg1, Any $arg2) : ArrayObject

The map method iterates over each key/value in the hash, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new hash reference containing the
elements for which the argument returns a value or non-empty list. This method
returns a L<Data::Object::Hash> object.

=over 4

=item map example

  # given {1..4}

  $hash->map(sub {
      shift + 1
  });

=back

=cut

=head2 merge

  merge() : HashObject

The merge method returns a hash reference where the elements in the hash and
the elements in the argument(s) are merged. This operation performs a deep
merge and clones the datasets to ensure no side-effects. The merge behavior
merges hash references only, all other data types are assigned with precendence
given to the value being merged. This method returns a L<Data::Object::Hash>
object.

=over 4

=item merge example

  # given {1..8}

  $hash->merge({7,7,9,9}); # {1=>2,3=>4,5=>6,7=>7,9=>9}

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item ne example

  # given $hash

  $hash->ne; # exception thrown

=back

=cut

=head2 pairs

  pairs() : ArrayObject

The pairs method is an alias to the pairs_array method. This method returns a
L<Data::Object::Array> object. This method is an alias to the pairs_array
method.

=over 4

=item pairs example

  # given {1..8}

  $hash->pairs; # [[1,2],[3,4],[5,6],[7,8]]

=back

=cut

=head2 reset

  reset() : HashObject

The reset method returns nullifies the value of each element in the hash. This
method returns a L<Data::Object::Hash> object. Note: This method modifies the
hash.

=over 4

=item reset example

  # given {1..8}

  $hash->reset; # {1=>undef,3=>undef,5=>undef,7=>undef}

=back

=cut

=head2 reverse

  reverse() : ArrayObject

The reverse method returns a hash reference consisting of the hash's keys and
values inverted. Note, keys with undefined values will be dropped. This method
returns a L<Data::Object::Hash> object.

=over 4

=item reverse example

  # given {1..8,9,undef}

  $hash->reverse; # {8=>7,6=>5,4=>3,2=>1}

=back

=cut

=head2 self

  self() : Object

The self method returns the calling object (noop).

=over 4

=item self example

  # given $hash

  my $self = $hash->self();

=back

=cut

=head2 set

  set(Str $arg1, Any $arg2) : Any

The set method returns the value of the element in the hash corresponding to
the key specified by the argument after updating it to the value of the second
argument. This method returns a data type object to be determined after
execution.

=over 4

=item set example

  # given {1..8}

  $hash->set(1,10); # 10
  $hash->set(1,12); # 12
  $hash->set(1,0); # 0

=back

=cut

=head2 slice

  slice(Any $arg1) : Any

The slice method returns a hash reference containing the elements in the hash
at the key(s) specified in the arguments. This method returns a
L<Data::Object::Hash> object.

=over 4

=item slice example

  # given {1..8}

  my $slice = $hash->slice(1,5); # {1=>2,5=>6}

=back

=cut

=head2 sort

  sort() : ArrayObject

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item sort example

  # given $hash

  $hash->sort; # exception thrown

=back

=cut

=head2 tail

  tail() : Any

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=over 4

=item tail example

  # given $hash

  $hash->tail; # exception thrown

=back

=cut

=head2 unfold

  unfold() : HashObject

The unfold method processes previously folded hash references and returns an
unfolded hash reference where the keys, which are paths (using dot-notation
where the segments correspond to nested hash keys and array indices), are used
to created nested hash and/or array references. This method returns a
L<Data::Object::Hash> object.

=over 4

=item unfold example

  # given {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

  $hash->unfold; # {3=>[4,5,6],7,{8,8,9,9}}

=back

=cut

=head2 values

  values(Str $arg1) : ArrayObject

The values method returns an array reference consisting of the values of the
elements in the hash. This method returns a L<Data::Object::Array> object.

=over 4

=item values example

  # given {1..8}

  $hash->values; # [2,4,6,8]
  $hash->values(1,3); # [2,4]

=back

=cut

=head1 CREDITS

Al Newkirk, C<+303>

Anthony Brummett, C<+10>

Adam Hopkins, C<+1>

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