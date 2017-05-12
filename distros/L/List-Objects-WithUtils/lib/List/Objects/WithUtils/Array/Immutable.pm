package List::Objects::WithUtils::Array::Immutable;
$List::Objects::WithUtils::Array::Immutable::VERSION = '2.028003';
use strictures 2;

require Role::Tiny;
Role::Tiny->apply_roles_to_package( __PACKAGE__,
  qw/
    List::Objects::WithUtils::Role::Array
    List::Objects::WithUtils::Role::Array::WithJunctions
    List::Objects::WithUtils::Role::Array::Immutable
  /,
);

use Exporter ();
our @EXPORT = 'immarray';

sub import {
  my $pkg = caller;
  { no strict 'refs';
    ${"${pkg}::a"} = ${"${pkg}::a"};
    ${"${pkg}::b"} = ${"${pkg}::b"};
  }
  goto &Exporter::import
}

sub immarray { __PACKAGE__->new(@_) }

1;

=pod

=head1 NAME

List::Objects::WithUtils::Array::Immutable - Immutable array objects

=head1 SYNOPSIS

  use List::Objects::WithUtils 'immarray';

  my $array = immarray(qw/ a b c /);

  my ($head, $rest) = $array->head;

=head1 DESCRIPTION

These are immutable array objects; attempting to call list-mutating methods
(or modify the backing array directly) will throw an exception.

This class consumes the following roles, which contain most of the relevant
documentation:

L<List::Objects::WithUtils::Role::Array>

L<List::Objects::WithUtils::Role::Array::WithJunctions>

L<List::Objects::WithUtils::Role::Array::Immutable>

(See L<List::Objects::WithUtils::Array> for a mutable implementation.)

=head2 immarray

Creates a new immutable array object.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut
