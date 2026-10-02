package Langertha::Role::RuntimeKnobs;
# ABSTRACT: Role for a self-hosted engine with per-request prefix-cache runtime knobs
our $VERSION = '0.503';
use Moose::Role;
use Carp qw( croak );
use Langertha::Runtime::Knobs;

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


has knob_wire_format => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_knob_wire_format',
);

# No shared default exists — an 'openai' knob dialect does not exist (the
# self-hosted servers each speak their own field set), so every engine that
# composes this role must set its tag explicitly. Engines override the builder
# (sub _build_knob_wire_format { 'vllm' }) — the codebase convention for
# wire-format tags (cf. _build_tool_wire_format).
sub _build_knob_wire_format {
  my ( $self ) = @_;
  croak ref($self) . " composes Langertha::Role::RuntimeKnobs but does not set "
    . "knob_wire_format — there is no shared default (an 'openai' knob dialect "
    . "does not exist); set it explicitly (vllm | sglang | llamacpp)";
}


my @KNOBS = qw(
  prefix_cache_salt
  cache_prompt
  n_cache_reuse
  id_slot
  priority
  return_cached_tokens_details
  extra_key
);

sub knobs_kwargs_for {
  my ( $self, %args ) = @_;

  # Per-request controls (chat_f, karr #46) beat the engine attributes on a
  # per-key basis: %args may carry any of the canonical knob names (the same
  # names as the attributes — there is no separate alias vocabulary), and any
  # key it does not carry falls back to the configured attribute.
  my %merged;
  for my $knob (@KNOBS) {
    my $has = "has_$knob";
    $merged{$knob} = $self->$knob if $self->$has;
    $merged{$knob} = $args{$knob} if exists $args{$knob};
  }
  return () unless %merged;
  return Langertha::Runtime::Knobs->new(
    map { $_ => $merged{$_} } keys %merged,
  )->to( $self->knob_wire_format );
}


sub knobs_kwargs {
  my ( $self ) = @_;
  return $self->knobs_kwargs_for;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::RuntimeKnobs - Role for a self-hosted engine with per-request prefix-cache runtime knobs

=head1 VERSION

version 0.503

=head2 prefix_cache_salt

Optional prefix-cache salt string, emitted as C<cache_salt> on the vLLM and
SGLang wires. B<Cache isolation, not a performance knob:> only requests
sharing a salt reuse each other's KV blocks, so a random per-request salt
B<reduces> cache reuse. vLLM's C<cache_salt> requires vLLM v1.x; older
servers silently ignore unknown fields. See L<Langertha::Runtime::Knobs>.

=head2 cache_prompt

Optional llama.cpp C<cache_prompt> boolean: reuse the prompt cache for this
request. Emitted as a JSON boolean on the llama.cpp wire.

=head2 n_cache_reuse

Optional llama.cpp C<n_cache_reuse> integer. B<Counter-intuitive:> C<0> means
reuse all cached tokens; higher values B<limit> reuse. See
L<Langertha::Runtime::Knobs>.

=head2 id_slot

Optional llama.cpp C<id_slot> integer: pin this request to a specific server
slot (useful when the relevant KV cache lives on one slot).

=head2 priority

Optional SGLang C<priority> integer: request scheduling priority. Higher
values are served first.

=head2 return_cached_tokens_details

Optional SGLang C<return_cached_tokens_details> boolean: ask the server to
report cached prompt tokens (C<usage.prompt_tokens_details.cached_tokens> on
the response). Emitted as a JSON boolean on the SGLang wire.

=head2 extra_key

Optional SGLang C<extra_key> string: an additional cache-key component beyond
the prompt text, used to partition the prefix cache.

=head2 knob_wire_format

    knob_wire_format => 'vllm'

The per-engine enum naming which self-hosted runtime-knob dialect this engine
speaks — C<vllm> | C<sglang> | C<llamacpp>. Drives the value-object dispatch
in L</knobs_kwargs>. B<There is no shared default:> each engine must set its
tag explicitly (override C<_build_knob_wire_format>), because the three
servers accept disjoint field sets and no generic 'openai' knob dialect
exists. Accessing the attribute on an engine that forgot the tag croaks with
a message naming the role and the missing tag.

=head2 knobs_kwargs_for

    my %kwargs = $engine->knobs_kwargs_for( prefix_cache_salt => 'tenant-a' );
    my %kwargs = $engine->knobs_kwargs_for( %$controls );

Returns the body kwargs to merge into a chat request for the runtime knobs,
serialized for L</knob_wire_format> via L<Langertha::Runtime::Knobs>. C<%args>
may carry any of the canonical knob names (C<prefix_cache_salt>,
C<cache_prompt>, C<n_cache_reuse>, C<id_slot>, C<priority>,
C<return_cached_tokens_details>, C<extra_key> — the same names as the
attributes, so the whole controls hash from chat_f can be passed wholesale);
keys it does not carry fall back to the engine attributes, so a per-request
control (chat_f, karr #46) beats the configured attribute on a per-key basis.
Empty list when neither a per-request value nor an attribute is set, or when
none of the set knobs is supported on the engine's wire.

=head2 knobs_kwargs

    my %kwargs = $engine->knobs_kwargs;

Returns the body kwargs to merge into a chat request for the configured
runtime knobs, serialized for L</knob_wire_format> via
L<Langertha::Runtime::Knobs>. Empty list when nothing is set, or when none of
the set knobs is supported on the engine's wire. Delegates to
L</knobs_kwargs_for> with no per-request overrides.

=head1 SEE ALSO

=over

=item * L<Langertha::Runtime::Knobs> - The value object this role dispatches to

=item * L<Langertha::Role::Capabilities> - Where C<prefix_caching> is registered

=item * L<Langertha::Role::ReasoningEffort> - Sibling request-side reasoning control

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
