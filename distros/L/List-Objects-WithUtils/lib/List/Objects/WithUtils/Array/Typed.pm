package List::Objects::WithUtils::Array::Typed;
$List::Objects::WithUtils::Array::Typed::VERSION = '2.028003';
use strictures 2;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Array
    List::Objects::WithUtils::Role::Array::WithJunctions
    List::Objects::WithUtils::Role::Array::Typed
  /,
);

use Exporter ();
our @EXPORT = 'array_of';

sub import {
  my $pkg = caller;
  { no strict 'refs';
    ${"${pkg}::a"} = ${"${pkg}::a"};
    ${"${pkg}::b"} = ${"${pkg}::b"};
  }
  goto &Exporter::import
}

sub array_of { __PACKAGE__->new(@_) }

1;

=pod

=for Pod::Coverage array_of

=head1 NAME

List::Objects::WithUtils::Array::Typed - Type-checking array objects

=head1 SYNOPSIS

  use List::Objects::WithUtils 'array_of';

  use Types::Standard -all;
  use List::Objects::Types -all;

  my $arr = array_of( Int() => 1 .. 10 );
  $arr->push('foo');    # dies, failed type check
  $arr->push(11 .. 15); # ok

  my $arr_of_arrs = array_of( ArrayObj );
  $arr_of_arrs->push([], []); # ok, coerces to ArrayObj

=head1 DESCRIPTION

These are type-checking array objects; elements are checked against the
specified type when the object is constructed or new elements are added.

The first argument passed to the constructor should be a L<Type::Tiny> type:

  use Types::Standard -all;
  my $arr = array_of Str() => qw/foo bar baz/;

If the initial type-check fails, a coercion is attempted.

This class consumes the following roles, which contain most of the relevant
documentation:

L<List::Objects::WithUtils::Role::Array>

L<List::Objects::WithUtils::Role::Array::WithJunctions>

L<List::Objects::WithUtils::Role::Array::Typed>

Also see L<Types::Standard>, L<List::Objects::Types>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org> with significant contributions from Toby
Inkster (CPAN: TOBYINK)

=cut
