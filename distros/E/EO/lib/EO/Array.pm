package EO::Array;

use strict;
use warnings;
use EO::Collection;

our $VERSION = 0.96;
our @ISA = qw( EO::Collection );

use overload '@{}' => 'get_reference',
             'fallback' => 1;

sub init {
  my $self = CORE::shift;
  if ($self->SUPER::init( @_ )) {
    $self->element( [] );
    return 1;
  }
  return 0;
}

sub get_reference {
  my $self = shift;
  return $self->element;
}

sub new_with_array {
  my $class = CORE::shift;
  my $array;
  if (@_ > 1) {
    $array = [ @_ ];
  } else {
    $array = CORE::shift;
    if (defined($array) && !ref($array)) {
      print "Not an array, making it one...\n";
      $array = [ $array ];
    }
  }
  if (!$array) {
    throw EO::Error::InvalidParameters text => 'no array specified';
  }
  if (!ref($array)) {
    throw EO::Error::InvalidParameters text => 'not a reference';
  }
  if (ref($array) && ref($array) ne 'ARRAY') {
    throw EO::Error::InvalidParameters text => 'not an array reference';
  }
  my $self = $class->new();
  $self->element( $array );
  return $self;
}

sub do {
  my $self = CORE::shift;
  my $code = CORE::shift;
  my $array = ref($self)->new();
  foreach my $element (@{ $self->element }) {
    local $_ = $element;
    $array->push( $code->( $element ) );
  }
  return $array;
}

sub reverse {
  my $self = CORE::shift;
  ref($self)->new_with_array( CORE::reverse( @{ $self->element } ) );
}

sub select {
  my $self = CORE::shift;
  my $code = CORE::shift;
  my $array = ref($self)->new();
  foreach my $element (@{ $self->element }) {
    local $_ = $element;
    $array->push( $element ) if $code->( $element );
  }
  return $array;
}

sub at {
  my $self = CORE::shift;
  my $idx  = CORE::shift;
  if (!defined($idx)) {
    throw EO::Error::InvalidParameters
      text => 'no index provided for the array';
  }
  if ($idx =~ /\D/) {
    throw EO::Error::InvalidParameters
      text => 'non-integer index specified';
  }
  if (@_) {
    $self->element->[ $idx ] = CORE::shift;
    return $self;
  }
  return $self->element->[ $idx ];
}

sub object_at_index : Deprecated {
  my $self = shift;
  $self->at( @_ );
}

sub delete {
  my $self = CORE::shift;
  my $idx  = CORE::shift;
  if (!defined($idx)) {
    throw EO::Error::InvalidParameters text => "no index provided for the array";
  }
  if ($idx =~ /\D/) {
    throw EO::Error::InvalidParameters text => 'non-integer index specified';
  }
  $self->splice( $idx, 1 );
}

sub splice {
  my $self = CORE::shift;
  my $offset = CORE::shift;
  my $length = CORE::shift;
  if (!@_ && $length) {

    return CORE::splice( @$self, $offset, $length );

  } elsif (!defined $length) {

    return CORE::splice( @$self, $offset );

  } elsif (!defined $offset) {

    return CORE::splice( @$self  );

  } else {

    return CORE::splice(@$self, $offset, $length, @_);

  }
}

sub count {
  my $self = CORE::shift;
  return scalar( $self->iterator );
}

sub push {
  my $self = CORE::shift;
  $self->splice( $self->count, 0, @_ );
  return $self;
}

sub pop {
  my $self = CORE::shift;
  $self->splice( -1 );
}

sub shift {
  my $self = CORE::shift;
  $self->splice( 0, 1 );
}

sub unshift {
  my $self = CORE::shift;
  $self->splice( 0, 0, @_ );
  return $self;
}

sub join {
  my $self = CORE::shift;
  my $joiner = CORE::shift;
  return join($joiner, $self->iterator);
}

sub iterator {
  my $self = CORE::shift;
  my @list = @{ $self->element };
  return @list;
}

1;

__END__

=head1 NAME

EO::Array - array type collection

=head1 SYNOPSIS

  use EO::Array;

  $array = EO::Array->new();
  $array->at( 0, 'bar' );

  my $thing = $array->at( 0 );
  $thing->delete( 0 );

  $array->push('value');
  my $value = $array->shift( $array->unshift( $array->pop() ) );

  my $count = $array->count;

  my @array = @$array;

=head1 DESCRIPTION

EO::Array is an OO wrapper around Perl's array type.  It will act both as
an object and as an array reference.

=head1 INHERITANCE

EO::Array inherits from EO::Collection.

=head1 CONSTRUCTOR

EO::Array provides the following constructors beyond those that the parent
class provides:

=over 4

=item new_with_array( ARRAYREF )

Prepares a EO::Array object that has all the elements contained in ARRAYREF.

=back

=head1 METHODS

=over 4

=item do( CODE )

The do method calls CODE with each of the elements of your array.  It sets
both $_ and the first argument passed to CODE as the element.  The return
value of CODE is added to a new array that is returned by the do method.

=item select( CODE )

The select method calls CODE with each of the elements of your array, it works
in a similar way to the do method.  The only difference is that if CODE returns
a true value, then the element is added to a new array which is returned from
the select method.

=item at( KEY [, VALUE] )

Gets and sets key value pairs.  KEY should always be an integer.  If provided
VALUE will be placed in the EO::Array object at the index KEY.

=item delete( KEY )

Deletes a key/value pair, indexed by key, from the EO::Array object.

=item count

Returns an integer representing the number of key/value pairs in the EO::Array
object.

=item iterator

Returns a Perl array.

=item pop

Removes an item from the end of the EO::Array and returns it

=item push( LIST )

Adds items on to the end of the EO::Array object

=item shift

Removes an item from the beginning of the EO::Array

=item unshift( LIST )

Adds items on to the beginning of the EO::Array object

=item splice( [OFFSET [, LENGTH [, LIST]]] )

Splice an array (see perldoc -f splice for more information).

=item reverse

Returns a new EO::Array object with the elements of the array reversed.

=back

=head1 SEE ALSO

EO::Collection, EO::Hash

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same terms as Perl itself.

=cut
