package List::Objects::WithUtils::Hash::Immutable::Typed;
$List::Objects::WithUtils::Hash::Immutable::Typed::VERSION = '2.028003';
use strictures 2;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Hash
    List::Objects::WithUtils::Role::Hash::Typed
    List::Objects::WithUtils::Role::Hash::Immutable
  /
);

use Exporter ();
our @EXPORT = 'immhash_of';

sub import {
  my $pkg = caller;
  { no strict 'refs';
    ${"${pkg}::a"} = ${"${pkg}::a"}; ${"${pkg}::b"} = ${"${pkg}::b"};
  }
  goto &Exporter::import
}

sub immhash_of { __PACKAGE__->new(@_) }

1;

=pod

=head1 NAME

List::Objects::WithUtils::Hash::Immutable::Typed - Immutable typed hashes

=head1 SYNOPSIS

  use List::Objects::WithUtils 'immhash_of';
  use Types::Standard -types;
  my $hash = immhash_of Int() => ( foo => 1, bar => 2 );

=head1 DESCRIPTION

These are immutable type-checking hash objects, essentially a combination of
L<List::Objects::WithUtils::Hash::Typed> and
L<List::Objects::WithUtils::Hash::Immutable>.

Type-checking is performed when
the object is created; attempts to modify the object will throw an exception.

This class consumes the following roles, which contain most of the relevant
documentation:

L<List::Objects::WithUtils::Role::Hash>

L<List::Objects::WithUtils::Role::Hash::Typed>

L<List::Objects::WithUtils::Role::Hash::Immutable>

=head2 immhash_of

Creates a new immutable typed hash object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
