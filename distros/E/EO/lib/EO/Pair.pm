package EO::Pair;

use strict;
use warnings;

use EO::Array;
use base qw( EO::Array );

our $VERSION = 0.96;

sub at {
  my $self = shift;
  if ($_[0] > 1) {
    throw EO::Error::InvalidParameters
      text => 'pairs cannot have indicies greater than 1';
  }
  $self->SUPER::at( @_ );
}

sub do {
  my $self = shift;
  my $code = shift;
  my $result;
  {
    local $_ = $self;
    $result = $code->( $self );
  }
  return $result;
}

sub key {
  my $self = shift;
  return $self->at( 0, @_ );
}

sub value {
  my $self = shift;
  return $self->at( 1, @_ );
}

1;

=head1 NAME

EO::Pair - simple pairs for EO.

=head1 SYNOPSIS

  use EO::Pair;

  my $pair = EO::Pair->new();
  $pair->key( 'foo' );
  $pair->value( 'bar' );
  $pair->do( sub { print $_->key } );

=head1 DESCRIPTION

C<EO::Pair> provides a simple pair to EO.  It is used by the EO::Hash class
primarily.

=head1 CONSTRUCTORS

EO::Pair inherits from EO::Array and provides any constructors that EO::Array
does.

=head1 METHODS

=over 4

=item key( [KEYNAME] )

The key method gets and sets the key name of the pair.  This is the zeroth
element in the array.

=item value( [VALUE] )

The value method gets and sets the value of the pair.  This is the first\
element in the array.

=item do( CODE )

Runs the coderef passed by CODE.  Sets $_ and the first argument to CODE as the
pair object.

=back

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2004 Fotango Ltd. All Rights Reserved.

This module is released under the same terms as Perl itself.

=cut

