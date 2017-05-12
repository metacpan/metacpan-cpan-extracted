package List::Objects::WithUtils::Role::Array::Immutable;
$List::Objects::WithUtils::Role::Array::Immutable::VERSION = '2.028003';
use strictures 2;
use Carp ();
use Tie::Array ();

sub _make_unimp {
  my ($method) = @_;
  sub {
    local $Carp::CarpLevel = 1;
    Carp::croak "Method '$method' not implemented on immutable arrays"
  }
}

our @ImmutableMethods = qw/
  clear
  delete delete_when
  insert
  pop push
  rotate_in_place
  set
  shift unshift
  splice
/;

use Role::Tiny;
requires 'new', @ImmutableMethods;

around is_mutable => sub { () };

around new => sub {
  my ($orig, $class) = splice @_, 0, 2;
  my $self = $class->$orig(@_);

  # SvREADONLY behavior is not very reliable.
  # Remove mutable behavior from our backing tied array instead:

  # If we're already tied, something else is going on,
  # like we're a typed array.
  # Otherwise, tie a StdArray & push items.
  tie @$self, 'Tie::StdArray' and push @$self, @_
    unless tied @$self;

  Role::Tiny->apply_roles_to_object( tied(@$self),
    'List::Objects::WithUtils::Role::Array::TiedRO'
  );

  $self
};

around $_ => _make_unimp($_) for @ImmutableMethods;

print
 qq[<LeoNerd> Coroutines are not magic pixiedust\n],
 qq[<DrForr> LeoNerd: Any sufficiently advanced technology.\n],
 qq[<LeoNerd> DrForr: ... probably corrupts the C stack during XS calls? ;)\n],
unless caller;
1;

=pod

=head1 NAME

List::Objects::WithUtils::Role::Array::Immutable - Immutable array behavior

=head1 SYNOPSIS

  # Via List::Objects::WithUtils::Array::Immutable ->
  use List::Objects::WithUtils 'immarray';
  my $array = immarray(qw/ a b c /);
  $array->push('d');  # dies

=head1 DESCRIPTION

This role adds immutable behavior to L<List::Objects::WithUtils::Role::Array>
consumers.

The following methods are not available and will throw an exception:

  clear
  set
  pop push
  shift unshift
  delete delete_when
  insert
  rotate_in_place
  splice

(The backing array is also marked read-only.)

See L<List::Objects::WithUtils::Array::Immutable> for a consumer
implementation that also pulls in L<List::Objects::WithUtils::Role::Array> &
L<List::Objects::WithUtils::Role::Array::WithJunctions>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Licensed under the same terms as Perl.

=cut
