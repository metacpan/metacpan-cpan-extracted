package Langertha::Knarr::Response;
# ABSTRACT: Normalized chat response shared across all Knarr handlers and protocol formatters
our $VERSION = '1.101';
use Moose;
use Scalar::Util qw( blessed );
use Langertha::Usage;


has content => (
  is => 'ro',
  isa => 'Str',
  default => '',
);

has model => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has usage => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

has tool_calls => (
  is => 'ro',
  isa => 'ArrayRef',
  default => sub { [] },
);

has finish_reason => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has id => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has timing => (
  is => 'ro',
  isa => 'Maybe[HashRef]',
  default => sub { undef },
);

has thinking => (
  is => 'ro',
  isa => 'Maybe[Str]',
  default => sub { undef },
);

has rate_limit => (
  is => 'ro',
  isa => 'Maybe[Object]',
  default => sub { undef },
);

has raw => (
  is => 'ro',
  default => sub { undef },
);

# Upgrade a raw usage HashRef into a Langertha::Usage. Done here rather
# than in from_langertha_response so every door into the object is
# covered — the Langertha::Response path, a handler returning a
# { content => ..., usage => {...} } hashref, and clone_with alike.
# Already-blessed usage passes untouched, so this stays correct if a
# later Langertha coerces on its own side.
around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  my $params = $class->$orig(@args);
  if ( ref $params->{usage} eq 'HASH' ) {
    $params->{usage} = Langertha::Usage->from_hash( $params->{usage} );
  }
  return $params;
};


sub coerce {
  my ($class, $thing) = @_;
  return $class->new() unless defined $thing;
  if (blessed $thing) {
    return $thing if $thing->isa($class);
    return $class->from_langertha_response($thing) if $thing->isa('Langertha::Response');
    return $class->new( content => "$thing" );
  }
  if (ref $thing eq 'HASH') {
    return $class->new( %$thing );
  }
  return $class->new( content => "$thing" );
}


sub from_langertha_response {
  my ($class, $r) = @_;
  return $class->new(
    content       => "$r",
    model         => ( $r->can('model')         ? $r->model         : undef ),
    usage         => ( $r->can('usage')         ? $r->usage         : undef ),
    tool_calls    => ( $r->can('tool_calls')    ? ( $r->tool_calls // [] ) : [] ),
    finish_reason => ( $r->can('finish_reason') ? $r->finish_reason : undef ),
    id            => ( $r->can('id')            ? $r->id            : undef ),
    timing        => ( $r->can('timing')        ? $r->timing        : undef ),
    thinking      => ( $r->can('thinking')      ? $r->thinking      : undef ),
    rate_limit    => ( $r->can('rate_limit')    ? $r->rate_limit    : undef ),
    raw           => ( $r->can('raw')           ? $r->raw           : undef ),
  );
}


sub ttft_seconds {
  my ($self) = @_;
  my $t = $self->timing or return undef;
  return $t->{ttft_seconds};
}

sub total_seconds {
  my ($self) = @_;
  my $t = $self->timing or return undef;
  return $t->{total_seconds};
}


sub has_tool_calls {
  my ($self) = @_;
  return scalar @{ $self->tool_calls } > 0;
}


sub clone_with {
  my ($self, %override) = @_;
  return ref($self)->new(
    content       => $self->content,
    model         => $self->model,
    usage         => $self->usage,
    tool_calls    => $self->tool_calls,
    finish_reason => $self->finish_reason,
    id            => $self->id,
    timing        => $self->timing,
    thinking      => $self->thinking,
    rate_limit    => $self->rate_limit,
    raw           => $self->raw,
    %override,
  );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Response - Normalized chat response shared across all Knarr handlers and protocol formatters

=head1 VERSION

version 1.101

=head1 DESCRIPTION

The single shape every L<Langertha::Knarr::Handler> returns and every
L<Langertha::Knarr::Protocol> formatter consumes. Mirrors
L<Langertha::Response> but is decoupled from it so non-engine handlers
(L<Langertha::Knarr::Handler::Code>, L<Langertha::Knarr::Handler::A2AClient>,
L<Langertha::Knarr::Handler::ACPClient>) can produce a Knarr response
without going through Langertha first.

L</coerce> upgrades all the legacy shapes Knarr handlers used to
return — a bare string, a C<{ content =E<gt> ..., model =E<gt> ... }>
hashref, or a stringifiable L<Langertha::Response> — into a
proper value object. So existing call sites can pass anything they
already had and downstream code can rely on a single API.

=head2 content

Plain assistant text. Defaults to empty string.

=head2 model

The model id that produced the response, if known.

=head2 usage

A L<Langertha::Usage> object with token counts, if the engine reported
them. C<undef> for handlers that have no usage data (Code, Passthrough).

A plain HashRef is accepted and upgraded with
L<Langertha::Usage>'s C<from_hash> — L<Langertha::Response> declares its own
C<usage> as C<Maybe[HashRef]> and the engines pass the provider's raw
JSON hash straight through, so that is the shape every real engine
response arrives in. The upgrade normalizes the provider spellings
(C<prompt_tokens> / C<input_tokens> / C<prompt_eval_count>, ...), which
is what lets the protocol formatters call C<to_openai_format> and
friends on whatever any handler produced.

=head2 tool_calls

ArrayRef of L<Langertha::ToolCall> objects produced by the engine.
Empty arrayref when the response is plain text.

=head2 finish_reason

Provider-agnostic stop reason (C<stop>, C<tool_calls>, C<length>, ...).
Optional; the protocol formatters fall back to C<stop> / C<end_turn>
when undef.

=head2 id

The provider-side response id (OpenAI C<chatcmpl-...>, Anthropic
C<msg_...>), when the engine reported one. Carried so a Knarr trace can
be correlated with the provider's own logs. C<undef> for handlers that
have no upstream id.

=head2 timing

HashRef of engine-measured durations, mirroring
L<Langertha::Response/timing>. The two keys every Langertha engine
populates are C<ttft_seconds> and C<total_seconds> (Float, seconds);
provider-native stage durations (Ollama's C<load_seconds>,
C<prompt_eval_seconds>, C<eval_seconds>, ...) may be present too.

Only the routed path has this — it comes from the engine's own
measurement inside L<Langertha>. Raw passthrough never produces a
L<Langertha::Response> and therefore never a C<timing>; see
L<Langertha::Knarr::Tracing/Timing sources> for which path reports
latency from where.

=head2 thinking

Chain-of-thought / reasoning text the engine separated from C<content>
(DeepSeek C<reasoning_content>, Anthropic thinking blocks, or
L<Langertha::Role::ThinkTag> filtering). Carried because it is model
output that C<content> no longer holds — without it the reasoning is
lost at the proxy boundary. Recorded into the Langfuse generation
metadata; the protocol formatters currently do not emit it.

=head2 rate_limit

Optional L<Langertha::RateLimit> object built from the upstream
provider's quota headers. Kept as the object; consumers pull the
scalar fields they need.

=head2 raw

Optional. The provider-native response body, kept around for handlers
(passthrough-style) that want to preserve every byte upstream returned.

=head2 coerce

    my $r = Langertha::Knarr::Response->coerce( $whatever );

Class method. Accepts:

=over

=item * an existing C<Langertha::Knarr::Response> — returned as-is.

=item * a L<Langertha::Response> — fields lifted via
C<from_langertha_response>.

=item * any other blessed object that stringifies — used as C<content>.

=item * a HashRef — fed to C<new> after key normalization.

=item * a plain scalar — used as C<content>.

=item * C<undef> — produces an empty response.

=back

This is the single normalization entry point. Handlers can return
whatever shape is convenient and the dispatcher coerces once at the
boundary.

=head2 from_langertha_response

    my $r = Langertha::Knarr::Response->from_langertha_response($lresp);

Builds a Knarr response from a L<Langertha::Response>. Carries
C<content>, C<model>, C<usage>, C<tool_calls>, C<finish_reason>,
C<id>, C<timing>, C<thinking>, C<rate_limit>, and C<raw> across.
C<usage> arrives as the provider's raw HashRef and is upgraded to a
L<Langertha::Usage> on the way in; see L</usage>.

Every field is read behind a C<can()> guard so Knarr keeps working
against a L<Langertha> release that predates one of them — the older
attributes were added over several Langertha versions and C<timing> /
C<rate_limit> / C<thinking> are the most recent.

=head2 ttft_seconds

Time-to-first-token in seconds (Float) out of L</timing>, or C<undef>
when the engine did not measure it (non-streaming calls, or any handler
that is not engine-backed).

=head2 total_seconds

Total engine-measured call duration in seconds (Float) out of
L</timing>, or C<undef>.

=head2 has_tool_calls

True when C<tool_calls> contains at least one entry.

=head2 clone_with

    my $r2 = $r->clone_with( model => 'override' );

Returns a new response with the given fields overridden. All other
attributes carry through from C<$self>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

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
