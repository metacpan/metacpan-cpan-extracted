package Langertha::Knarr::Admin;
# ABSTRACT: Admin routes that deliver, rotate and drop a routing setup layered over Knarr's own, in memory only
our $VERSION = '1.103';
use Moose;
use Carp qw( croak );
use Digest::SHA qw( sha256 );
use JSON::MaybeXS;
use Log::Any qw( $log );
use POSIX ();
use Storable qw( dclone );
use Try::Tiny;
use Langertha::Knarr::Config;
use Langertha::Knarr::Tracing;


my @ROUTES = (
  { method => 'GET',    path => '/knarr/admin/status', action => 'admin_status' },
  { method => 'PUT',    path => '/knarr/admin/config', action => 'admin_put_config' },
  { method => 'DELETE', path => '/knarr/admin/config', action => 'admin_delete_config' },
  { method => 'PATCH',  path => '/knarr/admin/keys',   action => 'admin_patch_keys' },
);

# Config keys that only take effect at start, named in a refusal; any other
# key a push may not set is counted, not echoed.
my @PROCESS_KEYS = qw(
  listen workers logging admin_key remote_config public_url
  ollama_compat_version a2a token_auth routes
);

# Actions that read a body.
my %WITH_BODY = ( admin_put_config => 1, admin_patch_keys => 1 );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  my $key = delete $args->{key};
  my $min = Langertha::Knarr::Config->admin_key_min_length;
  croak __PACKAGE__.": key must be a string of at least $min characters"
    unless defined $key && !ref $key && length $key >= $min;
  $args->{_key_digest} = sha256( $class->_bytes($key) );
  return $args;
};

has _key_digest => (
  is       => 'ro',
  required => 1,
);

has stack => (
  is       => 'ro',
  required => 1,
  writer   => '_set_stack',
);

has _boot_stack => (
  is       => 'ro',
  init_arg => undef,
  writer   => '_set_boot_stack',
);

has remote_config => (
  is      => 'ro',
  isa     => 'Bool',
  default => 0,
);

has configured => (
  is       => 'ro',
  init_arg => undef,
  writer   => '_set_configured',
);

has generation => (
  is       => 'ro',
  init_arg => undef,
  default  => 0,
  writer   => '_set_generation',
);

has applied_at => (
  is       => 'ro',
  init_arg => undef,
  writer   => '_set_applied_at',
);

# The delivered layer (a HashRef of runtime keys) or undef: only in RAM.
has _push => (
  is       => 'ro',
  init_arg => undef,
  writer   => '_set_push',
);

has max_body => (
  is      => 'ro',
  isa     => 'Int',
  default => 1_048_576,
);

has free_failures => (
  is      => 'ro',
  isa     => 'Int',
  default => 2,
);

has max_lockout => (
  is      => 'ro',
  isa     => 'Int',
  default => 300,
);

# Wrong-key requests by peer address: { count, last, until }.
has _failures => (
  is      => 'ro',
  default => sub { {} },
);

has _json => (
  is      => 'ro',
  default => sub { JSON::MaybeXS->new( utf8 => 1, canonical => 1 ) },
);

sub BUILD {
  my ($self) = @_;
  $self->_set_boot_stack( $self->stack );
  $self->_set_configured( $self->_boot_configured );
  $self->_set_applied_at( $self->_now );
}

sub config_class { 'Langertha::Knarr::Config' }

sub routes { map { { %$_ } } @ROUTES }

sub _now { time }

sub _bytes {
  my ($self, $string) = @_;
  utf8::encode($string) if utf8::is_utf8($string);
  return $string;
}

# Whether the start layer alone can serve: it holds a routing setup, or
# remote_config is off (a config that must name its models).
sub _boot_configured {
  my ($self) = @_;
  return 1 unless $self->remote_config;
  return $self->_boot_routable ? 1 : 0;
}

sub _boot_routable {
  my ($self) = @_;
  my $config = $self->_boot_stack->config;
  return 1 if eval { %{ $config->models } };
  return 1 if eval { $config->default_engine };
  return 1 if eval { %{ $config->passthrough } };
  return 0;
}

# 'file', 'env' (a config not read from a file) or undef: no start layer.
sub _boot_layer {
  my ($self) = @_;
  my $config = $self->_boot_stack->config;
  return 'file' if $config->can('has_file') && $config->has_file;
  return $self->_boot_routable ? 'env' : undef;
}

sub is_key {
  my ($self, $candidate) = @_;
  return 0 unless defined $candidate && !ref $candidate && length $candidate;
  # Digests of equal length, compared without an early exit: the time does
  # not depend on how much of the key was right.
  my $given = sha256( $self->_bytes($candidate) );
  my $want  = $self->_key_digest;
  my $diff  = 0;
  $diff |= ord( substr $given, $_, 1 ) ^ ord( substr $want, $_, 1 ) for 0 .. 31;
  return $diff ? 0 : 1;
}

sub handle {
  my ($self, %args) = @_;
  my $action = $args{action} // '';
  my $peer = defined $args{peer} && length $args{peer} ? $args{peer} : 'unknown';

  if ( my $wait = $self->_locked_for($peer) ) {
    return $self->_answer( 429, 'too many requests without the admin key, try again later',
      [ 'Retry-After' => $wait ] );
  }
  unless ( $self->_authorized( $args{request} ) ) {
    $self->_record_failure($peer);
    return $self->_answer( 401, 'unauthorized' );
  }
  delete $self->_failures->{$peer};

  return $self->_answer( 501, 'the admin routes need a single-process server:'
    . ' every process holds its own setup in memory (psgi.multiprocess is set)' )
    if $args{multiprocess};

  my $body = '';
  if ( $WITH_BODY{$action} ) {
    my $max = $self->max_body;
    return $self->_answer( 413, "the request body may be at most $max bytes" )
      if ( $args{content_length} // 0 ) > $max;
    $body = $args{body} ? $args{body}->() : '';
    $body = '' unless defined $body;
    return $self->_answer( 413, "the request body may be at most $max bytes" )
      if length $body > $max;
  }

  my $method = '_'.$action;
  return $self->_answer( 404, 'no such admin route' ) unless $self->can($method);
  my @answer;
  try {
    @answer = $self->$method( $args{knarr}, $body );
  } catch {
    # Whatever died here may carry a piece of the body: logged without it.
    $log->errorf( "Admin request %s failed: %s", $action,
      $self->_scrub( $self->_first_line($_), $self->_doc_or_undef($body) ) );
    @answer = $self->_answer( 500, 'the admin request failed' );
  };
  return @answer;
}

sub status {
  my ($self) = @_;
  my $config = $self->stack->config;
  my $configured = $self->configured;
  my $models  = $configured ? eval { $config->models } || {} : {};
  my $default = $configured ? eval { $config->default_engine } : undef;
  my $upstreams = $configured ? eval { $config->passthrough } || {} : {};
  my $at = $self->applied_at;
  my $base = $self->_boot_layer;
  return {
    generation       => $self->generation + 0,
    applied_at       => POSIX::strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime $at ),
    applied_at_epoch => $at + 0,
    layers           => [ ( $base ? ($base) : () ), ( $self->_push ? ('push') : () ) ],
    configured       => $configured ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    remote_config    => $self->remote_config ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    models           => [ sort keys %$models ],
    default_engine   => $default ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    passthrough      => [ sort keys %$upstreams ],
    ( $self->stack->authorizer
      ? ( token_auth => $self->_token_auth_status ) : () ),
  };
}

# token_auth on: the backend and whether the store has a connection right
# now. Never the dsn, user, password, relation or channel, and nothing of a
# token (k82).
sub _token_auth_status {
  my ($self) = @_;
  my $stack = $self->stack;
  my $store = $stack->token_store;
  return {
    backend   => $stack->config->token_auth->{backend},
    connected => ( $store && $store->available ? JSON::MaybeXS->true : JSON::MaybeXS->false ),
  };
}

#### Actions

sub _admin_status {
  my ($self) = @_;
  return $self->_answer( 200, $self->status );
}

sub _admin_put_config {
  my ($self, $knarr, $body) = @_;
  my ( $doc, $error ) = $self->_decode($body);
  return $self->_refuse($error) unless $doc;
  return $self->_refuse('the setup must be a JSON object') unless ref $doc eq 'HASH';
  # A pushed setup carries its keys literally. An api_key_env would hand the
  # start environment's secrets to whatever url the same push names.
  if ( my @env = $self->_env_key_refs($doc) ) {
    return $self->_refuse( 'api_key_env is not accepted in a delivered setup ('
      . join( ', ', @env ) . '); deliver the key itself as api_key' );
  }
  # A pushed langfuse url travels with its own keys: merged key by key, a url
  # alone would receive the config file's Langfuse keys (Basic auth).
  if ( ref $doc->{langfuse} eq 'HASH' && exists $doc->{langfuse}{url} ) {
    my $lf = $doc->{langfuse};
    return $self->_refuse('langfuse.url is accepted only together with'
      . ' langfuse.public_key and langfuse.secret_key in the same push' )
      unless defined $lf->{public_key} && length $lf->{public_key}
          && defined $lf->{secret_key} && length $lf->{secret_key};
  }
  my %runtime = map { $_ => 1 } $self->config_class->runtime_keys;
  if ( my @other = grep { !$runtime{$_} } sort keys %$doc ) {
    my %process = map { $_ => 1 } @PROCESS_KEYS;
    my @named = grep { $process{$_} } @other;
    my $unknown = @other - @named;
    return $self->_refuse( 'only the routing setup can be set at runtime ('
      . join( ', ', $self->config_class->runtime_keys ) . ')'
      . ( @named ? '; '.join( ', ', @named ).' take effect only at start' : '' )
      . ( $unknown ? "; $unknown unknown key(s)" : '' ) );
  }
  return $self->_install_runtime( $knarr, dclone($doc), 'replaced' );
}

# Names of the model/default entries of a pushed setup that carry api_key_env.
sub _env_key_refs {
  my ($self, $doc) = @_;
  my @found;
  my $models = ref $doc->{models} eq 'HASH' ? $doc->{models} : {};
  for my $name ( sort keys %$models ) {
    my $def = $models->{$name};
    push @found, "models.$name" if ref $def eq 'HASH' && exists $def->{api_key_env};
  }
  push @found, 'default' if ref $doc->{default} eq 'HASH' && exists $doc->{default}{api_key_env};
  return @found;
}

sub _admin_patch_keys {
  my ($self, $knarr, $body) = @_;
  return $self->_answer( 409, 'there is no setup to change keys in;'
    . ' deliver one with PUT /knarr/admin/config' ) unless $self->configured;
  my ( $doc, $error ) = $self->_decode($body);
  return $self->_refuse($error) unless $doc;
  return $self->_refuse('the body must be a JSON object of name: key pairs')
    unless ref $doc eq 'HASH' && %$doc;

  # Names are looked up in both layers; the key lands in the push layer.
  my $push = dclone( $self->_push // {} );
  my $seen = $self->_layered($push);
  my $models = ref $seen->{models} eq 'HASH' ? $seen->{models} : {};
  my $default = ref $seen->{default} eq 'HASH' ? $seen->{default} : undef;
  my ( $bad, $unknown, $ambiguous ) = ( 0, 0, 0 );
  for my $name ( sort keys %$doc ) {
    my $key = $doc->{$name};
    unless ( defined $key && !ref $key && length $key ) { $bad++; next }
    my $def = ref $models->{$name} eq 'HASH' ? $models->{$name} : undef;
    my $is_default = 0;
    if ( $name eq 'default' && $default ) {
      if ($def) { $ambiguous++; next }
      ( $def, $is_default ) = ( $default, 1 );
    }
    unless ($def) { $unknown++; next }
    my $copy = dclone($def);
    $copy->{api_key} = $key;
    delete $copy->{api_key_env};
    if ($is_default) { $push->{default} = $copy }
    else             { $push->{models}{$name} = $copy }
  }
  my @problems;
  push @problems, "$bad key(s) not a non-empty string" if $bad;
  push @problems, "$unknown name(s) neither a model under models: nor default" if $unknown;
  push @problems, "'default' names both a model and the default engine" if $ambiguous;
  return $self->_refuse( 'no key changed: '.join( '; ', @problems ) ) if @problems;
  return $self->_install_runtime( $knarr, $push, 'keys changed' );
}

sub _admin_delete_config {
  my ($self, $knarr) = @_;
  my $boot = $self->_boot_stack;
  my $stack = $boot->with_config( $boot->config )->build;
  $self->_install( $knarr, $stack,
    push       => undef,
    configured => $self->_boot_configured,
  );
  $log->infof( "Admin: delivered setup dropped, generation %d, %s",
    $self->generation, $self->configured ? 'back to the start setup' : 'no setup' );
  return $self->_answer( 200, $self->status );
}

#### Applying

# The start layer's data with the push layer over it (see Layers). Nothing
# of either is modified.
sub _layered {
  my ($self, $push) = @_;
  my %data = %{ $self->_boot_stack->config->data };
  # remote_config describes how this process started, not the layered setup:
  # that one is checked like any config that must name its models.
  $data{remote_config} = 0;
  for my $key ( sort keys %{ $push || {} } ) {
    my ( $mine, $theirs ) = ( $data{$key}, $push->{$key} );
    if ( ( $key eq 'models' || $key eq 'langfuse' )
        && ref $mine eq 'HASH' && ref $theirs eq 'HASH' ) {
      $data{$key} = { %$mine, %$theirs };
    }
    else {
      $data{$key} = $theirs;
    }
  }
  return \%data;
}

sub tracing_class { 'Langertha::Knarr::Tracing' }

# A pushed (or patched) push layer on top of the start layer: validated,
# built and installed, or refused with 400 and nothing changed.
sub _install_runtime {
  my ($self, $knarr, $push, $what) = @_;
  my $config = $self->config_class->new( data => $self->_layered($push) );

  my @errors = eval { $config->validate };
  push @errors, $self->_first_line($@) if $@;
  push @errors, 'proxy_api_key must differ from the admin key'
    if !@errors && $config->has_proxy_api_key && $self->is_key( $config->proxy_api_key );
  return $self->_refuse( join( '; ', @errors ), $push ) if @errors;

  # A delivered langfuse section brings its own tracing; without one the
  # start layer's tracing stays.
  my @over;
  if ( exists $push->{langfuse} ) {
    my $tracing = eval { $self->tracing_class->new( config => $config ) };
    return $self->_refuse( 'langfuse: '.$self->_first_line($@), $push ) unless $tracing;
    @over = ( tracing => $tracing->_enabled ? $tracing : undef );
  }

  my $stack = $self->_boot_stack->with_config( $config, @over );
  @errors = $self->_build_errors($stack);
  return $self->_refuse( join( '; ', @errors ), $push ) if @errors;

  $self->_install( $knarr, $stack, push => $push, configured => 1 );
  $log->infof( "Admin: setup %s, generation %d, %d model(s)%s", $what,
    $self->generation, scalar keys %{ $config->models },
    $config->default_engine ? ' and a default engine' : '' );
  return $self->_answer( 200, $self->status );
}

# Builds the stack and every engine it names now, so a setup that cannot
# serve is refused instead of failing on its first request.
sub _build_errors {
  my ($self, $stack) = @_;
  return 'the setup cannot be built: '.$self->_first_line($@)
    unless eval { $stack->build; 1 };
  my $config = $stack->config;
  my $router = $stack->router;
  my @errors;
  for my $name ( sort keys %{ $config->models } ) {
    next if eval { $router->resolve( $name, skip_default => 1 ); 1 };
    push @errors, "Model '$name': ".$self->_first_line($@);
  }
  if ( $config->default_engine ) {
    push @errors, 'Default: '.$self->_first_line($@)
      unless eval { $router->resolve(undef); 1 };
  }
  return @errors;
}

# One step, no event loop turn in between: every request after it sees the
# new stack, every request before it keeps the old one.
sub _install {
  my ($self, $knarr, $stack, %meta) = @_;
  $knarr->_apply_stack($stack) if $knarr;
  $self->_set_stack($stack);
  $self->_set_configured( $meta{configured} ? 1 : 0 );
  $self->_set_push( $meta{push} );
  $self->_set_generation( $self->generation + 1 );
  $self->_set_applied_at( $self->_now );
  return;
}

#### Keys and lockouts

sub _authorized {
  my ($self, $req) = @_;
  return 0 unless $req;
  my $value = $req->header('Authorization');
  return 0 unless defined $value;
  $value =~ s/\A\s+|\s+\z//g;
  return 0 unless $value =~ s/\ABearer\s+//i;
  return $self->is_key($value);
}

sub _locked_for {
  my ($self, $peer) = @_;
  my $entry = $self->_failures->{$peer} or return 0;
  my $wait = ( $entry->{until} // 0 ) - $self->_now;
  return $wait > 0 ? POSIX::ceil($wait) : 0;
}

sub _record_failure {
  my ($self, $peer) = @_;
  my $now = $self->_now;
  my $table = $self->_failures;
  $self->_prune_failures($now) if keys %$table >= 10_000;
  my $entry = $table->{$peer};
  $entry = $table->{$peer} = { count => 0, until => 0 }
    if !$entry || $entry->{last} < $now - 3600;
  $entry->{count}++;
  $entry->{last} = $now;
  my $over = $entry->{count} - $self->free_failures;
  if ( $over > 0 ) {
    my $secs = 2 ** ( $over > 20 ? 20 : $over - 1 );
    $secs = $self->max_lockout if $secs > $self->max_lockout;
    $entry->{until} = $now + $secs;
  }
  $log->warnf( "Admin: refused a request from %s without the admin key (%d in a row)",
    $peer, $entry->{count} );
  return;
}

# Bounded memory: forget what no longer locks anyone out, and when that is
# not enough, everything that does not lock right now.
sub _prune_failures {
  my ($self, $now) = @_;
  my $table = $self->_failures;
  for my $peer ( keys %$table ) {
    my $entry = $table->{$peer};
    delete $table->{$peer} if $entry->{until} <= $now && $entry->{last} < $now - 3600;
  }
  return if keys %$table < 10_000;
  delete $table->{$_} for grep { $table->{$_}{until} <= $now } keys %$table;
  return;
}

#### Answers

sub _answer {
  my ($self, $status, $content, $headers) = @_;
  my $data = ref $content ? $content : { error => { message => $content } };
  my @pairs = ( [ 'Cache-Control', 'no-store' ] );
  my @extra = @{ $headers || [] };
  push @pairs, [ splice @extra, 0, 2 ] while @extra;
  return ( $status, 'application/json', $self->_json->encode($data), \@pairs );
}

sub _refuse {
  my ($self, $message, $doc) = @_;
  $message = $self->_scrub( $message, $doc );
  $log->warnf( "Admin: change refused: %s", $message );
  return $self->_answer( 400, $message );
}

# A parse error of JSON::XS & co. quotes the text around the error -- part
# of a key, possibly. Neither the answer nor the log gets it.
sub _decode {
  my ($self, $body) = @_;
  return ( undef, 'the request body is empty' ) unless defined $body && length $body;
  my $doc = eval { $self->_json->decode($body) };
  return ( undef, 'the request body is not valid JSON' ) if $@ || !defined $doc;
  return ($doc);
}

sub _doc_or_undef {
  my ($self, $body) = @_;
  return unless defined $body && length $body;
  my $doc = eval { $self->_json->decode($body) };
  return $doc;
}

# Every string value of the delivered document, four characters or more,
# is taken out of a message -- a key in the wrong place (default: "sk-...")
# would otherwise come back in the error that names the place.
sub _scrub {
  my ($self, $text, $doc) = @_;
  return $text unless defined $doc;
  my %seen;
  my @values = sort { length $b <=> length $a } grep { length >= 4 && !$seen{$_}++ }
    $self->_leaves($doc);
  $text =~ s/\Q$_\E/[redacted]/g for @values;
  return $text;
}

sub _leaves {
  my ($self, $data) = @_;
  return map { $self->_leaves($_) } values %$data if ref $data eq 'HASH';
  return map { $self->_leaves($_) } @$data if ref $data eq 'ARRAY';
  return if ref $data || !defined $data;
  return "$data";
}

sub _first_line {
  my ($self, $err) = @_;
  ( my $text = "$err" ) =~ s/\n.*//s;
  $text =~ s/\s+at \S+ line \d+\.?\s*\z//;
  return $text;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Admin - Admin routes that deliver, rotate and drop a routing setup layered over Knarr's own, in memory only

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Langertha::Knarr;
    use Langertha::Knarr::Admin;
    use Langertha::Knarr::Stack;

    my $stack = Langertha::Knarr::Stack->new( config => $config, loop => $loop );
    my $knarr = Langertha::Knarr->new(
        loop  => $loop,
        admin => Langertha::Knarr::Admin->new(
            key      => $ENV{KNARR_ADMIN_KEY},
            stack    => $stack,
            remote_config => 1,
        ),
    );

    # From the central service:
    #   PUT    /knarr/admin/config   { "models": {...}, "default": {...}, ... }
    #   PATCH  /knarr/admin/keys     { "gpt-4o": "sk-...", "default": "sk-..." }
    #   GET    /knarr/admin/status
    #   DELETE /knarr/admin/config
    # each with  Authorization: Bearer $KNARR_ADMIN_KEY

=head1 DESCRIPTION

The admin routes let a central service hand a running Knarr its routing
setup -- the models, the default engine, the passthrough upstreams, the
keys, the Langfuse section -- as JSON, rotate the keys, and take the setup
back. What arrives is held in memory only: nothing is written to a file, a
cache or a log, and a restarted Knarr has forgotten it, so the central
service delivers it again.
C<knarr start> enables the routes when L<Langertha::Knarr::Config/admin_key>
(C<KNARR_ADMIN_KEY>) is set; L<Langertha::Knarr::Config/remote_config>
lets Knarr start without any model.

=head2 Layers

What Knarr started with (the config file, or the environment's config) is
the I<start layer> and is always in effect. A delivered setup is the
I<push layer> and lies over it:

=over

=item * C<models> are merged by name: a model of the push replaces the
start model of the same name, start models without a namesake stay.

=item * C<default>, C<passthrough> and the scalar keys
(C<proxy_api_key>, C<auto_discover>, the timeouts, the probe settings):
the pushed value wins, else the start layer's.

=item * C<langfuse> is merged key by key (the pushed C<public_key> and
C<secret_key> over a start C<trace_name>, say).

=back

A C<PUT> replaces the whole push layer, never the start layer; C<DELETE>
drops the push layer and falls back to the start layer alone. Keys of
the start layer that no push can touch (C<listen>, C<logging>, C<workers>,
...) stay.

=head2 Routes

Every route answers JSON with C<Cache-Control: no-store>, and no answer
ever contains a key.

=over

=item C<GET /knarr/admin/status>

C<200> with C<generation> (how many changes since the start, C<0> before the
first), C<applied_at> (ISO 8601, UTC) and C<applied_at_epoch> (when the
current state took effect), C<layers> (the layers in effect: C<file> or
C<env> for the start layer, when it holds anything, then C<push>),
C<configured>, C<remote_config>, C<models> (the names under C<models:>, both
layers), C<default_engine> (whether there is one) and C<passthrough> (the
protocols with an upstream, without their URLs). With
L<Langertha::Knarr::Config/token_auth> it also has C<token_auth>:
C<< { backend, connected } >> (C<connected>: the token store holds a database
connection at this moment; the store connects on its first lookup). Never
the DSN, user, password, relation or channel, and nothing of a token.

=item C<PUT /knarr/admin/config>

Sets the push layer to the JSON object in the body: the keys of
L<Langertha::Knarr::Config/runtime_keys> (C<models>, C<default>,
C<passthrough>, C<auto_discover>, C<proxy_api_key>, the upstream timeouts,
the capability probe settings and C<langfuse>), structured as in the YAML
config. A key it leaves out is not set by the push (the start layer's value
applies). The process settings (C<listen>, C<workers>, C<logging>,
C<admin_key>, C<remote_config>, C<public_url>, C<a2a>, C<token_auth>,
C<routes>, ...) stay as they were at the start; a body that names one is
refused. Under C<token_auth> the admin route cannot open a hole in the token
check: the start layer's C<token_auth> is part of every layered setup, so a
push of C<models>, C<default>, C<passthrough>, C<auto_discover> or
C<proxy_api_key> fails the config validation (C<400>, nothing changed), and a
push of the other settings (C<langfuse>, the timeouts) keeps the same
authorizer and database connection. Keys arrive
literally as C<api_key>: an C<api_key_env> in a model or the default is
refused, because the start environment's secrets must not follow a pushed
C<url>. The layered setup is checked like a config file
(L<Langertha::Knarr::Config/validate>) and every model's engine, and the
default engine, is built before anything changes; any problem answers
C<400> and the running setup stays exactly as it was. A pushed C<langfuse>
section with keys switches tracing on (or to the pushed Langfuse); its
C<url> is accepted only together with its own C<public_key> and
C<secret_key> (the file's Langfuse keys never go to a pushed address); its
keys never appear in an answer or the log. On success: C<200> with the
status above, under the next generation.

=item C<PATCH /knarr/admin/keys>

Swaps API keys only: a JSON object of name to key, where a name is a model
of either layer or C<default> for the default engine (refused as ambiguous
when a model is called C<default> too). The key becomes that entry's
C<api_key> in the push layer (a start model is copied there with the new
key; the start layer itself is never changed) and its C<api_key_env> is
dropped. All names must be known and every key a non-empty string, or
nothing changes (C<400>). C<409> when there is no setup yet. Applied like a
C<PUT> of the patched push layer.

=item C<DELETE /knarr/admin/config>

Drops the push layer: back to the start layer alone, or, when it holds no
routing setup (C<remote_config> with a start of no models), to no setup,
where every other request answers C<503>.

=back

=head2 Applying a setup

A change builds a new L<Langertha::Knarr::Stack> -- a new
L<Langertha::Knarr::Router>, so the engine cache and the discovered models
start empty -- and hands it to the Knarr in one step, under the next
generation. A request that is already running, a stream in particular, goes
on with the engine it started with and is not cut off. The capability
probe (L<Langertha::Knarr::Config/probe_capabilities>) runs again for the
new router on the native server.

=head2 Keys

The admin key is the only key the admin routes accept, as
C<Authorization: Bearer> I<key>, compared in constant time. The proxy key
(L<Langertha::Knarr/auth_token>) never opens them, and a request that
presents the admin key to any other route is refused with C<401>, so the
admin key never reaches an upstream. A pushed C<proxy_api_key> equal to the
admin key is refused. The admin key is held only as its SHA-256 digest.

Error messages name the problem without echoing what was sent: a body that
is not JSON gets no excerpt, unknown names are counted, not listed, and
every string value of the body (four characters or more) is replaced by
C<[redacted]> in a message from validation.

=head2 Wrong keys

A request without the admin key gets C<401>. After L</free_failures> such
requests in a row from one peer address, every further one locks that
address out for 1, 2, 4 ... up to L</max_lockout> seconds: until then its
requests answer C<429> with C<Retry-After>, without even checking the key.
A request with the key ends the count. Failures more than an hour apart do
not add up.

=head2 Limits

The body of C<PUT> and C<PATCH> may be at most L</max_body> bytes, else
C<413>; under PSGI the body is not even read then, nor before the key was
checked. The routes are not published anywhere: not in the provider
manifest, not as a protocol route.

Each process holds its own setup, so the admin routes need a single
process: L<Langertha::Knarr> refuses L<Langertha::Knarr/workers> above
C<1> with an admin, C<knarr start> sets it to C<1> with a warning, and
under a PSGI server that sets C<psgi.multiprocess> the routes answer C<501>.

=head2 key

Required, at construction only. The admin key, at least
L<Langertha::Knarr::Config/admin_key_min_length> characters. Only its digest
is kept.

=head2 stack

Required. The L<Langertha::Knarr::Stack> Knarr starts with; afterwards the
one currently installed.

=head2 remote_config

Boolean, default C<0>. A start layer without any routing setup (no models,
no default engine, no passthrough) is allowed: L</configured> is false until
the first push, and again after a C<DELETE>.

=head2 configured

False while there is no setup to serve from (L</remote_config> with an empty
start layer, before the first push, or after a C<DELETE>). L<Langertha::Knarr> answers every route but the
admin routes with C<503> then.

=head2 generation

Starts at C<0>, one more for every change.

=head2 max_body

Largest admin request body in bytes. Default C<1048576> (1 MiB).

=head2 free_failures

Wrong-key requests in a row from one address before the lockouts start.
Default C<2>.

=head2 max_lockout

Longest lockout in seconds. Default C<300>.

=head2 routes

    my @routes = Langertha::Knarr::Admin->routes;

The admin routes as C<{ method, path, action }> hashes.

=head2 is_key

    $admin->is_key($candidate);

True when C<$candidate> is the admin key, compared in constant time.

=head2 status

The status as a HashRef (see C<GET /knarr/admin/status>).

=head2 handle

    my ( $status, $content_type, $body, $headers ) = $admin->handle(
        knarr          => $knarr,
        action         => 'admin_put_config',
        request        => $req,          # ->header($name)
        content_length => $length,
        body           => sub { $bytes },
        peer           => $address,
        multiprocess   => 0,
    );

Answers one admin request; C<$headers> are further C<[ name, value ]>
pairs. Used by L<Langertha::Knarr> and L<Langertha::Knarr::PSGI>.

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
