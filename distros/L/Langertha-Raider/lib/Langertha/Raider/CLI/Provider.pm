package Langertha::Raider::CLI::Provider;
# ABSTRACT: Internal provider commands of the raider CLI: inspect a manifest, activate it for --provider
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Langertha::Manifest;
use Langertha::Manifest::Builder;
use URI;
use Langertha::Raider::Provider::Activation;
use Langertha::Raider::Provider::Fetch;


has output => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI::Output',
  required => 1,
);

has err => (
  is      => 'ro',
  default => sub { \*STDERR },
);

has fetch_args => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

sub fetch_class      { 'Langertha::Raider::Provider::Fetch' }
sub activation_class { 'Langertha::Raider::Provider::Activation' }
sub manifest_class   { 'Langertha::Manifest' }

has _known_capability => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build__known_capability',
);

sub _build__known_capability {
  return { map { $_ => 1 } Langertha::Manifest::Builder->model_capabilities };
}


sub fetcher {
  my ( $self, %args ) = @_;
  return $self->fetch_class->new(%{ $self->fetch_args }, %args);
}


sub inspect {
  my ( $self, $target, %opt ) = @_;
  my $fetch = $self->fetcher(allow_internal => $opt{allow_internal} ? 1 : 0);
  my $url = eval { $fetch->target_url($target) };
  unless (defined $url) {
    $self->_err('raider provider inspect: '.$self->output->error_text($@)."\n");
    return 2;
  }
  my $report = $fetch->fetch_f($url)->get;
  my $manifest;
  if ($report->{status} eq 'completed') {
    $manifest = eval { $self->manifest_class->from_json($report->{body}) };
    unless ($manifest) {
      $report->{status} = 'failed';
      $report->{error} = 'not a valid provider manifest: '.$self->output->error_text($@);
    }
  }
  my $doc = $self->document($report, $manifest, $fetch);
  if (my $machine = $opt{machine}) {
    $machine->write({ version => $machine->version, %$doc });
  }
  elsif ($manifest) {
    $self->show($doc, $manifest);
  }
  else {
    $self->_err('raider provider inspect: '.$doc->{status}.': '.$doc->{error}."\n");
  }
  return $manifest ? 0 : 1;
}


sub activate {
  my ( $self, $target, %opt ) = @_;
  my $activation = $self->activation_class->new(
    fetch => $self->fetcher(allow_internal => $opt{allow_internal} ? 1 : 0),
  );
  my $got = $activation->activate_f($target,
    model       => $opt{model},
    has_api_key => $opt{has_api_key} ? 1 : 0,
  )->get;
  unless ($got->{status} eq 'completed') {
    my $status = $got->{status} eq 'usage' ? '' : $got->{status}.': ';
    $self->_err('raider --provider: '.$status.$self->output->error_text($got->{error})."\n");
    return $got->{status} eq 'usage' ? 2 : 1;
  }
  $self->_err('raider --provider: warning: '.$_."\n") for @{ $got->{warnings} };
  return ( undef, $got );
}


sub document {
  my ( $self, $report, $manifest, $fetch ) = @_;
  my %doc = map { exists $report->{$_} ? ( $_ => $report->{$_} ) : () }
    qw( status url final_url redirects address error location elapsed );
  if ($manifest) {
    $doc{manifest} = $manifest->to_hash;
    $doc{warnings} = [ $self->warnings($manifest, $fetch->origin($report->{final_url} // $report->{url}), $fetch) ];
    $doc{notes}    = [ $self->notes($manifest) ];
  }
  return \%doc;
}


sub warnings {
  my ( $self, $manifest, $origin, $fetch ) = @_;
  my @warnings;
  my $issuer = $fetch->origin($manifest->issuer);
  push @warnings, 'issuer '.$manifest->issuer.' is not the origin the manifest came from ('.$origin.')'
    if defined $origin && ( $issuer // '' ) ne $origin;
  for my $endpoint (@{ $manifest->endpoints }) {
    my $what = "endpoint '".$endpoint->id."'";
    push @warnings, $what.": dialect '".$endpoint->dialect."' is unknown to this raider (no adapter for it)"
      unless $endpoint->is_known_dialect;
    my $uri = URI->new($endpoint->base_url);
    push @warnings, $what.': base_url is plain http, not https' if $uri->scheme eq 'http';
    my ( $kind ) = $fetch->address_kind($uri->host);
    push @warnings, $what.': base_url points at a '.$kind.' address ('.$uri->host.')'
      unless $kind eq 'public' || $kind eq 'invalid';
  }
  for my $auth (@{ $manifest->auth }) {
    push @warnings, "auth '".$auth->id."': type '".$auth->type."' is unknown to this raider (it cannot supply it)"
      unless $auth->is_known_type;
  }
  my $known = $self->_known_capability;
  for my $model (@{ $manifest->models }) {
    for my $cap (grep { !$known->{$_} } sort keys %{ $model->capabilities }) {
      push @warnings, "model '".$model->id."' on '".$model->endpoint_ref."': capability '".$cap
        ."' is not one Langertha knows; treated as absent";
    }
  }
  return @warnings;
}


sub notes {
  my ( $self, $manifest ) = @_;
  my @keys = sort keys %{ $manifest->extensions };
  return unless @keys;
  return 'extensions ('.join(', ', @keys).') are inert: kept as published, never interpreted, loaded or run';
}


sub show {
  my ( $self, $doc, $manifest ) = @_;
  my $out = $self->output;
  my $line = sub { $out->emit($out->c(meta => sprintf('%-11s ', $_[0])), @_[ 1 .. $#_ ], "\n") };
  $line->('provider', $out->c(title => $manifest->provider_id));
  $line->('issuer', $manifest->issuer);
  $line->('fetched', $doc->{final_url}.( defined $doc->{address} ? ' ('.$doc->{address}.')' : '' ));
  $line->('redirected', $_) for @{ $doc->{redirects} };

  $out->emit("\n", $out->c(title => 'endpoints'), "\n");
  for my $endpoint (@{ $manifest->endpoints }) {
    $out->emit(sprintf("  %-14s %-18s %s  ", $endpoint->id, $endpoint->dialect, $endpoint->base_url),
      $out->c(meta => 'auth: '.( $endpoint->auth_ref // 'none' )),
      $endpoint->is_known_dialect ? '' : $out->c(warn => '  (unknown dialect)'), "\n");
  }
  $out->emit($out->c(title => 'auth'), "\n");
  $out->emit('  ', $out->c(meta => 'none declared'), "\n") unless @{ $manifest->auth };
  for my $auth (@{ $manifest->auth }) {
    $out->emit(sprintf('  %-14s %s', $auth->id, $auth->type),
      $auth->is_known_type ? '' : $out->c(warn => '  (unknown type)'), "\n");
  }
  $out->emit($out->c(title => 'models'), "\n");
  $out->emit('  ', $out->c(meta => 'none listed'), "\n") unless @{ $manifest->models };
  for my $model (@{ $manifest->models }) {
    my $caps = $model->capabilities;
    my @claimed = grep { $caps->{$_} } sort keys %$caps;
    $out->emit(sprintf('  %-30s ', $model->id), $out->c(meta => 'on '.$model->endpoint_ref), '  ',
      @claimed ? join(', ', @claimed) : $out->c(meta => 'no capabilities claimed'), "\n");
  }
  $out->emit("\n") if @{ $doc->{warnings} } || @{ $doc->{notes} };
  $out->emit($out->c(warn => 'warning: '.$_), "\n") for @{ $doc->{warnings} };
  $out->emit($out->c(meta => 'note: '.$_), "\n") for @{ $doc->{notes} };
  $out->emit("\n", $out->c(meta => 'What the provider claims; nothing was stored or bound.'), "\n");
  return;
}

sub _err {
  my ( $self, @text ) = @_;
  print { $self->err } @text;
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::Provider - Internal provider commands of the raider CLI: inspect a manifest, activate it for --provider

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $provider = Langertha::Raider::CLI::Provider->new(output => $out, err => \*STDERR);
    my $exit = $provider->inspect('provider.example');                     # human
    my $exit = $provider->inspect('knarr.lan:8443', allow_internal => 1,
      machine => $machine);                                                # --json

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

C<raider provider inspect>: fetches a provider manifest
(L<Langertha::Raider::Provider::Fetch>), validates it with
L<Langertha::Manifest> and shows what it declares -- provider id, issuer,
endpoints, auth mechanisms and models -- together with what this raider
cannot use (an unknown dialect, auth type or capability) and the inert
C<extensions>. Nothing is stored, no credential is bound and nothing is
trusted: a manifest states what a provider claims (ADR 0007).

C<raider --provider>: L</activate> picks the endpoint of the manifest a
run uses (L<Langertha::Raider::Provider::Activation>) and reports why it
cannot, for L<Langertha::Raider::CLI::Main>.

=head2 output

The L<Langertha::Raider::CLI::Output> the result goes to. Required.

=head2 err

Filehandle for failures in human output. Defaults to C<STDERR>.

=head2 fetch_args

Extra constructor arguments for the fetcher (L</fetch_class>), for tests:
C<ssl_options>, C<resolver>, limits. Default none.

=head2 fetcher

    my $fetch = $provider->fetcher(allow_internal => 1);

A new fetcher with L</fetch_args> and the given arguments.

=head2 inspect

    my $exit = $provider->inspect($target, allow_internal => $bool, machine => $machine);

Inspects the provider C<$target> names (C<HOST>, C<HOST:PORT> or an
C<https> URL; L<Langertha::Raider::Provider::Fetch/target_url>). Returns
the exit status: C<0> for a valid manifest, C<1> when it was refused
(an address or redirect), could not be fetched or is not a valid manifest,
C<2> for a target that is none. With a machine, one document (see
L</document>); without, the report on L</output> and a failure on L</err>.

=head2 activate

    my ( $exit, $activation ) = $provider->activate($target,
      allow_internal => $bool, model => $model, has_api_key => $bool);

C<raider --provider TARGET>: the endpoint of the provider's manifest the
run uses, through L<Langertha::Raider::Provider::Activation>. Returns
C<undef> and the completed activation, with its warnings written to
L</err>; or, after writing why to L</err>, just the exit status: C<2> when
the command line has to change (a target that is none, a model the
manifest does not list, no model where it lists several, no key where
the endpoint needs one), C<1> when the provider cannot be used as it is
(refused, not fetched, not valid, not usable by this raider).

=head2 document

    my $doc = $provider->document($report, $manifest, $fetch);

The result as data, the machine document without C<version>:

=over

=item C<status> -- C<completed> (a valid manifest), C<refused> (an
address or a redirect the fetch policy refuses) or C<failed> (network,
TLS, HTTP status, a limit, invalid JSON or schema).

=item C<url> -- the manifest URL; C<final_url> -- where the body came
from after same-origin redirects (C<completed> only); C<redirects> -- those
redirects; C<address> -- the address connected to, once there was one.

=item C<manifest> -- the validated manifest as core serializes it
(L<Langertha::Manifest/to_hash>), C<completed> only.

=item C<warnings> -- what this raider could not use or found odd, one
sentence each (L</warnings>); C<notes> -- that C<extensions> are inert.
Both C<completed> only.

=item C<error> -- why (C<refused>, C<failed>); C<location> -- the target
of a redirect that was not followed.

=item C<elapsed> -- seconds the fetch took.

=back

=head2 warnings

    my @warnings = $provider->warnings($manifest, $origin, $fetch);

What a client should know before using the manifest: endpoints whose
dialect this raider has no adapter for, auth types it cannot supply,
capability names Langertha does not know (treated as absent), an issuer
that is not the origin the manifest came from, and endpoints that are
plain C<http> or point at an internal address literal.

=head2 notes

The C<extensions> of the manifest, when it has any: inert, kept as
published, never interpreted, loaded or run.

=head2 show

    $provider->show($doc, $manifest);

The human report of a valid manifest.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Provider::Fetch>

=item * L<Langertha::Raider::CLI::Main>

=item * L<raider> -- C<PROVIDERS>

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
