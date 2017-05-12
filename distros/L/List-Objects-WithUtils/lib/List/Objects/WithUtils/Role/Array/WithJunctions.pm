package List::Objects::WithUtils::Role::Array::WithJunctions;
$List::Objects::WithUtils::Role::Array::WithJunctions::VERSION = '2.028003';
use strictures 2;

use List::Objects::WithUtils::Array::Junction ();

use Role::Tiny;

sub any_items {
  List::Objects::WithUtils::Array::Junction::Any->new( @{ $_[0] } )
}

sub all_items {
  List::Objects::WithUtils::Array::Junction::All->new( @{ $_[0] } )
}

1;

=pod

=head1 NAME

List::Objects::WithUtils::Role::Array::WithJunctions - Add junctions

=head1 SYNOPSIS

  ## Via List::Objects::WithUtils::Array ->
  use List::Objects::WithUtils 'array';

  my $array = array(qw/ a b c /);

  if ( $array->any_items eq 'b' ) {
    ...
  }

  if ( $array->all_items eq 'a' ) {
    ...
  }

  if ( $array->any_items == qr/^b/ ) {
    ...
  }

  ## As a Role ->
  use Role::Tiny::With;
  with 'List::Objects::WithUtils::Role::Array',
       'List::Objects::WithUtils::Role::Array::WithJunctions';

=head1 DESCRIPTION

These methods supply overloaded L<List::Objects::WithUtils::Array::Junction>
objects that can be compared with values using normal Perl comparison
operators.

Regular expressions can be matched by providing a C<qr//> regular expression
object to the C<==> or C<!=> operators.

There is no support for the C<~~> experimental smart-match operator.

The junction objects returned are subclasses of
L<List::Objects::WithUtils::Array>, allowing manipulation of junctions (of
varying degrees of sanity) -- a simple case might be generating a new junction
out of an old junction:

  my $list = array(3, 4, 5);
  if ( (my $anyof = $list->any_items) > 2 ) {
    my $incr = $anyof->map(sub { $_[0] + 1 })->all_items;
    if ( $incr > 6 ) {
      # ...
    }
    # Drop junction magic again:
    my $plain = array( $incr->all );
  }

=head2 any_items

Returns the overloaded B<any> object for the current array; a comparison is
true if any items in the array satisfy the condition.

=head2 all_items

Returns the overloaded B<all> object for the current array; a comparison is
true only if all items in the array satisfy the condition.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
