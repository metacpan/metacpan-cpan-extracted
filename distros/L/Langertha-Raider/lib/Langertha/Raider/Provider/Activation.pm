package Langertha::Raider::Provider::Activation;
# ABSTRACT: Internal activation of a provider manifest's endpoint as the engine of one raider run
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Future::AsyncAwait;
use URI;
use Langertha::Manifest;
use Langertha::Manifest::Builder;
use Langertha::Raider::Provider::Fetch;



has fetch => (
  is       => 'ro',
  isa      => 'Langertha::Raider::Provider::Fetch',
  required => 1,
);

sub manifest_class { 'Langertha::Manifest' }

sub builder_class { 'Langertha::Manifest::Builder' }

# The adapter: manifest dialect => raider engine name (the .raider.yml
# engine / -o name). The Langertha engine class comes from core
# (Langertha::Manifest::Builder->engine_class_for_dialect); each class takes
# the endpoint's base_url as its url. anthropic-compat is the bare
# Anthropic-compatible base: no native structured output, so response_format
# goes through the synthetic tool and a forced tool_choice (ADR 0007, update
# of 2026-09-25) -- t/69 holds that core still answers AnthropicBase.
my %ENGINE_NAME_FOR_DIALECT = (
  'openai-chat'      => 'openai',
  'responses'        => 'responses',
  'perplexity-agent' => 'perplexity-agent',
  'anthropic'        => 'anthropic',
  'anthropic-compat' => 'anthropic-compat',
  'gemini'           => 'gemini',
  'ollama'           => 'ollama',
  'aki'              => 'aki'
);

# Dialects Langertha knows but raider cannot run on, and why.
my %UNSUPPORTED_DIALECT = (
  'lmstudio' => "Langertha's native LM Studio engine has no tool calling, which raider needs",
);


sub engine_for_dialect {
  my ( $self, $dialect ) = @_;
  my $name = $ENGINE_NAME_FOR_DIALECT{$dialect} or return;
  my $class = $self->builder_class->engine_class_for_dialect($dialect) or return;
  return ( $name, $class );
}

sub mapped_dialects {
  my ( $self ) = @_;
  return sort keys %ENGINE_NAME_FOR_DIALECT;
}

sub unsupported_dialect {
  my ( $self, $dialect ) = @_;
  return $UNSUPPORTED_DIALECT{$dialect};
}

sub unsupported_dialects {
  my ( $self ) = @_;
  return sort keys %UNSUPPORTED_DIALECT;
}


async sub activate_f {
  my ( $self, $target, %opt ) = @_;
  my $fetch = $self->fetch;
  my $url = eval { $fetch->target_url($target) };
  unless (defined $url) {
    ( my $error = $@ ) =~ s/ at \S+ line \d+\.?\n?\z//s;
    return { status => 'usage', error => $error };
  }
  my $report = await $fetch->fetch_f($url);
  return { status => $report->{status}, error => $report->{error} }
    unless $report->{status} eq 'completed';
  my $manifest = eval { $self->manifest_class->from_json($report->{body}) };
  unless ($manifest) {
    ( my $error = $@ ) =~ s/ at \S+ line \d+\.?\n?\z//s;
    return { status => 'failed', error => 'not a valid provider manifest: '.$error };
  }
  my $origin = $fetch->origin($report->{final_url} // $url);

  my ( $model, $refusal ) = $self->choose_model($manifest, $opt{model});
  return $refusal if $refusal;
  my $endpoint = $manifest->endpoint($model->endpoint_ref);
  my $what = "endpoint '".$endpoint->id."'";
  my $dialect = $endpoint->dialect;

  return { status => 'failed', error => $what.": dialect '".$dialect."' is unknown to this raider (no adapter for it)" }
    unless $endpoint->is_known_dialect;
  if ( my $why = $self->unsupported_dialect($dialect) ) {
    return { status => 'failed', error => $what.": dialect '".$dialect."' is not supported: ".$why };
  }
  my ( $engine_name, $engine_class ) = $self->engine_for_dialect($dialect);
  return { status => 'failed', error => $what.": dialect '".$dialect."' has no engine in this raider" }
    unless $engine_class;

  my $base = URI->new($endpoint->base_url);
  return { status => 'refused', error => $what.': base_url '.$endpoint->base_url.' is not https' }
    unless lc( $base->scheme // '' ) eq 'https';
  my $endpoint_origin = $fetch->origin($base) // '';
  return { status => 'refused', error => $what.': base_url '.$endpoint->base_url
    .' is not of the origin the manifest came from ('.$origin.'); no credential goes to another origin' }
    unless $endpoint_origin eq $origin;

  my $auth;
  if ( defined $endpoint->auth_ref ) {
    $auth = $manifest->auth_entry($endpoint->auth_ref);
    return { status => 'failed', error => $what.": auth '".$auth->id."' has type '".$auth->type
      ."', which this raider cannot supply" }
      unless $auth->is_known_type;
    return { status => 'usage', error => $what." needs an API key (auth '".$auth->id."', type "
      .$auth->type.'); pass it with -k KEY' }
      unless $opt{has_api_key};
  }

  my $checked = await $fetch->check_host_f($base->host);
  return { status => $checked->{status}, error => $what.': '.$checked->{error} } if $checked->{status};
  # The engine connects to this address, not to the name (k141). Every
  # address passed the policy above; the first is the one the system
  # prefers, and the one the manifest fetch tries first.
  my ( $connect_address ) = @{ $checked->{addresses} };
  return { status => 'failed', error => $what.': '.$base->host.' resolves first to '.$connect_address
    .', a scoped address the engine connection cannot be pinned to' }
    if $connect_address =~ /%/;

  my @warnings;
  push @warnings, "model '".$model->id."' does not declare tools_native; raider works through tool calls"
    unless $model->supports('tools_native');

  return {
    status       => 'completed',
    provider_id  => $manifest->provider_id,
    manifest_url => $report->{final_url} // $url,
    endpoint     => $endpoint->id,
    dialect      => $dialect,
    engine_name  => $engine_name,
    engine_class => $engine_class,
    url          => $endpoint->base_url,
    model        => $model->id,
    auth         => $auth ? $auth->id : undef,
    addresses       => $checked->{addresses},
    connect_address => $connect_address,
    warnings        => \@warnings,
  };
}


sub choose_model {
  my ( $self, $manifest, $requested ) = @_;
  my @models = @{ $manifest->models };
  my %seen;
  my @ids = grep { !$seen{$_}++ } map { $_->id } @models;
  my $listed = @ids ? ' (models: '.join(', ', @ids).')' : ' (it lists none)';
  my $id;
  if ( defined $requested && length $requested ) {
    return ( undef, { status => 'usage', error => "model '".$requested."' is not in the manifest of "
      .$manifest->provider_id.$listed } )
      unless $seen{$requested};
    $id = $requested;
  }
  else {
    return ( undef, { status => 'failed', error => 'the manifest of '.$manifest->provider_id.' lists no models' } )
      unless @ids;
    return ( undef, { status => 'usage', error => 'the manifest of '.$manifest->provider_id
      .' lists several models; choose one with -m MODEL'.$listed } )
      if @ids > 1;
    ( $id ) = @ids;
  }
  my @candidates = grep { $_->id eq $id } @models;
  return ( $candidates[0] ) if @candidates == 1;
  my @usable = grep {
    my $endpoint = $manifest->endpoint($_->endpoint_ref);
    $endpoint->is_known_dialect && $self->engine_for_dialect($endpoint->dialect);
  } @candidates;
  return ( $usable[0] ) if @usable == 1;
  return ( $candidates[0] ) unless @usable;
  return ( undef, { status => 'failed', error => "model '".$id."' is offered on several endpoints ("
    .join(', ', map { $_->endpoint_ref.': '.$manifest->endpoint($_->endpoint_ref)->dialect } @usable)
    .'); raider does not choose between them' } );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Provider::Activation - Internal activation of a provider manifest's endpoint as the engine of one raider run

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $activation = Langertha::Raider::Provider::Activation->new(
      fetch => Langertha::Raider::Provider::Fetch->new( allow_internal => 0 ),
    );
    my $got = $activation->activate_f('provider.example',
      model => 'example-model', has_api_key => 1)->get;
    # { status => 'completed', engine_name => 'openai',
    #   engine_class => 'Langertha::Engine::OpenAI',
    #   url => 'https://provider.example/v1', model => 'example-model', ... }
    # { status => 'usage' | 'refused' | 'failed', error => ... }

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

C<raider --provider>: turns what a provider manifest (ADR 0007) claims
into the engine of one run. Nothing is stored and nothing is trusted
beyond this run: the release is the target named on the command line,
as with C<-o url=>.

=over

=item 1. The manifest is fetched with L<Langertha::Raider::Provider::Fetch>
and validated with L<Langertha::Manifest>.

=item 2. B<The model.> The requested model must be a model id of the
manifest. Without one, the manifest must list exactly one model id.

=item 3. B<The endpoint> is the one the model is listed on. A model listed
on several endpoints takes the one whose dialect raider has an adapter
for; when that is more than one, raider does not choose.

=item 4. B<The dialect> maps to a L<Langertha> engine class
(L</engine_for_dialect>). An unknown dialect, or one raider cannot use
(L</unsupported_dialect>), is an error -- never a guess.

=item 5. B<The origin.> The endpoint's C<base_url> must be C<https> and of
the same origin as the manifest, so a credential never goes to an origin
the command line did not name. Its host is resolved and checked again,
under the same address policy as the fetch (C<--allow-internal> releases
both): every address it resolves to must pass, as for the manifest.

=item 6. B<The connection.> The engine connects to the first of those
checked addresses (C<connect_address>, Langertha ADR 0037), never to the
name resolved once more, so an answer that changes after the check (DNS
rebinding) cannot send the request and its credential elsewhere. An
address literal stands for itself. TLS still verifies the certificate
against the host name. Unlike the manifest fetch, the engine has no second
address to fall back to; an address with a scope (C<fe80::1%eth0>) cannot
be pinned and is an error.

=item 7. B<The credential> is the caller's: an endpoint with an
C<auth_ref> needs one (C<has_api_key>), of an auth type raider knows.

=back

A model that does not declare C<tools_native> is a warning, not an error.

=head2 fetch

The L<Langertha::Raider::Provider::Fetch> the manifest comes through; its
C<allow_internal> also releases the endpoint's host. Required.

=head2 engine_for_dialect

    my ( $name, $class ) = $activation->engine_for_dialect('openai-chat');
    # ( 'openai', 'Langertha::Engine::OpenAI' )

The raider engine name and the L<Langertha> engine class of a manifest
dialect; the empty list for a dialect raider has no adapter for. Also
callable on the class.

=head2 mapped_dialects

The dialects L</engine_for_dialect> maps, sorted. Also callable on the
class.

=head2 unsupported_dialect

    my $why = $activation->unsupported_dialect('lmstudio');

Why raider cannot use a dialect Langertha knows, or C<undef>. Also callable
on the class.

=head2 unsupported_dialects

The dialects L</unsupported_dialect> names, sorted. Also callable on the
class.

=head2 activate_f

    my $got = await $activation->activate_f($target,
      model => $model_or_undef, has_api_key => $bool);

Resolves to a hash. C<status> is C<completed>, C<usage> (the command line
names a target that is none, a model the manifest does not list, no model
where it lists several, or no key where the endpoint needs one),
C<refused> (the fetch policy, an endpoint that is not C<https> or not of
the manifest's origin, or an endpoint address the policy refuses) or
C<failed> (the fetch, an invalid manifest, a dialect or auth type raider
cannot use, a manifest without models). Apart from C<completed>, C<error>
says why.

A C<completed> activation carries C<provider_id>, C<manifest_url>,
C<endpoint> (its id), C<dialect>, C<engine_name>, C<engine_class>, C<url>
(the endpoint's C<base_url>), C<model>, C<auth> (the auth id, or C<undef>),
C<addresses> (of the endpoint host, all checked), C<connect_address> (the
one of them the engine connects to) and C<warnings>. It never carries a
credential.

=head2 choose_model

    my ( $model, $refusal ) = $activation->choose_model($manifest, $requested);

The L<Langertha::Manifest::Model> entry the run uses (see L</DESCRIPTION>),
or C<undef> and the C<usage> or C<failed> result that says why not.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Provider::Fetch>

=item * L<Langertha::Raider::EngineResolver> -- builds the engine from the activation

=item * L<Langertha::Manifest::Builder> -- core's dialect => engine class table this one asks

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

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
