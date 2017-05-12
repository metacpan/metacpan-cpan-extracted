package EO::WeakArray;

use strict;
use warnings;

use EO::Array;
use base qw( EO::Array );
use Scalar::Util qw( weaken );

our $VERSION = 0.96;

sub splice {
  my $self = shift;
  my $result = $self->SUPER::splice(@_);
  my $offset = shift;
  my $length = shift || 0;
  ## in the case that we have an offset we can deal with then we are going
  ## to start weakening the things that we can.  We're not going to be
  ## stupid and walk the entire thing either, no, we'll be smart and only
  ## touch the things that have been touched.
  if ($offset >= 0) {
    for ($offset..$offset + $length) {
      ## can't weaken non-references :-)
      weaken( $self->element->[ $_ ] ) if ref( $self->element->[ $_ ] );
    }
  }
  return $result;
}


sub at {
  my $self = shift;
  if (@_ > 1) {
    ## its a set, so we need to weaken these things.
    my $where = shift;
    my $what  = shift;
    my $result = $self->SUPER::at( $where, $what );
    weaken( $self->element->[ $where ] ) if ref($self->element->[ $where ]);
    return $result;
  } else {
    ## its a get, no weakening needed
    return $self->SUPER::at( @_ );
  }
}

1;

=head1 NAME

EO::WeakArray - arrays where all references contained are weak

=head1 SYNOPSIS

  use EO::WeakArray;
  my $thing = {};
  my $array = EO::WeakArray->new;
  $array->push( $obj );
  $obj = undef;

  if ( $array->at( 0 ) == undef ) {
    print "ok\n";
  }

=head1 DESCRIPTION

A WeakArray is similar to a normal array only its contents are not reference
counted.  Thus, if something destroys the contents from the outside world
then it disappears from inside the array as well.

=head1 METHODS

WeakArrays provide no methods beyond those provided by an array.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2004 Fotango Ltd. All Rights Reserved.

This module is released under the same terms as Perl itself.

=cut
