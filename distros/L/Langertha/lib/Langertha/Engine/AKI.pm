package Langertha::Engine::AKI;
# ABSTRACT: AKI.IO native API
our $VERSION = '0.402';
use Moose;
use Carp qw( croak carp );
use JSON::MaybeXS;

extends 'Langertha::Engine::Remote';

with map { 'Langertha::Role::'.$_ } qw(
  Models
  Temperature
  SystemPrompt
  Chat
  Tools
  HermesTools
);


has api_key => (
  is => 'ro',
  lazy_build => 1,
);
sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_AKI_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_AKI_API_KEY or api_key set";
}


has '+url' => (
  lazy => 1,
  default => sub { 'https://aki.io' },
);

sub default_model { 'llama3_8b_chat' }

sub hermes_extract_content {
  my ( $self, $data ) = @_;
  return $data->{text};
}

has top_k => (
  is => 'ro',
  isa => 'Num',
  predicate => 'has_top_k',
);


has top_p => (
  is => 'ro',
  isa => 'Num',
  predicate => 'has_top_p',
);


has max_gen_tokens => (
  is => 'ro',
  isa => 'Int',
  predicate => 'has_max_gen_tokens',
);


# Dynamic model listing

sub list_models_request {
  my ($self) = @_;
  return $self->generate_http_request(
    GET => $self->url.'/api/endpoints?key='.$self->api_key,
    sub { $self->list_models_response(shift) },
  );
}

sub list_models_response {
  my ($self, $response) = @_;
  my $data = $self->parse_response($response);
  return $data->{endpoints};
}

sub list_models {
  my ($self, %opts) = @_;

  # Check cache unless force_refresh requested
  unless ($opts{force_refresh}) {
    my $cache = $self->_models_cache;
    if ($cache->{timestamp} && time - $cache->{timestamp} < $self->models_cache_ttl) {
      return $opts{full} ? $cache->{models} : $cache->{model_ids};
    }
  }

  # Fetch from API
  my $request = $self->list_models_request;
  my $response = $self->user_agent->request($request);
  my $endpoints = $request->response_call->($response);

  # Update cache
  $self->_models_cache({
    timestamp => time,
    models => $endpoints,
    model_ids => $endpoints,
  });

  return $endpoints;
}


sub endpoint_details_request {
  my ($self, $endpoint_name) = @_;
  return $self->generate_http_request(
    GET => $self->url.'/api/endpoints/'.$endpoint_name.'?key='.$self->api_key,
    sub { $self->endpoint_details_response(shift) },
  );
}

sub endpoint_details_response {
  my ($self, $response) = @_;
  return $self->parse_response($response);
}

sub endpoint_details {
  my ($self, $endpoint_name) = @_;
  my $request = $self->endpoint_details_request($endpoint_name);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}


# Chat

sub chat_request {
  my ( $self, $messages, %extra ) = @_;
  my $model = $self->chat_model;
  return $self->generate_http_request(
    POST => $self->url.'/api/call/'.$model,
    sub { $self->chat_response(shift) },
    key => $self->api_key,
    chat_context => $self->json->encode($messages),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    $self->has_top_k ? ( top_k => $self->top_k ) : (),
    $self->has_top_p ? ( top_p => $self->top_p ) : (),
    $self->has_max_gen_tokens ? ( max_gen_tokens => $self->max_gen_tokens ) : (),
    wait_for_result => JSON->true,
    %extra,
  );
}


sub chat_response {
  my ( $self, $response ) = @_;
  my $data = $self->parse_response($response);
  croak "".(ref $self)." API error: ".($data->{error} || 'unknown')
    unless $data->{success};
  require Langertha::Response;
  return Langertha::Response->new(
    content       => $data->{text} // '',
    raw           => $data,
    $data->{model_name} ? ( model => $data->{model_name} ) : (),
    $data->{total_duration} ? ( timing => { total_duration => $data->{total_duration} } ) : (),
  );
}


sub openai {
  my ( $self, %args ) = @_;
  require Langertha::Engine::AKIOpenAI;
  unless (exists $args{model}) {
    carp "".(ref $self)."->openai: native model name cannot be mapped to /v1 model name automatically, using AKIOpenAI default model";
  }
  return Langertha::Engine::AKIOpenAI->new(
    api_key => $self->api_key,
    $self->has_system_prompt ? ( system_prompt => $self->system_prompt ) : (),
    $self->has_temperature ? ( temperature => $self->temperature ) : (),
    %args,
  );
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::AKI - AKI.IO native API

=head1 VERSION

version 0.402

=head1 SYNOPSIS

    use Langertha::Engine::AKI;

    my $aki = Langertha::Engine::AKI->new(
        api_key => $ENV{AKI_API_KEY},
        model   => 'llama3_8b_chat',
    );

    print $aki->simple_chat('Hello from Perl!');

    # Get OpenAI-compatible API access
    my $aki_openai = $aki->openai;
    print $aki_openai->simple_chat('Hello via OpenAI format!');

=head1 DESCRIPTION

Provides access to AKI.IO's native API for running LLM inference. AKI.IO is
a European AI model hub based in Germany; all inference runs on EU infrastructure,
fully GDPR-compliant with no data leaving the EU.

The native API sends the API key as a C<key> field in the JSON request body
(not as an HTTP header). Supports synchronous chat, temperature and sampling
controls, dynamic endpoint listing, MCP tool calling via
L<Langertha::Role::HermesTools>, and OpenAI-compatible access via L</openai>.

Streaming is not yet supported in the native API. For streaming, use the
OpenAI-compatible endpoint via C<< $aki->openai >>.

Get your API key at L<https://aki.io/> and set C<LANGERTHA_AKI_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head2 api_key

The AKI.IO API key. If not provided, reads from C<LANGERTHA_AKI_API_KEY>
environment variable. Sent as a C<key> field in the JSON request body
(not as an HTTP header). Required.

=head2 top_k

    top_k => 40

Top-K sampling parameter. Controls the number of highest-probability tokens
to consider at each generation step.

=head2 top_p

    top_p => 0.9

Top-P (nucleus) sampling parameter. Controls the cumulative probability
threshold for token selection.

=head2 max_gen_tokens

    max_gen_tokens => 1000

Maximum number of tokens to generate in the response.

=head2 list_models

    my $endpoints = $aki->list_models;
    my $endpoints = $aki->list_models(force_refresh => 1);

Fetches available endpoint names from the AKI.IO C<GET /api/endpoints> API.
Returns an ArrayRef of endpoint names. Results are cached for C<models_cache_ttl>
seconds (default: 3600).

=head2 endpoint_details

    my $details = $aki->endpoint_details('llama3_8b_chat');
    # Returns hashref with name, title, description, workers, parameter_description, etc.

Fetches detailed information about a specific endpoint from the AKI.IO
C<GET /api/endpoints/{name}> API. Returns worker info, model metadata,
and parameter descriptions.

=head2 chat_request

    my $request = $aki->chat_request($messages, %extra);

Generates a native AKI.IO chat request. Posts to C</api/call/{model}> with
messages encoded as JSON in the C<chat_context> field. Includes C<key>,
C<temperature>, C<top_k>, C<top_p>, C<max_gen_tokens>, and
C<wait_for_result> parameters as configured. Returns an HTTP request object.

=head2 chat_response

    my $response = $aki->chat_response($http_response);

Parses a native AKI.IO chat response. Dies with an API error message if
C<success> is false. Returns a L<Langertha::Response> with C<content>,
C<model>, C<timing>, and C<raw>.

=head2 openai

    my $oai = $aki->openai;
    my $oai = $aki->openai(model => 'llama3-chat-8b');

Returns a L<Langertha::Engine::AKIOpenAI> instance configured with the same
API key, system prompt, and temperature. Supports streaming and MCP tool
calling.

B<Note:> The native AKI model name is B<not> carried over automatically
because the C</v1> endpoint uses different model identifiers. If no C<model>
is passed, the AKIOpenAI default model is used and a warning is emitted.
Pass C<< model => '...' >> explicitly with a valid C</v1> model name to
suppress the warning.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::AKIOpenAI> - OpenAI-compatible AKI.IO access via L</openai>

=item * L<https://aki.io/docs> - AKI.IO API documentation

=item * L<Langertha::Role::Chat> - Chat interface methods

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
