package Langertha::Engine::VLLMHook;
# ABSTRACT: vLLM inference server with vLLM-Hook probe capture
our $VERSION = '0.503';
use Moose;
use JSON::MaybeXS ();

extends 'Langertha::Engine::vLLM';


has vllm_xargs => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);


has worker_name => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_worker_name',
);



sub resolved_xargs {
  my ( $self ) = @_;
  my $xargs = $self->vllm_xargs;
  return $xargs if keys %$xargs;
  return {} unless $self->has_worker_name;
  return { output_hidden_states => JSON::MaybeXS::true() }
    if $self->worker_name eq 'hidden_states';
  return {};
}


sub _encode_xargs {
  my ( $self, $xargs ) = @_;
  my %out;
  for my $k ( keys %$xargs ) {
    my $v = $xargs->{$k};
    $out{$k} = ( ref $v eq 'HASH' || ref $v eq 'ARRAY' )
      ? $self->encode_json_text($v)
      : $v;
  }
  return \%out;
}

around 'chat_request' => sub {
  my ( $orig, $self, $messages, %extra ) = @_;
  my $xargs = $self->resolved_xargs;
  if ( keys %$xargs ) {
    my $encoded  = $self->_encode_xargs($xargs);
    my $per_call = $extra{vllm_xargs} // {};
    $extra{vllm_xargs} = { %$encoded, %$per_call };
  }
  return $self->$orig( $messages, %extra );
};


around 'chat_response' => sub {
  my ( $orig, $self, $http_response ) = @_;
  my $resp = $self->$orig($http_response);
  my $raw  = $resp->raw // {};
  if ( defined $raw->{probes} ) {
    $resp = $resp->clone_with( probes => $raw->{probes} );
  }
  return $resp;
};


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Engine::VLLMHook - vLLM inference server with vLLM-Hook probe capture

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Engine::VLLMHook;

    # Capture hidden states for every request
    my $engine = Langertha::Engine::VLLMHook->new(
        url        => 'http://localhost:8770/v1',
        vllm_xargs => { output_hidden_states => JSON::MaybeXS::true() },
    );

    my $response = $engine->simple_chat('Hello');
    print $response->content, "\n";
    print "probes: ", join(',', keys %{$response->probes}), "\n"
      if $response->has_probes;

    # Drive xargs from a vLLM-Hook model config file
    use Langertha::VLLMHook::Config;
    my $cfg = Langertha::VLLMHook::Config->new(
        file => 'model_configs/hidden_states/Qwen2.5-3B-Instruct.json',
    );
    my $engine = Langertha::Engine::VLLMHook->new(
        url        => 'http://localhost:8770/v1',
        vllm_xargs => $cfg->xargs,
    );

=head1 DESCRIPTION

Talks to a vLLM server running the vLLM-Hook plugin
(L<https://github.com/IBM/vLLM-Hook>), which observes attention patterns,
extracts hidden states and performs activation steering. It speaks ordinary
OpenAI-compatible HTTP, so this engine extends L<Langertha::Engine::vLLM> and
only adds two things:

=over 4

=item * On the way out, the C<vllm_xargs> HashRef is merged into the chat
request body. vLLM maps the top-level C<vllm_xargs> field onto
C<SamplingParams.extra_args>, which the plugin reads to install its hooks.
Nested values (dicts, lists) are JSON-encoded as strings because C<vllm_xargs>
only carries scalars — the plugin JSON-decodes them again before the worker
reads them.

=item * On the way back, the serialized probe tensors that the plugin attaches
as a top-level C<probes> field are lifted onto
L<Langertha::Response/probes>.

=back

The server must be started with the matching worker, e.g.
C<VLLM_HOOK_WORKER=hidden_states vllm serve E<lt>modelE<gt> --enforce-eager>.

B<THIS API IS WORK IN PROGRESS>

=head2 vllm_xargs

HashRef of extra arguments merged into the top-level C<vllm_xargs> field of
every chat request. Activates the vLLM-Hook plugin's probes. Defaults to an
empty HashRef. Nested HashRef/ArrayRef values are JSON-encoded as strings on
the wire (see L</_encode_xargs>); plain scalars and JSON booleans pass through
(a JSON boolean rides as a native JSON C<true>/C<false>).
Recognised keys include C<output_hidden_states>, C<output_qk>, C<hookq_mode>
and C<steer>. When non-empty this takes precedence over L</worker_name>.

=head2 worker_name

Optional convenience naming the vLLM-Hook worker the server was started with
(C<VLLM_HOOK_WORKER>): C<qk>, C<hidden_states> or C<steer>. Used only to derive
a default L</vllm_xargs> when none was given explicitly. C<hidden_states>
yields C<{ output_hidden_states =E<gt> true }>; C<qk> and C<steer> need their
layer/head map or steering dict supplied via C<vllm_xargs> and therefore
contribute no default on their own.

=head2 resolved_xargs

    my $xargs = $engine->resolved_xargs;

Returns the effective C<vllm_xargs> HashRef. When L</vllm_xargs> is non-empty it
is returned as-is; otherwise a default is derived from L</worker_name>. Returns
an empty HashRef when neither yields anything.

=head2 _encode_xargs

    my $encoded = $engine->_encode_xargs(\%xargs);

Returns a copy of C<%xargs> in which every nested HashRef/ArrayRef value is
JSON-encoded to a string, leaving plain scalars and JSON booleans untouched (a
JSON boolean rides as a native JSON C<true>/C<false>). vLLM's C<vllm_xargs>
only accepts scalar values, so structured values must travel as JSON strings;
the vLLM-Hook plugin decodes them again.

=head2 chat_request

    my $request = $engine->chat_request($messages, %extra);

Wraps L<Langertha::Role::OpenAICompatible/chat_request> to merge
L</resolved_xargs> (encoded via L</_encode_xargs>) into the top-level
C<vllm_xargs> field of the request body. A per-call C<vllm_xargs> in C<%extra>
overrides the instance values key-by-key.

=head2 chat_response

    my $response = $engine->chat_response($http_response);

Wraps L<Langertha::Role::OpenAICompatible/chat_response> to lift the
serialized probe tensors from the response body's top-level C<probes> field
onto L<Langertha::Response/probes>. Behaves exactly like the parent when the
server returned no probes.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::vLLM> - Parent engine (plain vLLM, no probes)

=item * L<Langertha::VLLMHook::Config> - Loads vLLM-Hook model config JSON into C<vllm_xargs>

=item * L<Langertha::Response/probes> - Where captured probe tensors land

=item * L<https://github.com/IBM/vLLM-Hook> - The vLLM-Hook plugin

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
