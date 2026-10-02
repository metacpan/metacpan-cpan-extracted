package Langertha::Runtime::Knobs;
# ABSTRACT: Immutable self-hosted runtime knobs with per-server conversion
our $VERSION = '0.503';
use Moose;
use Carp qw( croak );
use JSON::MaybeXS qw( JSON );


has prefix_cache_salt => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_prefix_cache_salt',
);


has cache_prompt => (
  is        => 'ro',
  isa       => 'Bool',
  predicate => 'has_cache_prompt',
);


has n_cache_reuse => (
  is        => 'ro',
  isa       => 'Int',
  predicate => 'has_n_cache_reuse',
);


has id_slot => (
  is        => 'ro',
  isa       => 'Int',
  predicate => 'has_id_slot',
);


has priority => (
  is        => 'ro',
  isa       => 'Int',
  predicate => 'has_priority',
);


has return_cached_tokens_details => (
  is        => 'ro',
  isa       => 'Bool',
  predicate => 'has_return_cached_tokens_details',
);


has extra_key => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_extra_key',
);


sub to_vllm {
  my ( $self ) = @_;
  return () unless $self->has_prefix_cache_salt;
  return ( cache_salt => $self->prefix_cache_salt );
}


sub to_sglang {
  my ( $self ) = @_;
  return () unless $self->has_prefix_cache_salt
    || $self->has_extra_key
    || $self->has_priority
    || $self->has_return_cached_tokens_details;
  return (
    ( $self->has_prefix_cache_salt ? ( cache_salt => $self->prefix_cache_salt ) : () ),
    ( $self->has_extra_key ? ( extra_key => $self->extra_key ) : () ),
    ( $self->has_priority ? ( priority => $self->priority ) : () ),
    ( $self->has_return_cached_tokens_details
      ? ( return_cached_tokens_details => $self->return_cached_tokens_details ? JSON->true : JSON->false )
      : () ),
  );
}


sub to_llamacpp {
  my ( $self ) = @_;
  return () unless $self->has_cache_prompt
    || $self->has_n_cache_reuse
    || $self->has_id_slot;
  return (
    ( $self->has_cache_prompt ? ( cache_prompt => $self->cache_prompt ? JSON->true : JSON->false ) : () ),
    ( $self->has_n_cache_reuse ? ( n_cache_reuse => $self->n_cache_reuse ) : () ),
    ( $self->has_id_slot ? ( id_slot => $self->id_slot ) : () ),
  );
}


# Maps a knob_wire_format tag to the per-format serializer method.
my %TO_METHOD = (
  vllm     => 'to_vllm',
  sglang   => 'to_sglang',
  llamacpp => 'to_llamacpp',
);

sub to {
  my ( $self, $fmt ) = @_;
  my $method = $TO_METHOD{ $fmt // '' }
    or croak "Langertha::Runtime::Knobs: unknown knob wire format '" . ( $fmt // '' ) . "'";
  return $self->$method;
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Runtime::Knobs - Immutable self-hosted runtime knobs with per-server conversion

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $k = Langertha::Runtime::Knobs->new(
        prefix_cache_salt => 'tenant-a',
    );
    my %kwargs = $k->to('vllm');
    # ( cache_salt => 'tenant-a' )

    my $s = Langertha::Runtime::Knobs->new(
        prefix_cache_salt            => 'tenant-a',
        return_cached_tokens_details => 1,
    );
    my %kw = $s->to('sglang');
    # ( cache_salt => 'tenant-a', return_cached_tokens_details => true )

=head1 DESCRIPTION

Canonical value object for the request-side runtime knobs of the self-hosted
OpenAI-compatible engines (vLLM, SGLang, llama.cpp), dispatched by an engine's
C<knob_wire_format>. Mirrors L<Langertha::Reasoning> / L<Langertha::PromptCache>:
the per-provider placement of the fields lives in this one reviewable place
rather than scattered across engines (ADR 0001, ADR 0004 — no raw
C<extra_body> side-channel; these knobs serialize as top-level request-body
fields exactly like C<reasoning_kwargs_for> / C<prompt_cache_kwargs_for> do).

The only genuinely per-request knobs on these three servers are prefix-cache
isolation/reuse controls. Each C<to_*> serializer emits only the fields that
server's wire accepts and returns the body kwargs to merge into the request.

B<What is deliberately NOT modeled here:>

=over

=item * B<Speculative decoding> — a server-launch concern on all three engines
(C<--speculative-config> on vLLM, C<--speculative-*> on SGLang,
C<--spec-draft-*> on llama.cpp), restart-only, never a per-request knob.

=item * B<Continuous batching> — an internal scheduler flag, not a request knob.

=back

=head2 prefix_cache_salt

Optional prefix-cache salt string. Emitted as C<cache_salt> on the vLLM and
SGLang wires.

B<This is a cache-ISOLATION feature, not a performance knob.> It exists for
multi-tenant privacy and timing-attack mitigation: only requests sharing a
salt reuse each other's KV blocks, so a per-tenant salt keeps tenants from
observing each other's cache behavior. Setting a random salt per request
B<reduces> cache reuse — the opposite of a cache-warming hint. Requests that
want to share cached prefix blocks must carry the same salt.

B<Version gating:> vLLM's C<cache_salt> requires vLLM v1.x. Older servers
silently ignore unknown fields, so setting it against an old server is a
no-op, not an error.

=head2 cache_prompt

Optional llama.cpp C<cache_prompt> boolean: whether to reuse the prompt cache
for this request. Emitted as a JSON boolean on the llama.cpp wire.

=head2 n_cache_reuse

Optional llama.cpp C<n_cache_reuse> integer. B<Counter-intuitive:> C<0> means
reuse all cached tokens; higher values B<limit> reuse (the server reuses at
most that many cached tokens). The default is C<0> (reuse everything).

=head2 id_slot

Optional llama.cpp C<id_slot> integer: pin this request to a specific server
slot. Useful for stateful / multi-session setups where a request must land on
the slot holding the relevant KV cache.

=head2 priority

Optional SGLang C<priority> integer: request scheduling priority. Higher
values are served first.

=head2 return_cached_tokens_details

Optional SGLang C<return_cached_tokens_details> boolean: ask the server to
report how many prompt tokens were served from cache (surfaced on the
response as C<usage.prompt_tokens_details.cached_tokens>). Emitted as a JSON
boolean on the SGLang wire.

=head2 extra_key

Optional SGLang C<extra_key> string: an additional cache-key component, used
to partition the prefix cache beyond the prompt text itself (e.g. per-tenant
or per-request-type isolation).

=head2 to_vllm

Serializes to the vLLM wire. Emits exactly one field: C<cache_salt> (from
L</prefix_cache_salt>). Every other knob is clamped away — vLLM accepts no
other per-request runtime knob. Empty list when no salt is set.

=head2 to_sglang

Serializes to the SGLang wire: C<cache_salt> (from L</prefix_cache_salt>),
C<extra_key>, C<priority>, and C<return_cached_tokens_details> (a JSON
boolean). Knobs SGLang does not accept (llama.cpp's C<cache_prompt> /
C<n_cache_reuse> / C<id_slot>) are clamped away. Empty list when none of the
four fields is set.

=head2 to_llamacpp

Serializes to the llama.cpp wire: C<cache_prompt> (a JSON boolean),
C<n_cache_reuse>, and C<id_slot>. Knobs llama.cpp does not accept (vLLM /
SGLang's C<cache_salt>, SGLang's C<extra_key> / C<priority> /
C<return_cached_tokens_details>) are clamped away. Empty list when none of the
three fields is set.

=head2 to

    my %kwargs = $k->to($knob_wire_format);

Dispatch to the per-format serializer. Returns the body kwargs to merge into
the request (an empty list when nothing applies to that wire). Croaks on an
unknown format tag.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::RuntimeKnobs> - The composed role exposing the knob attributes

=item * L<Langertha::Reasoning> - Sibling value object for the reasoning-effort knob

=item * L<Langertha::PromptCache> - Sibling value object for the prompt-caching knob

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
