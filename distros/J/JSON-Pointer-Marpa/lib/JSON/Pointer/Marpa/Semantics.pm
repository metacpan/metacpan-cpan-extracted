use strict;
use warnings;

package JSON::Pointer::Marpa::Semantics;

use constant { ## no critic (ProhibitConstantPragma)
  EMPTY => '',
  SLASH => '/',
  TILDE => '~'
};

# This is a rule evaluation closure of a quantified rule
# https://metacpan.org/pod/distribution/Marpa-R2/pod/Semantics.pod#Quantified-rule-nodes
sub new {
  my ( $class, $currently_referenced_value ) = @_;

  return bless { currently_referenced_value => $currently_referenced_value }, $class;
}

sub concat {
  shift;
  return join '', @_;
}

sub array_index_dereferencing {
  my ( $self, $index ) = @_;

  return unless defined $self->get_currently_referenced_value;

  ref $self->get_currently_referenced_value eq 'HASH'
    ? $self->set_currently_referenced_value( $self->get_currently_referenced_value->{ $index } )
    : $self->set_currently_referenced_value( $self->get_currently_referenced_value->[ $index ] );

  return;
}

sub next_array_index_dereferencing {
  my ( $self, $next_index ) = @_;

  ref $self->get_currently_referenced_value eq 'ARRAY'
    ? Marpa::R2::Context::bail( "Handling of '$next_index' array index not implemented!" )
    : $self->set_currently_referenced_value( $self->get_currently_referenced_value->{ $next_index } );

  return;
}

sub object_name_dereferencing {
  my ( $self, $name ) = @_;

  return unless defined $self->get_currently_referenced_value;

  $self->set_currently_referenced_value( $self->get_currently_referenced_value->{ $name // '' } );

  return;
}

sub set_currently_referenced_value {
  my ( $self, $currently_referenced_value ) = @_;

  $self->{ currently_referenced_value } = $currently_referenced_value;

  return;
}

sub get_currently_referenced_value {
  my ( $self ) = @_;

  return $self->{ currently_referenced_value };
}

1;
