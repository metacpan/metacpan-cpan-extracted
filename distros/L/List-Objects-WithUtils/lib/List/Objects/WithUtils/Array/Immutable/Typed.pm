package List::Objects::WithUtils::Array::Immutable::Typed;
$List::Objects::WithUtils::Array::Immutable::Typed::VERSION = '2.028003';
use strictures 2;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Array
    List::Objects::WithUtils::Role::Array::WithJunctions
    List::Objects::WithUtils::Role::Array::Typed
    List::Objects::WithUtils::Role::Array::Immutable
  /,
);

use Exporter ();
our @EXPORT = 'immarray_of';

sub import {
  my $pkg = caller;
  { no strict 'refs';
    ${"${pkg}::a"} = ${"${pkg}::a"};
    ${"${pkg}::b"} = ${"${pkg}::b"};
  }
  goto &Exporter::import
}

sub immarray_of { __PACKAGE__->new(@_) }

1;

=pod

=for Pod::Coverage immarray_of

=head1 NAME

List::Objects::WithUtils::Array::Immutable::Typed - Immutable typed arrays

=head1 SYNOPSIS

  use List::Objects::WithUtils 'immarray_of';
  use Types::Standard -types;
  my $array = immarray_of( Int() => 1, 2, 3 );

=head1 DESCRIPTION

These are immutable type-checking array objects, essentially a combination of
L<List::Objects::WithUtils::Array::Typed> and
L<List::Objects::WithUtils::Array::Immutable>.

Type-checking is performed when the object is created; attempts to modify the
object will throw an exception.

This class consumes the following roles, which contain most of the relevant
documentation:

L<List::Objects::WithUtils::Role::Array>

L<List::Objects::WithUtils::Role::Array::WithJunctions>

L<List::Objects::WithUtils::Role::Array::Typed>

L<List::Objects::WithUtils::Role::Array::Immutable>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
