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
  provider_response
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
sub from_result {
########################################################################
  my ( $class, %args ) = @_;
  my $result = $args{result};

  die "ERROR: normalized LLM response must be a hash reference\n"
    if ref $result ne q{HASH};

  my $raw_response = {
    success => 1,
    status  => 200,
    code    => 200,
    reason  => q{OK},
  };

  my $self = $class->SUPER::new(
    { raw_response      => $raw_response,
      provider_response => $args{provider_response},
    }
  );

  $self->_load_result($result);

  return $self;
}

########################################################################
sub from_error {
########################################################################
  my ( $class, %args ) = @_;
  my $code    = $args{code}    // 500;
  my $message = $args{message} // q{Provider request failed};

  my $self = $class->SUPER::new(
    { raw_response => {
        success => 0,
        code    => $code,
        status  => $code,
        reason  => $message,
      },
      provider_response => $args{provider_response},
    }
  );

  $self->{provider_error_message} = $message;

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

  return sprintf '%s: %s', $rsp->{code}, $self->{provider_error_message}
    if exists $self->{provider_error_message};

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
  $self->_load_result($decoded_content);

  return $self;
}

########################################################################
sub _load_result {
########################################################################
  my ( $self, $result ) = @_;

  $self->decoded_content($result);
  $self->usage( LLM::API::Usage->new( $result->{usage}       // {} ) );
  $self->content( LLM::API::Content->new( $result->{content} // [] ) );

  foreach my $attr (qw(type role model id stop_reason stop_sequence)) {
    $self->set( $attr, $result->{$attr} );
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
