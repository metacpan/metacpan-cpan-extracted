package EO::Hierarchy;

use strict;
use warnings;

use EO::Hash;
use EO::delegate;
use base qw( EO );

our $VERSION = 0.96;

EO::Hierarchy->mk_accessors( qw( parent ) );

exception EO::Hierarchy::Error::NoParent;
exception EO::Hierarchy::Error::InvalidState;

sub init {
  my $self = shift;
  if ($self->SUPER::init( @_ )) {
    $self->delegate( EO::Hash->new );
    return 1;
  }
  return 0;
}

sub add_child {
  my $self = shift;
  my $name = shift;
  ## we want to share the delegated class, which makes this look
  ## sort of ugly, but not bad enough to make me want a 'class' method.
  ## on everything.
  my $child = ref($self)->new
                        ->delegate( ref($self->delegate)->new )
			->parent( $self );
  $self->at($name, $child);
}


## this took me a while to work out, so I'd better document it.
sub at {
  my $self = shift;
  my $key  = shift;

  throw EO::Error::InvalidParameters text => 'no key specified' unless defined( $key );

  if (@_) {
    ## if its a set, then we do just that, no
    ## need to worry about it.
    return $self->delegate->at( $key, @_ );
  }

  ## right, its a get, here is the fun.
  if ( !defined( $self->delegate->at( $key ) ) && $self->parent ) {
    ## if we don't have a defined value at the key, but
    ## we do have a parent then we ask the parent.
    return $self->parent->at( $key );
  } elsif (!defined( $self->delegate->at($key) ) && !$self->parent) {
    ## if we don't have a defined value at the key, and
    ## we have no parent, then we throw an Exception.
    throw EO::Hierarchy::Error::NoParent
      text => 'have gone as far as we can';
  } elsif (defined( $self->delegate->at( $key ) )) {
    ## if we have a key, then we return it
    return $self->delegate->at( $key );
  } else {
    ## we should absolutely never get here.  I don't know
    ## how we would get here, but it all seems hairy enough
    ## to warrant an exception.
    throw EO::Hierarchy::Error::InvalidState
      text => 'how the heck did we get here?'
  }
}

1;

__END__

=head1 NAME

EO::Hierarchy - hierarchical data structures

=head1 SYNOPSIS

  my $foo = EO::Hierarchy->new;
  $foo->at( 'bar', 'baz' );
  $foo->add_child( 'frob' );
  $foo->at( 'frob' )->at( 'bar' ); ## eq 'baz'

  ## or

  my $foo = EO::Hierarchy->new;
  $foo->delegate( EO::Array->new );
  $foo->at( 0, 'baz' );
  $foo->add_child( 1 );
  $foo->at( 1 )->at( 0 ); ## eq 'baz'

=head1 DESCRIPTION

EO::Hierarchy delegates to a collection object to provide heritable data
structures.  It should be noted that these data structures can I<appear>
recursive without being so.  This is demonstrable with the following code
example:

  my $obj = EO::Hierarchy->new;
  $obj->add_child( 'foo' );
  my $recurse = $obj->at('foo');
  print "appears recursive" if $recurse == $recurse->at('foo')

Handily the above code sample also displays a mechanism for testing it.

=head1 METHODS

EO::Hierarchy inherits from EO and shares all of its methods.  EO::Hierarchy
uses the EO::delegate pattern and shares the functionality of it.  It provides
a default delegation to an EO::Hash object which is constructed as a result of
creating an EO::Hierarchy object.

=over 4

=item add_child( KEY )

Adds a child into the data structure at the key KEY.  The child is also a
EO::Hierarchy object that inherits its data from the parent.  If you don't
want an inheriting child then you should use the C<at> method, as you would
with a normal EO::Collection object.

=back

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2005 Fotango Ltd. All Rights Reserved.

=cut


