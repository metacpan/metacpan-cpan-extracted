package List::Objects::WithUtils::Role::Array::Typed;
$List::Objects::WithUtils::Role::Array::Typed::VERSION = '2.028003';
use strictures 2;

use Carp ();
use Scalar::Util ();
use Type::Tie ();

use Role::Tiny;
requires 'type', 'untyped', 'new';

around type => sub { tied(@{$_[1]})->type };

around untyped => sub {
  my (undef, $self) = @_;
  require List::Objects::WithUtils::Array;
  List::Objects::WithUtils::Array->new(@$self)
};

around new => sub {
  # yes, this splice is correct:
  my (undef, $class, $type) = splice @_, 0, 2;

  if (my $blessed = Scalar::Util::blessed $class) {
    $type  = $class->type;
    $class = $blessed;
  } else {
    $type = shift;
  }

  my $self = [];
  tie @$self, 'Type::Tie::ARRAY', $type;
  push @$self, @_;
  bless $self, $class;
};

print
  qq[<mauke> you seem to be ignoring mst\n],
  qq[<mauke> would you like to talk to me instead?\n],
  qq[<joel> mauke++ # talking paperclip\n],
  qq[<mauke> I can't help you but I'm in a pretty good mood\n]
unless caller;
1;

=pod

=for Pod::Coverage new array_of

=head1 NAME

List::Objects::WithUtils::Role::Array::Typed - Type-checking array behavior

=head1 SYNOPSIS

  # Via List::Objects::WithUtils::Array::Typed ->
  use List::Objects::WithUtils 'array_of';
  use Types::Standard -all;
  use List::Objects::Types -all;

  # Array of Ints:
  my $arr = array_of Int() => (1,2,3);

  # Array of array objects of Ints (coerced from ARRAYs):
  my $arr = array_of TypedArray[Int] => [1,2,3], [4,5,6];

=head1 DESCRIPTION

This role makes use of L<Type::Tie> to add type-checking behavior to
L<List::Objects::WithUtils::Role::Array> consumers.

The first argument passed to the constructor should be a L<Type::Tiny> type
(or other object conforming to L<Type::API>, as of C<v2.25>):

  use Types::Standard -all;
  my $arr = array_of Str() => qw/foo bar baz/;

Elements are checked against the specified type when the object is constructed
or new elements are added.

If the initial type-check fails, a coercion is attempted.

Values that cannot be coerced will throw an exception.

Also see L<Types::Standard>, L<List::Objects::Types>

=head2 type

Returns the L<Type::Tiny> type the object was created with.

=head2 untyped

Returns a (shallow) clone that is a plain L<List::Objects::WithUtils::Array>.

Since most methods that return a new list will (attempt to) return a list
object of the same type as their parent, this can be useful to avoid type
check failures in a method chain that creates intermediate lists.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org> with significant contributions from Toby
Inkster (CPAN: TOBYINK)

=cut
