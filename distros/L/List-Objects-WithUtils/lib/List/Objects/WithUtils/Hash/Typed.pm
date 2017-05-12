package List::Objects::WithUtils::Hash::Typed;
$List::Objects::WithUtils::Hash::Typed::VERSION = '2.028003';
use strictures 2;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Hash
    List::Objects::WithUtils::Role::Hash::Typed
  /
);

use Exporter ();
our @EXPORT = 'hash_of';

sub import {
  my $pkg = caller;
  { no strict 'refs';
    ${"${pkg}::a"} = ${"${pkg}::a"}; ${"${pkg}::b"} = ${"${pkg}::b"};
  }
  goto &Exporter::import
}

sub hash_of { __PACKAGE__->new(@_) }

1;


=pod

=head1 NAME

List::Objects::WithUtils::Hash::Typed - Type-checking hash objects

=head1 SYNOPSIS

  use List::Objects::WithUtils 'hash_of';

  use Types::Standard -all;

  my $arr = hash_of Int() => ( foo => 1, bar => 2 );

=head1 DESCRIPTION

These are type-checking hash objects; values are checked against the specified
type when the object is constructed or new elements are added.

The first argument passed to the constructor should be a L<Type::Tiny> type:

  use Types::Standard -all;
  my $hash = hash_of Int() => ( foo => 1 );

If the initial type-check fails, a coercion is attempted.

This class consumes the following roles, which contain most of the relevant
documentation:

L<List::Objects::WithUtils::Role::Hash>

L<List::Objects::WithUtils::Role::Hash::Typed>

Also see L<Types::Standard>, L<List::Objects::Types>

=head2 hash_of

Creates a new typed hash object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org> with significant contributions from Toby
Inkster (CPAN: TOBYINK)

=cut
