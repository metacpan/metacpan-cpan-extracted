package List::Objects::WithUtils::Role::Hash::Immutable;
$List::Objects::WithUtils::Role::Hash::Immutable::VERSION = '2.028003';
use strictures 2;
use Carp ();
use Tie::Hash ();

sub _make_unimp {
  my ($method) = @_;
  sub {
    local $Carp::CarpLevel = 1;
    Carp::croak "Method '$method' not implemented on immutable hashes"
  }
}

our @ImmutableMethods = qw/
  clear
  set
  maybe_set
  delete
/;

use Role::Tiny;
requires 'new', @ImmutableMethods;

around is_mutable => sub { () };

around new => sub {
  my ($orig, $class) = splice @_, 0, 2;
  my $self = $class->$orig(@_);

  # This behavior changed in c. 45f59a73 --
  # we can revert back if Hash::Util gains the flexibility discussed on p5p
  # (lock_keys without an exception on unknown key retrieval)
  # For now, take the tie performance hit :(
  tie %$self, 'Tie::StdHash' and %$self = @_
    unless tied %$self;

  Role::Tiny->apply_roles_to_object( tied(%$self),
    'List::Objects::WithUtils::Role::Hash::TiedRO'
  );

  $self
};

around $_ => _make_unimp($_) for @ImmutableMethods;

1;

=pod

=head1 NAME

List::Objects::WithUtils::Role::Hash::Immutable - Immutable hash behavior

=head1 SYNOPSIS

  # Via List::Objects::WithUtils::Hash::Immutable ->
  use List::Objects::WithUtils 'immhash';
  my $hash = immhash( foo => 1, bar => 2 );
  $hash->set(foo => 3);  # dies

=head1 DESCRIPTION

This role adds immutable behavior to L<List::Objects::WithUtils::Role::Hash>
consumers.

The following methods are not available and will throw an exception:

  clear
  set
  maybe_set
  delete

(The backing hash is also marked read-only.)

See L<List::Objects::WithUtils::Hash::Immutable> for a consumer
implementation.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
