package Langertha::Raider::CLI::Provider;
# ABSTRACT: Internal provider commands of the raider CLI: inspect a manifest, bind an alias, activate it for --provider
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Time::HiRes ();
use Langertha::Manifest;
use Langertha::Manifest::Builder;
use URI;
use Langertha::Raider::Provider::Activation;
use Langertha::Raider::Provider::Binding;
use Langertha::Raider::Provider::Fetch;
use Langertha::Raider::CLI::Runner;


has output => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI::Output',
  required => 1,
);

has err => (
  is      => 'ro',
  default => sub { \*STDERR },
);

has in => (
  is      => 'ro',
  default => sub { \*STDIN },
);

has interactive => (
  is      => 'ro',
  lazy    => 1,
  default => sub { ( -t $_[0]->in && -t $_[0]->output->out ) ? 1 : 0 },
);

has fetch_args => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
);

sub fetch_class      { 'Langertha::Raider::Provider::Fetch' }
sub binding_class    { 'Langertha::Raider::Provider::Binding' }
sub activation_class { 'Langertha::Raider::Provider::Activation' }
sub manifest_class   { 'Langertha::Manifest' }
sub runner_class     { 'Langertha::Raider::CLI::Runner' }

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
  my ( $report, $manifest, $fetch ) = $self->_fetch_manifest($target, $opt{allow_internal});
  unless ($report) {
    $self->_err('raider provider inspect: '.$manifest."\n");
    return 2;
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

# ( $report, $manifest, $fetch ): the fetch report, the validated manifest
# (undef when it is none; the report then says failed), the fetcher. For a
# target that is none: an empty report and the error text.
sub _fetch_manifest {
  my ( $self, $target, $allow_internal ) = @_;
  my $fetch = $self->fetcher(allow_internal => $allow_internal ? 1 : 0);
  my $url = eval { $fetch->target_url($target) };
  return ( undef, $self->output->error_text($@) ) unless defined $url;
  my $report = $fetch->fetch_f($url)->get;
  my $manifest;
  if ($report->{status} eq 'completed') {
    $manifest = eval { $self->manifest_class->from_json($report->{body}) };
    unless ($manifest) {
      $report->{status} = 'failed';
      $report->{error} = 'not a valid provider manifest: '.$self->output->error_text($@);
    }
  }
  return ( $report, $manifest, $fetch );
}


sub activate {
  my ( $self, $target, %opt ) = @_;
  my $t0 = $opt{t0} // Time::HiRes::time();
  my $activation = $self->activation_class->new(
    fetch => $self->fetcher(allow_internal => $opt{allow_internal} ? 1 : 0),
  );
  my $binding = $opt{binding};
  my $got = $activation->activate_f($target,
    model       => $opt{model},
    endpoint    => $opt{endpoint},
    has_api_key => $opt{has_api_key} ? 1 : 0,
    ( $binding ? (
      verify   => sub { $self->_verify_binding($binding, @_) },
      key_hint => ( defined $binding->{entry}{credential_env}
        ? 'the environment variable '.$binding->{entry}{credential_env}.', or -k KEY'
        : '-k KEY' ),
    ) : () ),
  )->get;
  unless ($got->{status} eq 'completed') {
    my $status = $got->{status} eq 'usage' ? '' : $got->{status}.': ';
    $self->_err('raider --provider: '.$status.$self->output->error_text($got->{error})."\n");
    $self->failure_document($opt{machine}, $got->{status}, $got->{error}, $target, $t0) if $opt{machine};
    return $got->{status} eq 'usage' ? 2 : 1;
  }
  $self->_err('raider --provider: warning: '.$_."\n") for @{ $got->{warnings} };
  return ( undef, $got );
}


sub failure_document {
  my ( $self, $machine, $status, $error, $target, $t0 ) = @_;
  $machine->finish($machine->document(
    ( $status eq 'refused' ? 'refused' : 'failed' ),
    reason   => 'provider',
    error    => $self->output->error_text($error),
    provider => $target,
    elapsed  => $self->runner_class->elapsed_since($t0),
  ));
  return;
}

sub _verify_binding {
  my ( $self, $binding, $manifest, $origin ) = @_;
  my $why = $self->binding_class->verify($binding->{entry}, $manifest, $origin);
  return unless defined $why;
  return "provider alias '".$binding->{alias}."' no longer matches what you accepted (".$why
    .'); nothing was run. Review it with: raider provider inspect '.$binding->{entry}{origin}
    .'  and accept it again with: raider provider add '.$binding->{alias}.' HOST'
    .( $binding->{entry}{allow_internal} ? ' --allow-internal' : '' );
}


sub add {
  my ( $self, $alias, $target, %opt ) = @_;
  my $binding = $self->binding_class;
  my $say = sub { $self->_err('raider provider add: '.join('', @_)."\n") };
  unless ($binding->valid_alias($alias)) {
    $say->("alias '".( $alias // '' )."' is not a name: lowercase letters, digits, - and _ (at most 32)");
    return 2;
  }
  if ( defined $opt{credential_env} && !$binding->valid_credential_env($opt{credential_env}) ) {
    $say->("--credential-env '".$opt{credential_env}."' is not an environment variable name");
    return 2;
  }
  unless ($self->interactive) {
    $say->('needs a terminal: the endpoints and auth are shown first and accepted by a person; nothing was stored');
    return 1;
  }
  my ( $report, $manifest, $fetch ) = $self->_fetch_manifest($target, $opt{allow_internal});
  unless ($report) {
    $say->($manifest);
    return 2;
  }
  unless ($manifest) {
    $say->($report->{status}.': '.$self->output->error_text($report->{error}));
    return 1;
  }
  my $origin = $fetch->origin($report->{final_url} // $report->{url});
  my $entry = eval {
    $binding->entry($manifest, $origin,
      allow_internal => $opt{allow_internal}, credential_env => $opt{credential_env});
  };
  unless ($entry) {
    $say->($self->output->error_text($@));
    return 1;
  }
  if ( @{ $entry->{auth} } && !defined $entry->{credential_env} ) {
    $say->('the endpoints ask for auth ('.join(', ', @{ $entry->{auth} })
      .'); name the environment variable the credential comes from: --credential-env NAME');
    return 2;
  }
  if ( !@{ $entry->{auth} } && defined $entry->{credential_env} ) {
    $say->('--credential-env: the provider asks for no auth, there is no credential to bind');
    return 2;
  }

  my $doc = $self->document($report, $manifest, $fetch);
  $self->show($doc, $manifest, footer => 0);
  my $out = $self->output;
  my $line = sub { $out->emit($out->c(meta => sprintf('%-11s ', $_[0])), @_[ 1 .. $#_ ], "\n") };
  $out->emit("\n", $out->c(title => "binding '".$alias."'"), "\n");
  $line->('origin', $entry->{origin});
  $line->('issuer', $entry->{issuer});
  $line->('auth', @{ $entry->{auth} } ? join(', ', @{ $entry->{auth} }) : 'none');
  $line->('credential', defined $entry->{credential_env}
    ? 'the value of $'.$entry->{credential_env}.' is sent to '.$entry->{origin}.' only'
    : 'none');
  $line->('internal', $entry->{allow_internal}
    ? $out->c(warn => 'allowed: this alias may resolve to a loopback, private or link-local address')
    : 'not allowed');
  my $config = $opt{config};
  my $stored = eval { $config->providers };
  unless ($stored) {
    $say->($self->output->error_text($@));
    return 1;
  }
  my $old = $stored->{$alias};
  if ( defined $old ) {
    my $why = ref $old eq 'HASH' && !$binding->problem($old)
      ? $binding->verify($old, $manifest, $origin) : 'the stored binding is not valid';
    my $env_changed = ref $old eq 'HASH' && ( $old->{credential_env} // '' ) ne ( $entry->{credential_env} // '' )
      ? 'credential_env '.( $old->{credential_env} // 'none' ).' -> '.( $entry->{credential_env} // 'none' ) : undef;
    $out->emit($out->c(warn => "replaces the stored binding '".$alias."'"
      .( defined $env_changed ? ' ('.$env_changed.'; the value of the new variable is what is sent)'
        : defined $why ? ' (differs: '.$why.')' : ' (same pin; metadata is rewritten)' )), "\n");
  }
  $out->emit("\n", $out->c(meta => 'Raider will keep this origin, issuer and auth; a change of any of them stops '
    .'--provider '.$alias.' until you accept again.'), "\n");
  $out->emit('Store this binding in ', $config->home_file // '~/.raider/config.yml', '? [y/N] ');
  my $in = $self->in;
  my $answer = <$in>;
  unless ( defined $answer && $answer =~ /\A\s*y(?:es)?\s*\z/i ) {
    $say->('not stored');
    return 1;
  }
  my $written = eval {
    $config->update_home(sub {
      my ( $data ) = @_;
      $data->{providers} //= {};
      $data->{providers}{$alias} = $entry;
      return 1;
    });
  };
  unless ($written) {
    $say->('not stored: '.$self->output->error_text($@ || 'the home file was not written'));
    return 1;
  }
  $out->emit($out->c(title => "bound '".$alias."'"), ': raider --provider '.$alias."\n");
  return 0;
}


sub list {
  my ( $self, %opt ) = @_;
  my $rows = $self->_rows($opt{config});
  return 1 unless $rows;
  if ( my $machine = $opt{machine} ) {
    $machine->write({ version => $machine->version, status => 'completed',
      providers => [ map { $self->_public($_) } @$rows ] });
    return 0;
  }
  my $out = $self->output;
  unless (@$rows) {
    $out->emit($out->c(meta => 'no provider aliases; bind one with: raider provider add ALIAS HOST'), "\n");
    return 0;
  }
  for my $row (@$rows) {
    $out->emit(sprintf('%s  ', $out->c(title => sprintf('%-16s', $row->{alias}))),
      $row->{problem} ? $out->c(warn => 'unusable: '.$row->{problem})
        : join('  ', $row->{origin},
          $out->c(meta => 'auth: '.( @{ $row->{auth} } ? join(', ', @{ $row->{auth} }) : 'none' )),
          $out->c(meta => 'credential: '.( $row->{credential_env} // 'none' )),
          ( $row->{allow_internal} ? $out->c(warn => 'internal allowed') : () )),
      "\n");
  }
  return 0;
}


sub describe {
  my ( $self, $alias, %opt ) = @_;
  my $rows = $self->_rows($opt{config});
  return 1 unless $rows;
  my ( $row ) = grep { $_->{alias} eq ( $alias // '' ) } @$rows;
  unless ($row) {
    $self->_err("raider provider show: no stored alias '".( $alias // '' )."'\n");
    return 2;
  }
  if ( my $machine = $opt{machine} ) {
    $machine->write({ version => $machine->version, status => 'completed', provider => $row });
    return 0;
  }
  my $out = $self->output;
  my $line = sub { $out->emit($out->c(meta => sprintf('%-15s ', $_[0])), @_[ 1 .. $#_ ], "\n") };
  $line->('alias', $out->c(title => $row->{alias}));
  $line->('unusable', $out->c(warn => $row->{problem})) if $row->{problem};
  $line->('origin', $row->{origin} // '');
  $line->('issuer', $row->{issuer} // '');
  $line->('auth', @{ $row->{auth} // [] } ? join(', ', @{ $row->{auth} }) : 'none');
  $line->('credential_env', $row->{credential_env} // 'none');
  $line->('allow_internal', $row->{allow_internal} ? 'yes' : 'no');
  $line->('pinned_at', $row->{pinned_at} // '');
  $line->('fingerprint', $row->{fingerprint} // '');
  return 0;
}


sub remove {
  my ( $self, $alias, %opt ) = @_;
  my $say = sub { $self->_err('raider provider remove: '.join('', @_)."\n") };
  my $config = $opt{config};
  my $stored = eval { $config->providers };
  unless ($stored) {
    $say->($self->output->error_text($@));
    return 1;
  }
  unless ( defined $alias && exists $stored->{$alias} ) {
    $say->("no stored alias '".( $alias // '' )."'");
    return 2;
  }
  unless ( $opt{yes} ) {
    unless ($self->interactive) {
      $say->('needs a terminal to ask, or --yes; nothing was removed');
      return 1;
    }
    my $out = $self->output;
    my $entry = $stored->{$alias};
    $out->emit("Remove the binding '".$alias."'".( ref $entry eq 'HASH' && defined $entry->{origin}
      ? ' ('.$entry->{origin}.')' : '' ).' from ', $config->home_file // '~/.raider/config.yml', '? [y/N] ');
    my $in = $self->in;
    my $answer = <$in>;
    unless ( defined $answer && $answer =~ /\A\s*y(?:es)?\s*\z/i ) {
      $say->('not removed');
      return 1;
    }
  }
  my $written = eval {
    $config->update_home(sub {
      my ( $data ) = @_;
      return 0 unless ref $data->{providers} eq 'HASH' && exists $data->{providers}{$alias};
      delete $data->{providers}{$alias};
      delete $data->{providers} unless %{ $data->{providers} };
      return 1;
    });
  };
  unless ($written) {
    $say->('not removed: '.$self->output->error_text($@ || 'the home file was not written'));
    return 1;
  }
  $self->output->emit($self->output->c(title => "removed '".$alias."'"), "\n");
  return 0;
}

# The stored aliases as Binding summaries, sorted; undef (after the
# message) when the home file cannot be read.
sub _rows {
  my ( $self, $config ) = @_;
  my $stored = eval { $config->providers };
  unless ($stored) {
    $self->_err('raider provider: '.$self->output->error_text($@)."\n");
    return;
  }
  return [ map { $self->binding_class->summary($_, $stored->{$_}) } sort keys %$stored ];
}

# A row of the list document: the fingerprint is for show.
sub _public {
  my ( $self, $row ) = @_;
  return { map { $_ => $row->{$_} } grep { $_ ne 'fingerprint' } keys %$row };
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
  my ( $self, $doc, $manifest, %opt ) = @_;
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
  $out->emit("\n", $out->c(meta => 'What the provider claims; nothing was stored or bound.'), "\n")
    unless exists $opt{footer} && !$opt{footer};
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

Langertha::Raider::CLI::Provider - Internal provider commands of the raider CLI: inspect a manifest, bind an alias, activate it for --provider

=head1 VERSION

version 0.504

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

C<raider provider add ALIAS HOST>: L</add> shows what a manifest declares
and what would be pinned, asks a person, and stores the alias in the home
file (L<Langertha::Raider::Provider::Binding>); C<raider --provider ALIAS>
then activates through the stored binding and stops when it no longer
matches. C<provider list>, C<show> and C<remove> manage the stored
aliases.

=head2 output

The L<Langertha::Raider::CLI::Output> the result goes to. Required.

=head2 err

Filehandle for failures in human output. Defaults to C<STDERR>.

=head2 in

Filehandle the confirmation of L</add> is read from. Defaults to C<STDIN>.

=head2 interactive

True when a person can confirm: L</in> and the output are terminals.
L</add> stores nothing otherwise. Decided from the handles; a test sets it.

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
      allow_internal => $bool, model => $model, endpoint => $id, has_api_key => $bool,
      machine => $machine, t0 => $t0,
      binding => { alias => $alias, entry => $entry, credential_env => $name });

With C<binding> (C<raider --provider ALIAS>) the manifest must still be
what the alias accepted (L<Langertha::Raider::Provider::Binding/verify>);
otherwise nothing runs and the message says to run C<raider provider add>
again. C<$target> is then the alias's origin and C<allow_internal> its own,
stored one.

C<raider --provider TARGET>: the endpoint of the provider's manifest the
run uses, through L<Langertha::Raider::Provider::Activation>. Returns
C<undef> and the completed activation, with its warnings written to
L</err>; or, after writing why to L</err>, just the exit status: C<2> when
the command line has to change (a target that is none, a model the
manifest does not list, no model where it lists several, no key where
the endpoint needs one), C<1> when the provider cannot be used as it is
(refused, not fetched, not valid, not usable by this raider). C<t0>, the
L<Time::HiRes> time the run started, is where the C<elapsed> of a failure
document counts from; without it, the start of the activation.

=head2 failure_document

    $provider->failure_document($machine, 'refused', $error, $target, $t0);

With a machine format (C<--json> and friends), the C<--provider> that could
not run is also a document on stdout, as for a run that failed (ADR 0013):
C<status> C<refused> for a policy refusal (address, redirect, origin, a
stored alias that no longer matches), else C<failed> (also for a usage
error, whose exit status stays C<2>), C<reason> C<provider>, C<error> and
the C<provider> target, and C<elapsed>: the seconds since the
L<Time::HiRes> time C<$t0>, to the millisecond
(L<Langertha::Raider::CLI::Runner/elapsed_since>).
The message on L</err> is kept.

=head2 add

    my $exit = $provider->add($alias, $target, config => $config,
      allow_internal => $bool, credential_env => $name);

C<raider provider add ALIAS HOST>: fetches and validates the manifest of
C<$target> (L</inspect>'s fetch), shows what it declares and what would be
pinned (origin, issuer, endpoints with their origin, dialect and auth, the
environment variable the credential comes from, whether an internal
address is allowed), asks on a terminal and, on a C<y>, stores the entry
(L<Langertha::Raider::Provider::Binding>) under C<providers:> of the home
file through L<Langertha::Raider::Config/update_home> (C<$config>). An
existing alias is replaced after the same question, with what differs shown.

Never headless: without a terminal (L</interactive>) nothing is fetched and
nothing stored. Nothing is stored when the answer is not C<y>, the manifest
is not valid, or it asks for auth and no C<credential_env> was given (never
guessed from the environment).

Returns the exit status: C<0> stored, C<1> not stored (headless, declined,
refused, not fetched, not valid), C<2> when the command line has to
change (an alias or variable name that is none, a target that is none, a
C<credential_env> that does not fit the provider's auth).

=head2 list

    my $exit = $provider->list( config => $config, machine => $machine );

C<raider provider list>: the aliases stored under C<providers:> of the
home file, sorted, each with its origin, issuer, auth types, credential
variable (the name, never a value), whether an internal address is allowed
and when it was accepted; an entry that cannot be used says why. Nothing is
fetched. With a machine, one document: C<status> C<completed> and
C<providers>, a list of the L<Langertha::Raider::Provider::Binding/summary>
rows without C<fingerprint>. Returns C<0>; C<1> when the home file cannot
be read.

=head2 describe

    my $exit = $provider->describe($alias, config => $config, machine => $machine);

C<raider provider show ALIAS>: one stored alias with every field of its
entry, including the pinned C<fingerprint>. Returns C<0>; C<2> for an
alias that is not stored; C<1> when the home file cannot be read.

=head2 remove

    my $exit = $provider->remove($alias, config => $config, yes => $bool);

C<raider provider remove ALIAS>: deletes the alias from C<providers:> of
the home file through L<Langertha::Raider::Config/update_home>. Asks on a
terminal; without a terminal it needs C<yes> (C<--yes>) and is an error
otherwise, nothing removed. Returns C<0> removed, C<1> not removed
(declined, no terminal and no C<yes>, home file not written), C<2> for an
alias that is not stored.

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

    $provider->show($doc, $manifest, footer => 0);

The human report of a valid manifest. It ends with "nothing was stored or
bound" unless C<footer> is false (L</add> stores after it).

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Provider::Fetch>

=item * L<Langertha::Raider::CLI::Main>

=item * L<raider> -- C<PROVIDERS>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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

L<https://raudssus.de/>

=cut
