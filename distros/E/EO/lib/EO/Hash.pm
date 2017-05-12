
package EO::Hash;

use strict;
use warnings;

use EO::Pair;
use EO::Array;
use EO::Collection;

our $VERSION = 0.96;
our @ISA = qw( EO::Collection );

use overload '%{}'      => 'get_reference',
             'fallback' => 1;

sub init {
  my $self  = CORE::shift;
  my $elems = CORE::shift;
  if ($self->SUPER::init( @_ )) {
    $self->element( {} );
    return 1;
  }
  return 0;
}

sub get_reference {
  my $self = shift;
  my $callpkg = caller();
  my $prefix  = substr($callpkg,0,4);
  if ($prefix eq 'EO::' || $prefix eq 'EO') {
    return $self;
  }
  return $self->element;
}

sub new_with_hash {
  my $class = shift;
  my $hash;
  if (@_ > 1) {
    $hash = { @_ };
  } else {
    $hash = shift;
  }
  if (!$hash) {
    throw EO::Error::InvalidParameters
      text => 'no hash provided';
  }
  if (!ref($hash)) {
    throw EO::Error::InvalidParameters
      text => 'not a reference';
  }
  if (ref($hash) && ref($hash) ne 'HASH') {
    throw EO::Error::InvalidParameters
      text => 'not a hash reference';
  }
  my $self = $class->new();
  $self->element( $hash );
  return $self;
}

sub at {
  my $self = shift;
  my $key  = shift;
  if (!$key) {
    throw EO::Error::InvalidParameters
      text => 'no key specified for at';
  }
  if (@_) {
    $self->element->{ $key } = shift;
    return $self;
  }
  return $self->element->{ $key };
}

sub pair_for {
  my $self = shift;
  my $key  = shift;
  return EO::Pair->new
                 ->key( $key )
		 ->value( $self->at( $key ) );
}

sub do {
  my $self = shift;
  my $code = shift;
  unless( $code and ref($code) eq 'CODE') {
    throw EO::Error::InvalidParameters
      text => 'must have a code reference as a parameter';
  }
  my $hash = ref($self)->new();
  foreach my $key (keys %{ $self->element }) {
    my $pair = $self->pair_for( $key );
    $hash->add( $pair->do( $code ) );
  }
  return $hash;
}

sub select {
  my $self = shift;
  my $code = shift;
  unless( $code and ref($code) eq 'CODE') {
    throw EO::Error::InvalidParameters
      text => 'must have a code reference as a parameter';
  }
  my $hash = ref($self)->new();
  foreach my $key (keys %{ $self->element }) {
    my $pair = $self->pair_for( $key );
    if ( $pair->do( $code ) ) {
      $hash->add( $pair );
    }
  }
  return $hash;
}

sub add {
  my $self = shift;
  my $pair = shift;
  if (!$pair or !$pair->isa('EO::Pair')) {
    throw EO::Error::InvalidParameters
      text => 'argument to add must be a pair';
  }
  $self->at( $pair->key, $pair->value );
}

sub object_at_index : Deprecated {
  my $self = shift;
  $self->at( @_ );
}

sub delete {
  my $self = shift;
  my $key  = shift;
  if (!$key) {
    throw EO::Error::InvalidParameters text => 'no key specified for delete';
  }
  delete $self->element->{ $key };
}

sub count {
  my $self = shift;
  $self->keys->count;
}

sub iterator {
  my $self = shift;
  my %iter = %{$self->element };
  return %iter;
}

sub keys {
  my $self = shift;
  my %hash = $self->iterator;
  if (!wantarray) {
    my $array = EO::Array->new()->push( keys %hash );
    return $array;
  } else {
    return keys %hash;
  }
}

sub values {
  my $self = shift;
  my %hash = $self->iterator;
  if (!wantarray) {
    my $array = EO::Array->new()->push( values %hash );
    return $array;
  } else {
    return values %hash;
  }
}

sub has {
  my $self = shift;
  my $key  = shift;
  exists $self->element->{ $key }
}

1;

__END__

=head1 NAME

EO::Hash - hash type collection

=head1 SYNOPSIS

  use EO::Hash;

  $hash = EO::Hash->new();
  $hash->at( 'foo', 'bar' );
  my $thing = $hash->at( 'foo' );

  print "ok\n" if $thing->has( 'foo' );

  $thing->delete( 'foo' );

  my $keys  = $hash->keys;
  my $vals  = $hash->values;

  my $count = $hash->count;

  my %hash = %$hash;

=head1 DESCRIPTION

EO::Hash is an OO wrapper around Perl's hash type.  Objects of the hash
class will act as a normal hash outside of any class that does not have an
'EO::' prefix.

=head1 INHERITANCE

EO::Hash inherits from EO::Collection.

=head1 CONSTRUCTOR

EO::Hash provides the following constructors beyond those that the parent
class provides:

=over 4

=item new_with_hash( HASHREF )

Prepares a EO::Hash object that has all the elements contained in HASHREF.

=back

=head1 METHODS

=over 4

=item has( KEY )

Returns true if the key exists inside the hash

=item add( EO::Pair )

Adds a pair to the hash.

=item pair_for( KEY )

Returns an EO::Pair object for the key value pair at KEY.

=item do( CODE )

Runs the coderef CODE for each pair in the EO::Hash object.  It passes CODE
the EO::Pair object as both its first argument and as $_.  CODE must return a
pair object.  The do method returns an EO::Hash which has all the pairs that
are returned from CODE.

=item select( CODE )

Runs the coderef CODE for each pair in the EO::Hash object.  It passes CODE
the EO::Pair object as both its first argument and as $_.  If the result of
running the code is true, then the pair is added to a new EO::Hash object
which is returned.

=item at( KEY [, VALUE] )

Gets and sets key value pairs.  KEY should always be a string.  If provided
VALUE will be placed in the EO::Hash object at the key KEY.

=item delete( KEY )

Deletes a key/value pair, indexed by key, from the EO::Hash object.

=item count

Returns an integer representing the number of key/value pairs in the EO::Hash
object.

=item iterator

Returns a Perl hash.

=item keys

In scalar context returns an EO::Array object of keys in the EO::Hash.  In list
context it returns a Perl array of keys in the EO::Hash.

=item values

In scalar context returns an EO::Array object of values in the EO::Hash.  In list
context it returns a Perl array of values in the EO::Hash.

=back

=head1 SEE ALSO

EO::Collection, EO::Array

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This module is released under the same terms as Perl itself.

=cut

