package Langertha::Engine::DeepSeek;
# ABSTRACT: DeepSeek API
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );

extends 'Langertha::Engine::OpenAIBase';

with 'Langertha::Role::Tools';


sub _build_supported_operations {[qw(
  createChatCompletion
)]}

has '+url' => (
  lazy => 1,
  default => sub { 'https://api.deepseek.com' },
);

sub _build_api_key {
  my ( $self ) = @_;
  return $ENV{LANGERTHA_DEEPSEEK_API_KEY}
    || croak "".(ref $self)." requires LANGERTHA_DEEPSEEK_API_KEY or api_key set";
}

sub default_model { 'deepseek-flash' }

# image_input (k266, k280, ADR 0019 k266 Update): deepseek-flash is
# DeepSeek-V4.1-Flash, natively multimodal since the 2026-09-10 release (news
# 260910; pricing table "Vision: yes"). The legacy ids deepseek-v4-flash and
# deepseek-v4-flash-vision-exp are served by V4.1-Flash too (pricing note,
# /guides/vision). deepseek-v4-pro (V4-Pro-0813) is "Vision: not supported";
# its temporary routing to V4.1-Flash since 2026-09-14 is not a capability
# and is deliberately not claimed. Other ids are unchecked, so the catch-all
# first row clears the flag (llm-advisor, docs only, read 2026-09-25).
sub model_capability_corrections {
  return (
    qr/\A/                                    => { image_input => 0 },
    'deepseek-flash'                          => { image_input => 1 },
    qr/\Adeepseek-v4-flash(?:-vision-exp)?\z/ => { image_input => 1 },
  );
}

# DeepSeek's response_format.type enum is [text, json_object] only — there is
# no json_schema on the standard endpoint (api-docs.deepseek.com, verified
# 2026-09-01; schema enforcement instead needs a forced tool with strict:true
# on the /beta base URL). Clear the json_schema flag so chat_f routes a
# json_schema request through the forced-tool path rather than shipping a
# response_format the wire rejects; json_object stays.
# parallel_tool_calls is not in the chat/completions schema, and DeepSeek's own
# Responses guide calls it "Ignored (parallel tool calling is always enabled)":
# clear parallel_tool_use so a parallel_tool_use=0 is dropped with a carp
# instead of sent and ignored (karr k242, docs only).
around engine_capabilities => sub {
  my ( $orig, $self, @rest ) = @_;
  my $caps = $self->$orig(@rest);
  delete @{$caps}{ qw( response_format_json_schema parallel_tool_use ) };
  return $caps;
};

# Reasoning effort diverges by DeepSeek model within the shared openai wire
# format: the current V4 generation (deepseek-flash, deepseek-v4-pro, and the
# temporarily-routed deepseek-v4-* aliases) takes a flat reasoning_effort
# string; the legacy V3.2 line used a thinking:{type:enabled} toggle instead.
# Match the V3.2 family by explicit prefix — anchored, so `deepseek-v3`,
# `deepseek-v3.2`, `deepseek-v3.2-exp` (etc.) hit the legacy toggle, and
# retired aliases / unknown future ids default to V4 (the safe current
# default). A bare `/v3/i` regex was rejected: it matched too widely and
# could collide with future V3.x / V3.x-y naming. (V3.2 mapping flagged for
# live re-verify.)
sub _is_deepseek_v3 {
  my ( $model ) = @_;
  return 0 unless defined $model && length $model;
  return 1 if $model eq 'deepseek-v3' || $model eq 'deepseek-v3.2';
  return 1 if $model =~ /\Adeepseek-v3(?:\.\d+)?(?:-[A-Za-z0-9._-]+)?\z/;
  return 0;
}

# Effort set per api-docs.deepseek.com/api/create-chat-completion (verified
# 2026-09-14): the chat-completion endpoint serving deepseek-flash and
# deepseek-v4-pro accepts reasoning_effort none|low|high|max (server default
# high) with NO per-model difference; none disables thinking. The former
# deepseek-v4-pro-only high|max clamp (drop low) was reversed by DeepSeek —
# V4 Pro service continues unchanged after 2026-09-14 — and is gone. Unknown
# future V4 ids get the same flat set.
#
# This override replaces Role::ReasoningEffort::reasoning_kwargs_for and so
# bypasses its supports()-gate (karr k204, ADR 0009): harmless while DeepSeek
# never clears reasoning_effort -- if it ever does, add the same gate here.
sub reasoning_kwargs_for {
  my ( $self, %args ) = @_;
  # A per-request reasoning_effort control (chat_f, karr #46) beats the
  # engine attribute; the rest of the model-gated placement is unchanged.
  my $e = exists $args{reasoning_effort} ? $args{reasoning_effort}
        : exists $args{effort}           ? $args{effort}
        : $self->has_reasoning_effort    ? $self->reasoning_effort
        : undef;
  return () unless defined $e;
  my $model = $self->can('chat_model') ? ( $self->chat_model // '' ) : '';
  if ( _is_deepseek_v3($model) ) {
    return ( thinking => { type => 'enabled' } );
  }
  return () unless $e eq 'none' || $e eq 'low' || $e eq 'high' || $e eq 'max';
  return ( reasoning_effort => $e );
}

# The thinking switch follows chat_model too, and every DeepSeek id resolves
# the same reasoning profile, so a per-request model that crosses the V3 line
# flips it unnamed otherwise (karr k362, Role::Chat::_warn_model_override).
around _model_scoped_wire_decisions => sub {
  my ( $orig, $self, $features, @rest ) = @_;
  my %decision = $self->$orig( $features, @rest );
  $decision{'thinking switch'} = _is_deepseek_v3( $self->chat_model ) ? 1 : 0
    if $features->{reasoning};
  return %decision;
};

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::DeepSeek - DeepSeek API

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::DeepSeek;

    my $deepseek = Langertha::Engine::DeepSeek->new(
        api_key      => $ENV{DEEPSEEK_API_KEY},
        model        => 'deepseek-flash',
        system_prompt => 'You are a helpful assistant',
        temperature  => 0.5,
    );

    print $deepseek->simple_chat('Say something nice');

=head1 DESCRIPTION

Provides access to DeepSeek's models via their API. Composes
L<Langertha::Role::OpenAICompatible> with DeepSeek's endpoint
(C<https://api.deepseek.com>) and API key handling.

Available models: C<deepseek-flash> (default; DeepSeek-V4.1-Flash, native
multimodal vision, 1M context) and C<deepseek-v4-pro>. The previous-generation
C<deepseek-v4-flash> and C<deepseek-v4-flash-vision-exp> were retired on
2026-09-10 and their ids are temporarily routed to V4.1-Flash — pin
C<deepseek-flash> instead. The older aliases C<deepseek-chat> and
C<deepseek-reasoner> were retired on 2026-07-24. Embeddings and transcription
are not supported. Dynamic model listing via C<list_models()>.

B<Reasoning effort:> the chat-completion endpoint — serving both
C<deepseek-flash> and C<deepseek-v4-pro> — accepts C<none>, C<low>, C<high>
(server default) and C<max>, with B<no per-model difference>; C<none> disables
thinking. Set it via the C<reasoning_effort> attribute or the per-request
C<chat_f> control.

Get your API key at L<https://platform.deepseek.com/> and set
C<LANGERTHA_DEEPSEEK_API_KEY> in your environment.

B<THIS API IS WORK IN PROGRESS>

=head1 SEE ALSO

=over

=item * L<https://status.deepseek.com/> - DeepSeek service status

=item * L<https://api-docs.deepseek.com/> - Official DeepSeek API documentation

=item * L<Langertha::Role::OpenAICompatible> - OpenAI API format role

=item * L<Langertha::Engine::Groq> - Another OpenAI-compatible engine

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

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
