package List::Objects::WithUtils::Hash::Immutable;
$List::Objects::WithUtils::Hash::Immutable::VERSION = '2.028003';
use strictures 2;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Hash
    List::Objects::WithUtils::Role::Hash::Immutable
  /,
);

use Exporter ();
our @EXPORT = 'immhash';

sub import {
  my $pkg = caller;
  { no strict 'refs';
    ${"${pkg}::a"} = ${"${pkg}::a"}; ${"${pkg}::b"} = ${"${pkg}::b"};
  }
  goto &Exporter::import
}

sub immhash { __PACKAGE__->new(@_) }

1;

=pod

=head1 NAME

List::Objects::WithUtils::Hash::Immutable - Immutable hash objects

=head1 SYNOPSIS

  use List::Objects::WithUtils 'immhash';
  my $hash = immhash( foo => 1, bar => 2 );

=head1 DESCRIPTION

These are immutable hash objects; attempting to call list-mutating methods
(or modify the backing hash directly) will throw an exception.

This class consumes the following roles, which contain most of the relevant
documentation:

L<List::Objects::WithUtils::Role::Hash>

L<List::Objects::WithUtils::Role::Hash::Immutable>

(See L<List::Objects::WithUtils::Hash> for a mutable implementation.)

=head2 immhash

Creates a new immutable hash object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
