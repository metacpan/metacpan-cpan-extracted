package LLM::API::Response;

use strict;
use warnings;

use LLM::API::Usage;
use LLM::API::Content;
use JSON::PP;

use English qw(-no_match_vars);
use Data::Dumper;

our @ACCESSORS = qw(
  content
  decoded_content
  id
  model
  raw_response
  role
  stop_reason
  stop_sequence
  type
  usage
);

__PACKAGE__->mk_accessors(@ACCESSORS);

use parent qw(Class::Accessor::Fast);

our $VERSION = '1.0.0';

########################################################################
sub new {
########################################################################
  my ( $class, $raw_response ) = @_;

  my $self = $class->SUPER::new( { raw_response => $raw_response } );

  $self->init;

  return $self;
}

########################################################################
sub is_success {
########################################################################
  my ($self) = @_;

  return $self->raw_response->{success};
}

########################################################################
sub status {
########################################################################
  my ($self) = @_;

  return $self->raw_response->{status};
}

########################################################################
sub reason {
########################################################################
  my ($self) = @_;

  return $self->raw_response->{reason};
}

########################################################################
sub code {
########################################################################
  my ($self) = @_;

  return $self->raw_response->{code};
}

########################################################################
sub raw_content {
########################################################################
  my ($self) = @_;

  return $self->raw_response->{content};
}

########################################################################
sub error {
########################################################################
  my ($self) = @_;

  my $rsp = $self->raw_response;

  return q{}
    if $rsp->{success};

  return sprintf '%s: %s', $rsp->{code}, decode_json( $rsp->{content} );
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my $rsp = $self->raw_response;

  return
    if !$self->is_success;

  my $decoded_content = decode_json( $rsp->{content} );
  $self->decoded_content($decoded_content);

  $self->usage( LLM::API::Usage->new( $decoded_content->{usage} ) );
  $self->content( LLM::API::Content->new( $decoded_content->{content} ) );

  foreach my $attr (qw(type role model id stop_reason stop_sequence)) {
    $self->set( $attr, $decoded_content->{$attr} );
  }

  return $self;
}

########################################################################
sub was_cutoff {
########################################################################
  my ($self) = @_;

  return $self->stop_reason eq 'max_tokens';
}

1;

__END__
