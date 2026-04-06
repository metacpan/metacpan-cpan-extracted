package Langertha::Engine::HuggingFace;
# ABSTRACT: HuggingFace Inference Providers API
our $VERSION = '0.309';
use Moose;
use Carp qw( croak );
use URI;

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


has '+url' => (
  lazy => 1,
  default => sub { 'https://router.huggingface.co/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_HUGGINGFACE_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_HUGGINGFACE_API_KEY or api_key set";
}

sub default_model { croak "".(ref $_[0])." requires model to be set" }

sub _build_supported_operations {[qw(
  createChatCompletion
)]}

has hub_url => (
  is => 'ro',
  isa => 'Str',
  default => sub { 'https://huggingface.co' },
);


sub list_models_request {
  my ($self, %opts) = @_;
  my $url = URI->new($self->hub_url.'/api/models');
  my %params = (
    inference_provider => $opts{inference_provider} // 'all',
    pipeline_tag => $opts{pipeline_tag} // 'text-generation',
    limit => $opts{limit} // 50,
    $opts{search} ? (search => $opts{search}) : (),
    'expand[]' => 'inferenceProviderMapping',
  );
  $url->query_form(%params);
  return $self->generate_http_request(
    GET => $url->as_string,
    sub { $self->list_models_response(shift, %opts) },
  );
}


sub list_models_response {
  my ($self, $response, %opts) = @_;
  my $data = $self->parse_response($response);
  return $data;
}


sub list_models {
  my ($self, %opts) = @_;

  # Check cache unless force_refresh or search (searches are not cached)
  unless ($opts{force_refresh} || $opts{search}) {
    my $cache = $self->_models_cache;
    if ($cache->{timestamp} && time - $cache->{timestamp} < $self->models_cache_ttl) {
      return $opts{full} ? $cache->{models} : $cache->{model_ids};
    }
  }

  my $request = $self->list_models_request(%opts);
  my $response = $self->user_agent->request($request);
  my $models = $request->response_call->($response);

  my @model_ids = map { $_->{id} } @$models;

  # Only cache non-search results
  unless ($opts{search}) {
    $self->_models_cache({
      timestamp => time,
      models => $models,
      model_ids => \@model_ids,
    });
  }

  return $opts{full} ? $models : \@model_ids;
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::HuggingFace - HuggingFace Inference Providers API

=head1 VERSION

version 0.309

=head1 SYNOPSIS

    use Langertha::Engine::HuggingFace;

    my $hf = Langertha::Engine::HuggingFace->new(
        api_key => $ENV{HF_TOKEN},
        model   => 'Qwen/Qwen2.5-7B-Instruct',
    );

    print $hf->simple_chat('Hello from Perl!');

    # Access many models through one API
    my $llama = Langertha::Engine::HuggingFace->new(
        api_key => $ENV{HF_TOKEN},
        model   => 'meta-llama/Llama-3.3-70B-Instruct',
    );

=head1 DESCRIPTION

Provides access to HuggingFace Inference Providers, a unified API gateway
for open-source models hosted on the HuggingFace Hub. The endpoint at
C<https://router.huggingface.co/v1> is 100% OpenAI-compatible.

Model names use C<org/model> format (e.g., C<Qwen/Qwen2.5-7B-Instruct>,
C<meta-llama/Llama-3.3-70B-Instruct>). No default model is set;
C<model> must be specified explicitly.

Supports chat, streaming, and MCP tool calling. Embeddings and transcription
are not supported.

Get your API token at L<https://huggingface.co/settings/tokens> and set
C<LANGERTHA_HUGGINGFACE_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head2 hub_url

Base URL for the HuggingFace Hub API. Default: C<https://huggingface.co>.
Used by C<list_models> to query available inference models.

=head2 list_models_request

    my $request = $engine->list_models_request(%opts);

Generates an HTTP GET request for the HuggingFace Hub API models
endpoint with inference provider filtering. Accepts options:
C<search>, C<pipeline_tag> (default: C<text-generation>),
C<inference_provider> (default: C<all>), C<limit> (default: 50).

=head2 list_models_response

    my $models = $engine->list_models_response($http_response);

Parses the Hub API response. Returns an ArrayRef of model objects
with C<id>, C<pipeline_tag>, C<inferenceProviderMapping>, etc.

=head2 list_models

    # All text-generation models with inference providers
    my $ids = $hf->list_models;

    # Search for specific models
    my $ids = $hf->list_models(search => 'llama');

    # Filter by pipeline tag
    my $ids = $hf->list_models(pipeline_tag => 'text-to-image');

    # Full model objects with provider details
    my $models = $hf->list_models(full => 1);

Queries the HuggingFace Hub API for models available via inference
providers. Only returns models that have at least one active inference
provider. Results are cached for C<models_cache_ttl> seconds (search
results are not cached).

=head1 SEE ALSO

=over

=item * L<https://huggingface.co/docs/inference-providers/index> - HuggingFace Inference Providers docs

=item * L<https://huggingface.co/models> - Browse available models

=item * L<https://status.huggingface.co/> - HuggingFace service status

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
