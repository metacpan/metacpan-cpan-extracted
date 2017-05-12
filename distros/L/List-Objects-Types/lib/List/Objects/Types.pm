package List::Objects::Types;
$List::Objects::Types::VERSION = '2.001001';
use strict; use warnings;

use List::Util ();

use Type::Library   -base;
use Type::Utils     -all;
use Types::Standard -types;
use Types::TypeTiny ();

use List::Objects::WithUtils;

# FIXME reorg wrt Immutable types;
#   ::WithUtils needs v3 role reorg wrt moving common methods
#   -> declare ArrayObj as ImmutableArray & HashObj as ImmutableHash

declare ArrayObj =>
  as ConsumerOf[ 'List::Objects::WithUtils::Role::Array' ];

coerce ArrayObj =>
  from ArrayRef() => via { array(@$_) };


declare ImmutableArray =>
  as ArrayObj(),
  where     { $_->does('List::Objects::WithUtils::Role::Array::Immutable') },
  inline_as { 
    (undef, qq[$_->does('List::Objects::WithUtils::Role::Array::Immutable')]) 
  };

coerce ImmutableArray =>
  from ArrayRef() => via { immarray(@$_) },
  from ArrayObj() => via { immarray($_->all) };


declare TypedArray =>
  as ConsumerOf[ 'List::Objects::WithUtils::Role::Array::Typed' ],
  constraint_generator => sub {
    my $param = Types::TypeTiny::to_TypeTiny(shift);
    sub { $_->type->equals($param) }
  },
  coercion_generator => sub {
    my ($parent, $child, $param) = @_;
    my $c = Type::Coercion->new(type_constraint => $child);
    if ($param->has_coercion) {
      my $inner = $param->coercion;
      $c->add_type_coercions(
        ArrayRef() => sub { array_of($param, map {; $inner->coerce($_) } @$_) },
        ArrayObj() => sub { array_of($param, map {; $inner->coerce($_) } $_->all) },
      );
    } else {
      $c->add_type_coercions(
        ArrayRef() => sub { array_of($param, @$_) },
        ArrayObj() => sub { array_of($param, $_->all) },
      );
    }

    $c->freeze
  };

declare ImmutableTypedArray =>
  as InstanceOf[ 'List::Objects::WithUtils::Array::Immutable::Typed' ],
  constraint_generator => sub {
    my $param = Types::TypeTiny::to_TypeTiny(shift);
    sub { $_->type->is_a_type_of($param) }
  },
  coercion_generator => sub {
    my ($parent, $child, $param) = @_;
    my $c = Type::Coercion->new( type_constraint => $child );
    if ($param->has_coercion) {
      my $inner = $param->coercion;
      $c->add_type_coercions(
        ArrayRef() => sub { 
          immarray_of($param, map {; $inner->coerce($_) } @$_)
        },
        ArrayObj() => sub {
          immarray_of($param, map {; $inner->coerce($_) } $_->all)
        },
      );
    } else {
      $c->add_type_coercions(
        ArrayRef() => sub { immarray_of($param, @$_) },
        ArrayObj() => sub { immarray_of($param, $_->all) },
      );
    }
  };

declare HashObj =>
  as ConsumerOf[ 'List::Objects::WithUtils::Role::Hash' ];

coerce HashObj =>
  from HashRef() => via { hash(%$_) };


declare ImmutableHash =>
  as HashObj(),
  where     { $_->does('List::Objects::WithUtils::Role::Hash::Immutable') },
  inline_as {
    (undef, qq[$_->does('List::Objects::WithUtils::Role::Hash::Immutable')])
  };

coerce ImmutableHash =>
  from HashRef() => via { immhash(%$_) },
  from HashObj() => via { immhash($_->export) };


declare InflatedHash =>
  as InstanceOf['List::Objects::WithUtils::Hash::Inflated'],
  constraint_generator => sub {
    my @params = @_;
    sub { 
      Scalar::Util::blessed $_
        and not List::Util::first { !$_[0]->can($_) } @params
    }
  };

coerce InflatedHash =>
  from HashRef() => via { hash(%$_)->inflate },
  from HashObj() => via { $_->inflate };


declare TypedHash =>
  as ConsumerOf[ 'List::Objects::WithUtils::Role::Hash::Typed' ],
  constraint_generator => sub {
    my $param = Types::TypeTiny::to_TypeTiny(shift);
    sub { $_->type->equals($param) }
  },
  coercion_generator => sub {
    my ($parent, $child, $param) = @_;
    my $c = Type::Coercion->new(type_constraint => $child);
    if ($param->has_coercion) {
      my $inner = $param->coercion;
      $c->add_type_coercions(
        HashRef() => sub {
          my %old = %$_; my %new;
          @new{keys %old} = map {; $inner->coerce($_) } values %old;
          hash_of($param, %new)
        },
        HashObj() => sub { 
          my %old = $_->export; my %new;
          @new{keys %old} = map {; $inner->coerce($_) } values %old;
          hash_of($param, %new)
        },
      );
    } else {
      $c->add_type_coercions(
        HashRef() => sub { hash_of($param, %$_) },
        HashObj() => sub { hash_of($param, $_->export) },
      );
    }

 
    $c->freeze
  };


declare ImmutableTypedHash =>
  as InstanceOf[ 'List::Objects::WithUtils::Hash::Immutable::Typed' ],
  constraint_generator => sub {
    my $param = Types::TypeTiny::to_TypeTiny(shift);
    sub { $_->type->is_a_type_of($param) }
  },
  coercion_generator => sub {
    my ($parent, $child, $param) = @_;
    my $c = Type::Coercion->new(type_constraint => $child);
    if ($param->has_coercion) {
      my $inner = $param->coercion;
      $c->add_type_coercions(
        HashRef() => sub {
          my %old = %$_; my %new;
          @new{keys %old} = map {; $inner->coerce($_) } values %old;
          immhash_of($param, %new)
        },
        HashObj() => sub { 
          my %old = $_->export; my %new;
          @new{keys %old} = map {; $inner->coerce($_) } values %old;
          immhash_of($param, %new)
        },
      );
    } else {
      $c->add_type_coercions(
        HashRef() => sub { immhash_of($param, %$_) },
        HashObj() => sub { immhash_of($param, $_->export) },
      );
    }

 
    $c->freeze
  };

1;


=pod

=head1 NAME

List::Objects::Types - Type::Tiny-based types for List::Objects::WithUtils

=head1 SYNOPSIS

  package Foo;

  use List::Objects::Types -all;
  use List::Objects::WithUtils;
  use Moo 2;  # version 2+ for better Type::Tiny support

  has my_array => (
    is  => 'ro',
    isa => ArrayObj,
    default => sub { array }
  );

  has static_array => (
    is  => 'ro',
    isa => ImmutableArray,
    coerce  => 1,
    default => sub { [qw/ foo bar /] }
  );

  has my_hash => (
    is  => 'ro',
    isa => HashObj,
    coerce  => 1,
    # Coercible from a plain HASH:
    default => sub { +{} }
  );

  use Types::Standard 'Int', 'Num';
  has my_ints => (
    is  => 'ro',
    # Nums added to this array_of(Int) are coerced to Ints:
    isa => TypedArray[ Int->plus_coercions(Num, 'int($_)') ],
    coerce  => 1,
    default => sub { [1, 2, 3.14] }
  );

=head1 DESCRIPTION

A set of L<Type::Tiny>-based types & coercions matching the list objects found
in L<List::Objects::WithUtils>.

=head3 ArrayObj

An object that consumes L<List::Objects::WithUtils::Role::Array>.

Can be coerced from a plain ARRAY; a shallow copy is performed.

=head3 HashObj

An object that consumes L<List::Objects::WithUtils::Role::Hash>.

Can be coerced from a plain HASH; a shallow copy is performed.

=head3 ImmutableArray

An object that consumes L<List::Objects::WithUtils::Role::Array::Immutable>.

Can be coerced from a plain ARRAY or an L</ArrayObj>; a shallow copy is performed.

=head3 TypedArray

An object that consumes L<List::Objects::WithUtils::Role::Array::Typed>.

Not coercible.

=head3 TypedArray[`a]

TypedArray can be parameterized with another type constraint specifying the
type of its values. 

Can be coerced from a plain ARRAY or an L</ArrayObj>; a shallow copy is
performed. If the parameter also has a coercion, this will be applied
to each item in the new array.

In versions prior to C<v2.x>, subtypes were permitted; C<< TypedArray[Num] >>
would accept C<< array_of(Num, 1, 2, 3.14) >> as expected, but also C<<
array_of(Int, 1, 2, 3) >> as C<Int> is a subtype C<Num>. This could lead to
unexpected behavior. As of C<v2.1.1>, this has been corrected; the latter
would be rejected without an appropriate coercion (for example, specifying C<<
coerce => 1 >> in a Moo(se) attribute along these lines will coerce the
C<Int>-typed array object to C<Num>)

(The C<examples/> directory that comes with this distribution contains some
examples of parameterized & coercible TypedArrays.)

=head3 ImmutableTypedArray

An object that isa L<List::Objects::WithUtils::Array::Immutable::Typed>.

Not coercible.

=head3 ImmutableTypedArray[`a]

ImmutableTypedArray can be parameterized with another type constraint, like
L</TypedArray> (however unlike its mutable counterpart, subtypes are
accepted).

Can be coerced from a plain ARRAY or an L</ArrayObj>.

=head3 TypedHash

An object that consumes L<List::Objects::WithUtils::Role::Hash::Typed>.

Not coercible.

=head3 TypedHash[`a]

TypedHash can be parameterized with another type constraint, like
L</TypedArray>.

Can be coerced from a plain HASH or a L</HashObj>. If the parameter also has a
coercion, this will be applied to each value in the new hash.

=head3 ImmutableTypedHash

An object that isa L<List::Objects::WithUtils::Hash::Immutable::Typed>.

Not coercible.

=head3 ImmutableTypedHash[`a]

ImmutableTypedHash can be parameterized with another type constraint, like
L</TypedHash>.

Can be coerced from a plain HASH or an L</HashObj>.

=head3 InflatedHash

An object that isa L<List::Objects::WithUtils::Hash::Inflated>.

Can be coerced from a plain HASH or an L</HashObj>.

(Available from v1.2.1)

=head3 InflatedHash[`a]

InflatedHash can be parameterized with a list of methods expected to be
available.

(Available from v1.3.1)

=head2 SEE ALSO

L<MoopsX::ListObjects> for integration with L<Moops> class-building sugar.

L<List::Objects::WithUtils> for more on the relevant list objects.

L<Type::Tiny> for more on type methods & overloads.

L<Types::Standard> for a set of useful base types.

L<Type::Library> for details on importing types.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org> with significant contributions from Toby
Inkster (CPAN: TOBYINK)

=cut
