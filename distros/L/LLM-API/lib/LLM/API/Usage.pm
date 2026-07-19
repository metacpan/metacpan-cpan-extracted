package LLM::API::Usage;

use strict;
use warnings;

use English qw(-no_match_vars);
use Data::Dumper;

our @ACCESSORS = qw(
  input_tokens
  cache_creation_input_tokens
  cache_read_input_tokens
  output_tokens
  cache_creation
);

__PACKAGE__->mk_accessors(@ACCESSORS);

use parent qw(Class::Accessor::Fast);

our $VERSION = '1.0.0';

########################################################################
sub new {
########################################################################
  my ( $class, $usage ) = @_;

  my $self = $class->SUPER::new($usage);

  return $self;
}

########################################################################
sub ephemeral_5m_input_tokens {
########################################################################
  my ($self) = @_;
  return $self->cache_creation->{ephemeral_5m_input_tokens};
}

########################################################################
sub ephemeral_1h_input_tokens {
########################################################################
  my ($self) = @_;

  return $self->cache_creation->{ephemeral_1h_input_tokens};
}

1;
