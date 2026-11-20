package Langertha::Skeid::KeyBroker::OpenBao;
our $VERSION = '0.005';
# ABSTRACT: OpenBao-backed KeyBroker with AppRole auth or a token file, and token renewal
use Moo;
use HTTP::Tiny;
use Mojo::IOLoop;
use Time::HiRes ();
use Mojo::UserAgent;
use JSON::MaybeXS qw(decode_json encode_json);
use POSIX qw(strftime);
use Scalar::Util qw(weaken);
use namespace::clean;

extends 'Langertha::Skeid::KeyBroker';



has addr => (
  is       => 'ro',
  required => 1,
  default  => sub { $ENV{OPENBAO_ADDR} // 'http://127.0.0.1:8200' },
);

has role_id => (
  is => 'ro',
);

has secret_id => (
  is => 'ro',
);


has token_file => (
  is => 'ro',
);

# What the token file was when it was last read: mtime, size, inode.
has _token_file_seen => (is => 'rw', default => sub { '' });

has renew_secs => (
  is      => 'rw',
  default => sub { 300 },  # 5 minutes
);


has verify_ssl => (
  is      => 'ro',
  default => sub {
    return (defined($ENV{OPENBAO_VERIFY_SSL}) && $ENV{OPENBAO_VERIFY_SSL} =~ /^(0|false|no|off)$/i)
      ? 0 : 1;
  },
);

has _http => (
  is      => 'lazy',
  builder => sub {
    my ($self) = @_;
    HTTP::Tiny->new(
      timeout    => 10,
      verify_ssl => $self->verify_ssl,
    );
  },
);

# The non-blocking client, used on the request path. HTTP::Tiny stays for boot and for callers
# with no IO loop (CLI, tests, setup scripts).
has _ua => (
  is      => 'lazy',
  builder => sub {
    my ($self) = @_;
    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout(5);
    $ua->request_timeout(10);
    $ua->insecure(1) unless $self->verify_ssl;
    return $ua;
  },
);

# Callbacks waiting on a token renewal that is already in flight.
has _refresh_waiters => (
  is      => 'ro',
  default => sub { [] },
);

has _token => (
  is      => 'rw',
  clearer => '_clear_token',
);

has _renew_token => (
  is      => 'rw',
  clearer => '_clear_renew_token',
);

has _token_expire => (
  is      => 'rw',
  default => sub { 0 },
);

has _renewal_loop => (
  is      => 'rw',
  clearer => '_clear_renewal_loop',
);

sub BUILD {
  my ($self) = @_;
  if (defined($self->token_file) && length($self->token_file)) {
    die "OpenBao: token_file and role_id/secret_id exclude each other; give one\n"
      if length($self->role_id // '') || length($self->secret_id // '');
    my $error = $self->_read_token_file;
    die "$error\n" if defined $error;
    return;
  }
  die "OpenBao: role_id and secret_id are required (or token_file)\n"
    unless length($self->role_id // '') && length($self->secret_id // '');
  # Initial token fetch
  $self->_fetch_token;
}

sub _uses_token_file { defined($_[0]->token_file) && length($_[0]->token_file) }

sub _token_file_stamp {
  my ($self) = @_;
  # Sub-second mtime: a token rewritten in place within the same second is still a change.
  my @st = Time::HiRes::stat($self->token_file);
  return @st ? join(':', @st[9, 7, 1]) : 'missing';
}

# Reads the token file into the token. Undef when it did, else why not (the path, never the
# token). A file that cannot be read leaves the token as it was.
sub _read_token_file {
  my ($self) = @_;
  my $path = $self->token_file;
  my $stamp = $self->_token_file_stamp;
  $self->_token_file_seen($stamp);
  return "OpenBao token file $path is missing" if $stamp eq 'missing';
  open(my $fh, '<', $path) or return "OpenBao token file $path cannot be read: $!";
  my $token = do { local $/; <$fh> };
  close $fh;
  $token = '' unless defined $token;
  $token =~ s/\A\s+//;
  $token =~ s/\s+\z//;
  return "OpenBao token file $path is empty" unless length $token;
  return "OpenBao token file $path holds more than one line" if $token =~ /[\r\n]/;
  $self->_token($token);
  $self->_renew_token($token);
  # The starter renews; this process only notices when the file changes.
  $self->_token_expire(9**9**9);
  return undef;
}

# A changed token file is read again; a failed read warns and keeps the token in use.
sub _reread_token_file {
  my ($self) = @_;
  return unless $self->_token_file_stamp ne $self->_token_file_seen;
  my $error = $self->_read_token_file;
  warn "$error; keeping the token read before\n" if defined $error;
  return;
}

sub _fetch_token {
  my ($self) = @_;
  my $resp = $self->_http->post(
    "${\$self->addr}/v1/auth/approle/login",
    {
      headers => { 'Content-Type' => 'application/json' },
        content => encode_json({
          role_id  => $self->role_id,
          secret_id => $self->secret_id,
        }),
    },
  );

  unless ($resp->{success}) {
    die "OpenBao AppRole login failed: " . ($resp->{content} // 'unknown error');
  }

  my $data = decode_json($resp->{content})->{auth} // {};
  my $token = $data->{client_token} // '';
  my $ttl = $data->{ttl} // 0;

  die "OpenBao AppRole login returned no token" unless length $token;

  # The token from AppRole login is ONLY for renew-self
  # Store it as _renew_token - we'll use it to get the actual API token
  $self->_renew_token($token);
  $self->_token_expire(time + ($ttl > 0 ? $ttl : 3600));

  return 1;
}


sub needs_refresh {
  my ($self) = @_;
  if ($self->_uses_token_file) {
    $self->_reread_token_file;
    return $self->_token ? 0 : 1;
  }
  # Refresh if: time is near expiry, OR we have no client_token yet
  return 1 if time >= ($self->_token_expire - 60);
  return 1 unless $self->_token;
  return 0;
}


sub refresh {
  my ($self) = @_;
  if ($self->_uses_token_file) {
    my $error = $self->_read_token_file;
    die "$error\n" if defined($error) && !$self->_token;
    warn "$error; keeping the token read before\n" if defined $error;
    return 1;
  }
  # Token renewal via renew-self endpoint
  # _token holds the RENEW token (from initial AppRole login or previous renew-self)
  # renew-self returns a NEW client_token for API calls AND a new renew token
  my $renew_token = $self->_token // $self->_renew_token;
  unless ($renew_token) {
    die "No renew token available - call _fetch_token first";
  }

  my $resp = $self->_http->post(
    "${\$self->addr}/v1/auth/token/renew-self",
    {
      headers => {
        'Content-Type'  => 'application/json',
        'X-Vault-Token' => $renew_token,
      },
      content => encode_json({}),
    },
  );

  if ($resp->{success}) {
    my $data = decode_json($resp->{content})->{auth} // {};
    my $new_client_token = $data->{client_token} // '';
    my $ttl = $data->{ttl} // 0;

    die "renew-self returned no client_token" unless length $new_client_token;

    # Store the new client_token for API calls
    $self->_token($new_client_token);

    # Store a new renew token (same as client_token in Vault's default behavior)
    # The renew_token is good for the lease_duration, then we need to renew again
    $self->_renew_token($new_client_token);
    $self->_token_expire(time + ($ttl > 0 ? $ttl : 3600));

    return 1;
  }

  # Renewal failed - need new AppRole credentials
  die "OpenBao token renewal failed. Container must be restarted to get new AppRole credential.";
}

# KV-v2 reads go through secret/data/. Callers name the logical path
# ("secret/skeid/remote/groq"); the API path is "secret/data/skeid/remote/groq".
sub _kv_path {
  my ($self, $ref) = @_;
  $ref =~ s{^/+}{};
  $ref =~ s{^secret/?}{secret/data/};
  return $ref;
}

sub _key_from_payload {
  my ($self, $payload) = @_;
  my $decoded = eval { decode_json($payload // '') } or return undef;
  my $data = $decoded->{data} // {};
  return $data->{data}{api_key} // $data->{api_key} // undef;
}


sub resolve_key {
  my ($self, $ref) = @_;
  return undef unless defined $ref && length $ref;

  # Refresh token if needed
  $self->refresh if $self->needs_refresh;

  my $token = $self->_token or die "No OpenBao token";

  my $path = $self->_kv_path($ref);
  my $resp = $self->_http->get(
    "${\$self->addr}/v1/$path",
    {
      headers => { 'X-Vault-Token' => $token },
    },
  );

  if (!$resp->{success}) {
    # Only the status: a response body from a vault read is the last thing that belongs in a
    # log line, and the reference alone is enough to find the misconfiguration.
    warn "OpenBao read failed for '$ref': HTTP " . ($resp->{status} // '???');
    return undef;
  }

  return $self->_key_from_payload($resp->{content});
}


sub resolve_key_async {
  my ($self, $ref, $cb) = @_;
  $cb ||= sub { };
  return $cb->(undef, 'no key reference') unless defined($ref) && length($ref);
  return $self->SUPER::resolve_key_async($ref, $cb) unless Mojo::IOLoop->is_running;

  my $read = sub {
    my ($token, $error) = @_;
    return $cb->(undef, $error) unless defined($token) && length($token);

    $self->_ua->get(
      $self->addr . '/v1/' . $self->_kv_path($ref) => { 'X-Vault-Token' => $token } => sub {
        my (undef, $tx) = @_;
        my $res = $tx->res;
        my $status = $res->code // 0;
        return $cb->(undef, "OpenBao read failed for '$ref': HTTP " . ($status || 'no response'))
          unless $status >= 200 && $status < 300;

        my $key = $self->_key_from_payload($res->body);
        return $cb->(undef, "OpenBao returned no api_key for '$ref'")
          unless defined($key) && length($key);
        $cb->($key, undef);
      }
    );
  };

  return $self->_refresh_async($read) if $self->needs_refresh;
  $read->($self->_token);
  return;
}

# Renews the token without blocking, and only once at a time: a cold start at concurrency 64
# would otherwise fire 64 renew-self calls, and vault would answer them with 64 different
# tokens, 63 of which are immediately stale.
sub _refresh_async {
  my ($self, $cb) = @_;
  $cb ||= sub { };

  # A token file is a local read (a tmpfs, a few bytes), not a round trip.
  if ($self->_uses_token_file) {
    my $error = $self->_read_token_file;
    return $cb->(undef, $error) if defined($error) && !$self->_token;
    warn "$error; keeping the token read before\n" if defined $error;
    return $cb->($self->_token, undef);
  }

  my $waiters = $self->_refresh_waiters;
  push @$waiters, $cb;
  return if @$waiters > 1;

  my $settle = sub {
    my ($token, $error) = @_;
    my @waiting = splice @$waiters;
    $_->($token, $error) for @waiting;
  };

  my $renew_token = $self->_token // $self->_renew_token;
  return $settle->(undef, 'No renew token available') unless $renew_token;

  $self->_ua->post(
    $self->addr . '/v1/auth/token/renew-self' => {
      'Content-Type'  => 'application/json',
      'X-Vault-Token' => $renew_token,
    } => encode_json({}) => sub {
      my (undef, $tx) = @_;
      my $status = $tx->res->code // 0;
      return $settle->(undef, 'OpenBao token renewal failed: HTTP ' . ($status || 'no response'))
        unless $status >= 200 && $status < 300;

      my $data = eval { decode_json($tx->res->body)->{auth} } // {};
      my $token = $data->{client_token} // '';
      return $settle->(undef, 'renew-self returned no client_token') unless length $token;

      my $ttl = $data->{ttl} // 0;
      $self->_token($token);
      $self->_renew_token($token);
      $self->_token_expire(time + ($ttl > 0 ? $ttl : 3600));
      $settle->($token, undef);
    }
  );
  return;
}


sub start_renewal {
  my ($self) = @_;
  return $self->_renewal_loop if $self->_renewal_loop;

  my $every = $self->renew_secs;
  $every = 60 if !$every || $every < 1;

  # Weak, or the timer's closure keeps the broker alive forever and DEMOLISH never runs -- which
  # is how a token outlives the object that was supposed to be the only thing holding it.
  my $weak = $self;
  weaken($weak);

  my $id = Mojo::IOLoop->recurring($every => sub {
    my $broker = $weak or return;
    # With a token file the starter renews; the timer reads the file again whatever its stamp
    # says, so a change no stamp shows is picked up within one interval.
    if ($broker->_uses_token_file) {
      my $error = $broker->_read_token_file;
      warn "$error; keeping the token read before\n" if defined $error;
      return;
    }
    $broker->_refresh_async(sub {
      my ($token, $error) = @_;
      return unless defined $error;
      die "OpenBao token renewal failed and the token has expired: $error"
        if time >= $broker->_token_expire;
      warn "OpenBao token renewal failed (token still valid): $error";
    });
  });
  $self->_renewal_loop($id);
  return $id;
}


sub list_secrets {
  my ($self, $path) = @_;
  return [] unless defined $path && length $path;

  $self->refresh if $self->needs_refresh;

  my $token = $self->_token or return [];
  $path =~ s{^/+}{};
  $path .= '/' unless $path =~ m{/$};

  my $resp = $self->_http->list(
    "${\$self->addr}/v1/$path",
    {
      headers => { 'X-Vault-Token' => $token },
    },
  );

  return [] unless $resp->{success};

  my $data = decode_json($resp->{content})->{data} // {};
  return [ map { $_->{key} } @{$data->{keys} // []} ];
}

sub DEMOLISH {
  my ($self) = @_;
  if (my $id = $self->_renewal_loop) {
    eval { Mojo::IOLoop->remove($id) };
    $self->_clear_renewal_loop;
  }
  $self->forget_key;
  $self->_clear_token;
  $self->_clear_renew_token;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::KeyBroker::OpenBao - OpenBao-backed KeyBroker with AppRole auth or a token file, and token renewal

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $broker = Langertha::Skeid::KeyBroker::OpenBao->new(
    addr        => $ENV{OPENBAO_ADDR} // 'http://127.0.0.1:8200',
    role_id     => $ENV{OPENBAO_ROLE_ID},
    secret_id   => $ENV{OPENBAO_SECRET_ID},
    renew_secs  => 300,  # renew token every 5 minutes
  );

  # Or many processes behind one starter that keeps a token current in a file (skeid k127):
  my $broker = Langertha::Skeid::KeyBroker::OpenBao->new(
    addr       => $ENV{OPENBAO_ADDR},
    token_file => $ENV{OPENBAO_TOKEN_FILE},   # e.g. /run/skeid/openbao-token on a tmpfs
  );

  my $api_key = $broker->resolve_key('secret/skeid/remote/openai');   # blocking; CLI and tests

  # the request path
  $broker->key_async('secret/skeid/remote/openai', sub { my ($key, $error) = @_; ... });

=head2 addr

The OpenBao address (default C<OPENBAO_ADDR>, else C<http://127.0.0.1:8200>).

=head2 role_id

The AppRole role id, injected at container start (C<OPENBAO_ROLE_ID>). Required, with
L</secret_id>, unless L</token_file> is given.

=head2 secret_id

The AppRole secret id, injected at container start (C<OPENBAO_SECRET_ID>). Held in
memory only. Required, with L</role_id>, unless L</token_file> is given.

=head2 renew_secs

How often L</start_renewal> renews the token, in seconds (default 300; below 1 means 60).

=head2 token_file

Instead of C<role_id> and C<secret_id>: a file holding the OpenBao token to use
(C<OPENBAO_TOKEN_FILE>), for many processes behind one starter (skeid k127). An AppRole
C<secret_id> is single use, so only the first process could log in with it; the starter logs in
once and keeps a periodic token current in the file, which every process reads.

The file is read at construction -- missing or empty dies, there is no fallback -- and read
again whenever it changed (its mtime, size or inode; a writer should replace it by rename), checked
before a key is resolved, and read again on every tick of the L</start_renewal> timer
(C<renew_secs>) whether or not it looks changed. This broker does not renew a token
from a file: renewing is the starter's. A file that is missing or empty later warns, naming the
path, and the last token read stays in use until OpenBao refuses it. The token is never logged.
Giving both a C<token_file> and C<role_id>/C<secret_id> dies: which one counts is not guessed.

=head2 verify_ssl

Whether to verify the OpenBao server's TLS certificate (default 1, override with
C<OPENBAO_VERIFY_SSL=0>). Turning it off on an C<https://> address means anything that can
intercept the connection can hand out this process's AppRole token and every secret it
resolves. It exists for a dev vault with a self-signed certificate and nothing else.

=head2 needs_refresh

True when there is no client token yet or it expires within the next 60 seconds.

=head2 refresh

Renews the token through C<renew-self>, blocking. Dies when there is no token to renew with or
the renewal fails -- the AppRole credential is then spent and the process has to restart. The
request path renews through L</resolve_key_async> instead.

=head2 resolve_key

  my $key = $broker->resolve_key('secret/skeid/remote/groq');

Reads the KV-v2 secret the reference names and returns its C<api_key> field, renewing the token
first when it is due. C<secret/skeid/remote/groq> is read from C<secret/data/skeid/remote/groq>.
Blocking -- never call it from a request handler. Returns undef for an empty reference, a failed
read (warned with the reference and the HTTP status only) or a secret without C<api_key>.

=head2 resolve_key_async

Non-blocking resolution against OpenBao, renewing the token first when it is due. Used by
L<Langertha::Skeid::KeyBroker/key_async>, which is what the request path calls; a cache hit
never gets here.

With no IO loop running there is nothing to yield to, so this falls back to the blocking path
— that is the CLI and the test suite, not the proxy.

=head2 start_renewal

  $broker->start_renewal;

Renews the token on a timer instead of waiting for a request to notice it expired, so the
request path finds a valid token already there. Called by
L<Langertha::Skeid::Proxy/build_app>; safe to call twice.

A failed renewal warns while the current token is still valid — a blip is not worth dropping
in-flight requests for. With a L</token_file> the timer only reads the file again. Once it has actually expired the process dies, because a Skeid that
cannot resolve keys is not a Skeid that should keep answering: the container restarts and logs
in again with its AppRole credentials (ADR 0003).

=head2 list_secrets

  my $names = $broker->list_secrets('secret/metadata/skeid/remote');

The keys under a path, via a blocking C<LIST>. The path is the API path as given -- for KV-v2
that is C<secret/metadata/...>; no C<secret/> rewriting happens here. Returns an empty arrayref
on any failure. For setup scripts, not the request path.

=head1 DESCRIPTION

This KeyBroker implementation fetches API keys from OpenBao KV-v2 secrets. It gets its token
one of two ways: an AppRole login of its own (C<role_id> + C<secret_id>), or a token a starter
keeps current in a file (L</token_file>, C<OPENBAO_TOKEN_FILE>). With a token file the broker
neither logs in nor renews -- both are the starter's -- and only reads the file; the file should
sit on a tmpfs. Security model of the AppRole mode:

=over 4

=item * AppRole credentials (C<role_id> + C<secret_id>) are injected at container start.
Construction logs in with them, blocking, and dies when the login fails.

=item * The login token is used only to call C<renew-self>; the first resolution does that and
gets the client token for API calls.

=item * C<renew-self> returns a new client token, which is also the next renew token.

=item * The token is renewed every C<renew_secs> seconds via C<renew-self> once
L</start_renewal> runs.

=item * If renewal fails after the token expired, the process dies, so the container restarts
and logs in again.

=item * Skeid never writes a secret to disk. Tokens and resolved keys live only in memory, and
are dropped when the broker is destroyed. (A token file is written by the starter, not by
Skeid.)

=back

=head1 SEE ALSO

L<Langertha::Skeid::KeyBroker>, L<Langertha::Skeid::Proxy/build_app> (which builds this broker
from C<OPENBAO_TOKEN_FILE>, or C<OPENBAO_ROLE_ID> and C<OPENBAO_SECRET_ID>, and C<OPENBAO_ADDR>)

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
