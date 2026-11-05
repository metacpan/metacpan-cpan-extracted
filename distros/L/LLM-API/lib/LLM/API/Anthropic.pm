package LLM::API::Anthropic;

use strict;
use warnings;

use HTTP::Tiny;
use JSON::PP qw(encode_json decode_json);
use LLM::API::Response;
use Scalar::Util qw(reftype);

our $VERSION = '2.0.0';

# Anthropic transport for LLM::API. The public client object is passed
# explicitly so its existing accessors, options, and response behavior
# remain unchanged while provider implementations are separated.

########################################################################
sub count_input_tokens {
########################################################################
  my ( $class, $self, $content ) = @_;

  die "ERROR: usage: send_prompt(array-ref)\n"
    if !ref $content || reftype($content) ne 'ARRAY';

  my $req = {
    headers => $self->headers( 'content-type' => 'application/json' ),
    content => encode_json(
      { model    => $self->get_model,
        messages => [
          { role    => $self->get_role,
            content => $content,
          }
        ]
      }
    )
  };

  my $rsp
    = HTTP::Tiny->new( timeout => $self->get_timeout )->post( $LLM::API::LLM_URL_BASE . $LLM::API::LLM_COUNT_TOKENS_EP, $req );

  die sprintf "ERROR %s:%s\n", @{$rsp}{qw(code content)}
    if !$rsp->{success};

  my ($input_token_cost) = $self->pricing( $self->get_model // $LLM::API::DEFAULT_LLM_MODEL );

  my $decoded = decode_json( $rsp->{content} );

  my $input_tokens = $decoded->{input_tokens};

  return ( $input_tokens, $input_tokens * $input_token_cost );
}

########################################################################
sub send_prompt {
########################################################################
  my ( $class, $self, $content ) = @_;

  die "ERROR: usage: send_prompt(array-ref)\n"
    if !ref $content || reftype($content) ne 'ARRAY';

  return $class->send_messages( $self, [ { role => $self->get_role, content => $content } ] );
}

########################################################################
sub send_messages {
########################################################################
  my ( $class, $self, $messages ) = @_;

  my $req = {
    headers => $self->headers( 'content-type' => 'application/json' ),
    content => encode_json(
      { model      => $self->get_model,
        max_tokens => $self->get_max_tokens,
        messages   => $messages,
      }
    )
  };

  my $rsp
    = HTTP::Tiny->new( timeout => $self->get_timeout )->post( $LLM::API::LLM_URL_BASE . $LLM::API::LLM_MESSAGES_EP, $req );

  return LLM::API::Response->new($rsp);
}

########################################################################
sub headers {
########################################################################
  my ( $class, $self, @headers ) = @_;

  return {
    @headers,
    'x-api-key'         => $self->get_api_key_getter->(),
    'anthropic-version' => $self->get_version,
  };
}

########################################################################
sub _do_admin_api {
########################################################################
  my ( $class, $self, $url ) = @_;

  my $rsp = HTTP::Tiny->new( timeout => $self->get_timeout )->get( $url, { headers => $self->headers } );

  die sprintf "%s:%s\n", @{$rsp}{qw(code content)}
    if !$rsp->{success};

  return decode_json( $rsp->{content} );
}

1;
