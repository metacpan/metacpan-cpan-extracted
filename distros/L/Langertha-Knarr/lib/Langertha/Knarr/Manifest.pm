package Langertha::Knarr::Manifest;
# ABSTRACT: Build Knarr's provider manifest (/.well-known/langertha.json) from its exposed model surface
our $VERSION = '1.102';
use Moose;
use URI;
use Log::Any qw( $log );


has knarr => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);

has _cache => (
  is => 'rw',
);

my $AVAILABLE;

sub available {
  $AVAILABLE //= eval { require Langertha::Manifest::Builder; 1 } ? 1 : 0;
  return $AVAILABLE;
}


sub build {
  my ( $self, $base_url ) = @_;
  $base_url =~ s{/+\z}{};
  my $knarr = $self->knarr;

  my $builder = Langertha::Manifest::Builder->new(
    provider_id => 'knarr',
    issuer      => _origin_of($base_url),
  );

  my $auth_ref;
  if ( defined $knarr->auth_token && length $knarr->auth_token ) {
    $auth_ref = 'api';
    $builder->add_auth( id => $auth_ref, type => 'api_key' );
  }

  my %allowed = map { $_ => 1 } Langertha::Manifest::Builder->model_capabilities;
  my $entries = $self->_model_entries;
  my %seen;
  for my $proto ( @{ $knarr->_protocol_objects } ) {
    my $spec = $proto->manifest_endpoint or next;
    my $endpoint_id = $proto->protocol_name;
    next if $seen{$endpoint_id}++;
    $builder->add_endpoint(
      id       => $endpoint_id,
      dialect  => $spec->{dialect},
      base_url => $base_url . ( $spec->{path} // '' ),
      ( defined $auth_ref ? ( auth_ref => $auth_ref ) : () ),
    );
    my %forwarded = map { $_ => 1 } grep { $allowed{$_} } @{ $spec->{capabilities} || [] };
    my %image_format = map { $_ => 1 } @{ $spec->{image_content_formats} || [] };
    for my $entry (@$entries) {
      my %caps = map { $_ => 1 } grep { $forwarded{$_} } keys %{ $entry->{capabilities} };
      # Only an engine whose content format reads the protocol's image
      # parts gets them (k32); with translation (k33) that is every format.
      delete $caps{image_input}
        unless defined $entry->{content_format} && $image_format{ $entry->{content_format} };
      eval {
        $builder->add_model(
          id           => $entry->{id},
          endpoint_ref => $endpoint_id,
          capabilities => \%caps,
        );
        1;
      } or $log->debugf( "Manifest: model %s not published: %s", $entry->{id}, $@ );
    }
  }

  return $builder->manifest;
}


# The listed surface, one entry per model id with the capabilities of the
# engine that serves it. Cached until the listing changes or a capability
# probe finishes.
sub _model_entries {
  my ($self) = @_;
  my $knarr  = $self->knarr;
  my $router = $knarr->router;
  my $listed = $router ? $router->list_models : $knarr->handler->list_models;
  my @rows   = map { ref $_ eq 'HASH' ? $_ : { id => "$_" } } @{ $listed || [] };

  my $key = join "\0", map { join "\1", map { $_ // '' } @{$_}{qw( id engine model )} } @rows;
  # A capability probe (k37) can change what an engine supports.
  $key .= "\2" . $router->capabilities_generation
    if $router && $router->can('capabilities_generation');
  my $cache = $self->_cache;
  return $cache->{entries} if $cache && $cache->{key} eq $key;

  my @entries;
  for my $row (@rows) {
    my $id = $row->{id};
    next unless defined $id && length $id;
    my ( $caps, $content_format ) = $router
      ? _router_capabilities( $router, $id ) : ( { chat => 1 } );
    next unless $caps;
    push @entries, { id => $id, capabilities => $caps, content_format => $content_format };
  }
  $self->_cache( { key => $key, entries => \@entries } );
  return \@entries;
}

# Capabilities of the engine serving $id, for the upstream model it sends,
# through core's Builder: model-scoped (ADR 0019) and filtered to the public
# allowlist. A model the router cannot build an engine for (e.g. its key
# variable is unset) is not servable and not published.
sub _router_capabilities {
  my ( $router, $id ) = @_;
  my ( $engine, $model, $alias_only ) = eval { $router->resolve( $id, skip_default => 1 ) };
  unless ($engine) {
    $log->debugf( "Manifest: model %s not published: %s", $id, $@ || 'unresolved' );
    return;
  }
  # An alias without model: key sends the engine's own default (k22).
  my $upstream = $alias_only ? eval { $engine->chat_model } : $model;
  $upstream = $id unless defined $upstream && length $upstream;

  my $caps = eval {
    my $probe = Langertha::Manifest::Builder->new(
      provider_id => 'probe',
      issuer      => 'http://probe.invalid',
    );
    # base_url, dialect and auth are given so nothing of the engine but its
    # capabilities is read; the probe manifest is thrown away.
    $probe->add_engine( $engine,
      endpoint_id => 'probe',
      base_url    => 'http://probe.invalid',
      dialect     => 'probe',
      auth        => 'none',
      models      => [$upstream],
    );
    my ($entry) = @{ $probe->manifest->models };
    +{ map { $_ => 1 } grep { $entry->supports($_) } keys %{ $entry->capabilities } };
  };
  unless ($caps) {
    # Not a Langertha chat engine: it answers chat, nothing more is known.
    $log->debugf( "Manifest: no capabilities for %s: %s", $id, $@ );
    $caps = { chat => 1 };
  }
  # The message-content shape the engine puts on its wire (openai,
  # anthropic, gemini, ollama, ...); decides which protocol's image parts
  # reach it intact.
  my $content_format = $engine->can('content_format') ? eval { $engine->content_format } : undef;
  return ( $caps, $content_format );
}

sub _origin_of {
  my ($url) = @_;
  my $uri = URI->new($url);
  return $url unless $uri->can('authority') && defined $uri->authority;
  return $uri->scheme . '://' . $uri->authority;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Manifest - Build Knarr's provider manifest (/.well-known/langertha.json) from its exposed model surface

=head1 VERSION

version 1.102

=head1 SYNOPSIS

    # Used by Langertha::Knarr itself; see Langertha::Knarr/MANIFEST.
    my $manifest = Langertha::Knarr::Manifest->new( knarr => $knarr );
    if ( Langertha::Knarr::Manifest->available ) {
        print $manifest->build('https://knarr.example')->to_json;
    }

=head1 DESCRIPTION

Builds the L<Langertha::Manifest> that L<Langertha::Knarr> serves at
C</.well-known/langertha.json>, with L<Langertha::Manifest::Builder> from
Langertha core.

Only what Knarr B<exposes> is published, never its configuration:

=over

=item * one endpoint per loaded protocol that has a manifest dialect
(L<Langertha::Knarr::Protocol/manifest_endpoint>), under the public base
URL;

=item * one model entry per model id Knarr lists (configured aliases and
C<auto_discover> results, as C<GET /v1/models> shows them) on each of those
endpoints;

=item * per model, the capabilities of the engine that serves it, evaluated
for its upstream model by the core Builder (model-scoped, public allowlist
only) and narrowed to what the endpoint's protocol actually forwards;
C<image_input> only where the engine's C<content_format> reads the
protocol's image parts (C<image_content_formats> in
L<Langertha::Knarr::Protocol/manifest_endpoint>: every format when Knarr
translates images, see L<Langertha::Knarr::Image>);

=item * an C<api_key> auth entry when Knarr requires its
L<Langertha::Knarr/auth_token>.

=back

Upstream URLs, API keys, C<api_key_env> names, engine classes, upstream
model names and passthrough targets never enter the document. Without a
router (a single custom handler), model entries claim only C<chat>.

The model part is cached and rebuilt when the listed model surface changes
(for example once auto-discovery has run) or a capability probe
(L<Langertha::Knarr::Router/probe_capabilities_f>) has finished, so learned
facts such as C<image_input> appear without a restart; the envelope around it is built
per request, because the base URL can come from the request.

=head2 knarr

Required (weak). The L<Langertha::Knarr> whose surface is published.

=head2 available

    Langertha::Knarr::Manifest->available;

True when the installed Langertha has L<Langertha::Manifest::Builder>.
Checked once per process; the manifest is a runtime-optional feature.

=head2 build

    my $manifest = $knarr_manifest->build($public_base_url);

Returns a validated L<Langertha::Manifest> for the given public base URL.
Croaks when the URL is not a valid manifest URL. Call only when
L</available> is true.

=head1 SEE ALSO

=over

=item * L<Langertha::Knarr/MANIFEST>

=item * L<Langertha::Manifest>, L<Langertha::Manifest::Builder> (Langertha core)

=back

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
