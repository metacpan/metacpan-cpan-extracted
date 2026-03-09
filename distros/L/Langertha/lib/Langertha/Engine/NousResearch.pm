package Langertha::Engine::NousResearch;
# ABSTRACT: Nous Research Inference API
our $VERSION = '0.305';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';
with 'Langertha::Role::HermesTools';


sub _build_supported_operations {[qw(
  createChatCompletion
)]}

has '+url' => (
  lazy => 1,
  default => sub { 'https://inference-api.nousresearch.com/v1' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_NOUSRESEARCH_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_NOUSRESEARCH_API_KEY or api_key set";
}

sub default_model { 'Hermes-4-70B' }

has reasoning => (
  is => 'ro',
  isa => 'Bool',
  default => 0,
);


my $_default_reasoning_prompt = <<'END_REASONING_PROMPT';
You are a deep thinking AI, you may use extremely long chains of thought to
deeply consider the problem and deliberate with yourself via systematic
reasoning processes to help come to a correct solution prior to answering.
You should enclose your thoughts and internal monologue inside <think> </think>
tags, and then provide your solution or response to the problem.
END_REASONING_PROMPT
chomp $_default_reasoning_prompt;

has reasoning_prompt => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  default => sub { $_default_reasoning_prompt },
);


around chat_messages => sub {
  my ( $orig, $self, @messages ) = @_;
  my $msgs = $self->$orig(@messages);
  return $msgs unless $self->reasoning;
  # Prepend reasoning prompt as first system message
  unshift @$msgs, { role => 'system', content => $self->reasoning_prompt };
  return $msgs;
};

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::NousResearch - Nous Research Inference API

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    use Langertha::Engine::NousResearch;

    my $nous = Langertha::Engine::NousResearch->new(
        api_key => $ENV{NOUSRESEARCH_API_KEY},
        model   => 'Hermes-4-70B',
    );

    print $nous->simple_chat('Explain the Hermes prompt format');

    # Chain-of-thought reasoning (Hermes 4)
    my $nous = Langertha::Engine::NousResearch->new(
        api_key   => $ENV{NOUSRESEARCH_API_KEY},
        model     => 'Hermes-4-70B',
        reasoning => 1,
    );

    my $response = $nous->simple_chat('Solve this step by step...');
    say $response;                  # clean answer
    say $response->thinking;        # chain-of-thought reasoning

    # MCP tool calling (via HermesTools role)
    use Future::AsyncAwait;

    my $nous = Langertha::Engine::NousResearch->new(
        api_key     => $ENV{NOUSRESEARCH_API_KEY},
        model       => 'Hermes-4-70B',
        mcp_servers => [$mcp],
    );

    my $response = await $nous->chat_with_tools_f('Add 7 and 15');

=head1 DESCRIPTION

Provides access to Nous Research's inference API. Composes
L<Langertha::Role::OpenAICompatible> with Nous's endpoint
(C<https://inference-api.nousresearch.com/v1>) and Hermes tool calling.

Available models: C<Hermes-4-70B> (default), C<Hermes-4-405B>.

Composes L<Langertha::Role::HermesTools> for tool calling. Tool descriptions
are injected into the system prompt as C<< <tools> >> XML, and
C<< <tool_call> >> tags are parsed from the model output. No server-side tool
calling support required. See L<Langertha::Role::HermesTools> for
customization options.

Get your API key at L<https://portal.nousresearch.com/> and set
C<LANGERTHA_NOUSRESEARCH_API_KEY>.

B<THIS API IS WORK IN PROGRESS>

=head2 reasoning

    reasoning => 1

Enable chain-of-thought reasoning for Hermes 4 and DeepHermes 3 models.
Prepends the standard Nous reasoning system prompt that instructs the model
to use C<E<lt>thinkE<gt>> tags. The thinking content is automatically
extracted into L<Langertha::Response/thinking> by L<Langertha::Role::ThinkTag>.

With DeepHermes 3, reasoning output appears inline as C<E<lt>thinkE<gt>> tags
(handled by the think tag filter). With Hermes 4 (without response prefill),
reasoning appears in the C<reasoning_content> response field (handled by
native extraction).

Defaults to C<0> (disabled).

=head2 reasoning_prompt

The system prompt prepended when C<reasoning> is enabled. Defaults to the
standard Nous Research reasoning prompt from the Hermes model documentation.
Unless you have a specific technical reason (e.g. a different model requires
a different trigger format), it is strongly recommended to keep the default.

=head1 SEE ALSO

=over

=item * L<https://nousresearch.com/> - Nous Research homepage

=item * L<https://portal.nousresearch.com/api-docs> - API documentation

=item * L<Langertha::Role::HermesTools> - Hermes-style tool calling via XML tags

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
