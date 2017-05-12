package EO::Collection;

use strict;
use warnings;
use EO;
use EO::Error;
our $VERSION = 0.96;
our @ISA = qw( EO );

exception EO::Error::InvalidParameters;

sub element {
  my $self = CORE::shift;
  if (@_) {
    my $thing = shift;
    if (!ref($thing)) {
      throw EO::Error::InvalidParameters text => 'not a reference';
    }
    $self->{ element } = $thing;
    return $self;
  }
  return $self->{ element };
}

sub delete : Abstract;
sub at : Abstract;
sub count : Abstract;

sub select : Abstract;
sub do : Abstract;

sub grep {
  my $self = shift;
  $self->select( @_ );
}

sub foreach {
  my $self = shift;
  $self->do( @_ );
}

sub as_string {
  my $self = shift;
  use Data::Dumper qw();
  my $d = Data::Dumper->new([ $self->element ]);
  $d->Indent( 0 );
  my $str = $d->Dump;
  $str =~ s/\$VAR\d\s*=\s*//g;
  return $str;
}

1;

__END__

=head1 NAME

EO::Collection - abstract base class for Collection-type objects

=head1 SYNOPSIS

=head1 DESCRIPTION

EO::Collection is an base class for things that want to
implement a collection class.

=head1 EXCEPTIONS

=over 4

=item EO::Error::InvalidParameters

Thrown when invalid parameters are passed to a method.

=back

=head1 INHERITANCE

EO::Collection inherits from EO.

=head1 CONSTRUCTOR

EO::Collection provides no constructor beyond what its parent class
provides.

=head1 METHODS

=over 4

=item element

This gets and sets the raw Perl primitive that is going to be used for
storage.  An attempt to set this to something other than a reference
will result in a EO::Error::InvalidParameters exception being thrown.

=item as_string

Returns a string representation of the object useful for debugging purposes.

=back

=head1 ABSTRACT METHODS

=over 4

=item delete( KEY )

Abstract method that needs to be implemented in child classes.  Should delete
the thing located at element KEY.

=item object_at_index( KEY [, THING] )

Abstract method that needs to be implemented in child classes.  With one
argument should return the thing located at element KEY.  With two
arguments it should place THING in location KEY.

=back

=head1 SEE ALSO

EO::Array, EO::Hash

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd.

=cut
