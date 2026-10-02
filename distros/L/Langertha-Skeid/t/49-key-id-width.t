use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Digest::SHA qw(sha1_hex);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# The customer key id is the sole separator of customers' routing, billing and manifests
# (skeid #37, ADR 0016). At 48 bits it left a thin collision and guessing margin, so it is now
# the full digest (160 bits). The old id was a prefix of the same digest, so configs written
# with short ids keep naming the same customer: a request's full id falls back to its short
# prefix, with a one-time deprecation warning at load. A config naming one key twice -- short
# and full -- is ambiguous and must not load.

my $HAS_MANIFEST = eval { require Langertha::Manifest; require Langertha::Manifest::Builder; 1 };

sub short_id { 'k_' . substr(sha1_hex($_[0]), 0, 12) }

# --- the width ---
{
  my $id = Langertha::Skeid->key_id_for_key('sk-width');
  like $id, qr/\Ak_[0-9a-f]{40}\z/, 'a key id carries the full 160-bit digest';
  is $id, 'k_' . sha1_hex('sk-width'), 'derived from the same digest as before';
  is substr($id, 0, 14), short_id('sk-width'), 'so the old short id is its prefix';
  is(Langertha::Skeid->key_id_for_key(''), 'anonymous', 'no key is still anonymous');
}

# --- a keys: entry by short id ---
{
  my $key = 'sk-legacy-policy';
  my $cfg = {
    policies       => { narrow => { models => ['m'] }, wide => {} },
    default_policy => 'wide',
    keys           => { short_id($key) => 'narrow' },
  };
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $skeid = Langertha::Skeid->new(config_reload_interval => 0, config_loader => sub { $cfg });

  my $policy = $skeid->policy_for_key(Langertha::Skeid->key_id_for_key($key));
  ok $policy->{allow_models} && $policy->{allow_models}{m} && !$policy->{allow_models}{other},
    'the full id of the key finds the entry written with its short id';
  is $skeid->policy_for_key(short_id($key)), $policy, 'the short id itself still does too';
  is $skeid->policy_for_key(Langertha::Skeid->key_id_for_key('sk-someone-else')),
    $skeid->default_policy, 'another key does not';

  is scalar(@warnings), 1, 'the short id is warned about';
  like $warnings[0], qr/key id '\Q${\ short_id($key)}\E' is a short key id .* deprecated/,
    'as deprecated, naming it';

  $cfg = { %$cfg, pricing => { m => { input_per_million => 1 } } };
  is $skeid->maybe_reload_config, 1, 'a changed config reloads';
  is scalar(@warnings), 1, 'without warning about the same short id again';
}

# --- a names: entry by short id ---
{
  my $key = 'sk-legacy-name';
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    return {
      policies       => { narrow => { models => ['m'] }, wide => {} },
      default_policy => 'wide',
      names          => { carol => short_id($key) },
      keys           => { carol => 'narrow' },
    };
  });
  ok !$skeid->policy_for_key(Langertha::Skeid->key_id_for_key($key))->{allow_models}{other},
    'a name mapped to a short id governs the key whose full id starts with it';
  is scalar(@warnings), 1, 'warned once, although the id is both a names: value and a keys: id';
}

# --- ambiguity is a load error ---
{
  my $key = 'sk-twice';
  local $SIG{__WARN__} = sub { };
  ok !eval {
    Langertha::Skeid->new(config_loader => sub {
      return {
        policies => { a => {}, b => { models => ['m'] } },
        keys     => { short_id($key) => 'a', Langertha::Skeid->key_id_for_key($key) => 'b' },
      };
    });
    1;
  }, 'a short id and the full id it prefixes, both listed, fail the load';
  like $@, qr/is the short form of .* both have a keys entry/, 'saying which';

  ok !eval {
    Langertha::Skeid->new(config_loader => sub {
      return {
        policies => { a => {}, b => { models => ['m'] } },
        names    => { dave => short_id($key) },
        keys     => { dave => 'a', Langertha::Skeid->key_id_for_key($key) => 'b' },
      };
    });
    1;
  }, 'also when the short id comes in through a name';

  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader => sub {
      return { policies => { a => {} }, keys => { short_id('sk-x') => 'a', short_id('sk-y') => 'a' } };
    },
  );
  ok $skeid, 'two unrelated short ids load fine';
}

# --- routing, billing and the manifest through the proxy ---
my %served;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body = $c->req->json || {};
  push @{$served{models}}, $body->{model};
  $c->render(json => {
    id => 'chatcmpl-1', object => 'chat.completion', model => ($body->{model} // ''),
    choices => [{ index => 0, message => { role => 'assistant', content => 'hi' }, finish_reason => 'stop' }],
    usage   => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
  });
});
my $up = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$up->start;
my $up_url = 'http://127.0.0.1:' . $up->ports->[0] . '/v1';

{
  my $LEGACY_KEY = 'sk-legacy-customer';
  my $NEW_KEY    = 'sk-new-customer';
  my @events;
  local $SIG{__WARN__} = sub { };
  my $skeid = Langertha::Skeid->new(
    route_wait_poll_ms => 5,
    store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
    config_loader      => sub {
      return {
        policies       => { narrow => { models => ['m'] }, wide => {} },
        default_policy => 'wide',
        keys => {
          short_id($LEGACY_KEY)                       => { policy => 'narrow', manifest => { models => ['m'] } },
          Langertha::Skeid->key_id_for_key($NEW_KEY)  => { policy => 'narrow', manifest => { models => ['m'] } },
        },
        manifest => { enabled => 1, public_url => 'https://llm.example.com' },
        routing  => { wait_timeout_ms => 60, wait_poll_ms => 5 },
        nodes    => [
          { id => 'n-m',     url => $up_url, model => 'm' },
          { id => 'n-other', url => $up_url, model => 'other' },
        ],
      };
    },
  );
  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $proxy->log->level('fatal');
  my $daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $base = 'http://127.0.0.1:' . $daemon->ports->[0];
  my $ua = Mojo::UserAgent->new;
  my $ask = sub {
    my ($method, $path, $key, @args) = @_;
    my $tx;
    my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
    $ua->$method("$base$path" => { Authorization => "Bearer $key" } => @args
      => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    Mojo::IOLoop->remove($guard);
    return $tx;
  };
  my $chat = sub {
    my ($key, $model) = @_;
    return $ask->(post => '/v1/chat/completions', $key,
      json => { model => $model, messages => [{ role => 'user', content => 'hi' }] });
  };

  for my $case ([legacy => $LEGACY_KEY], [new => $NEW_KEY]) {
    my ($label, $key) = @$case;
    my $full = Langertha::Skeid->key_id_for_key($key);
    @events = ();
    is $chat->($key, 'm')->res->code, 200, "$label entry: the granted model is served";
    is $events[0]{api_key_id}, $full, "$label entry: and billed under the full key id";
    is $chat->($key, 'other')->res->code, 403, "$label entry: the policy still refuses the rest";

    if ($HAS_MANIFEST) {
      my $tx = $ask->(get => '/.well-known/langertha.json', $key);
      is $tx->res->code, 200, "$label entry: the manifest is served to the key";
      my @models = sort map { $_->{id} } @{$tx->res->json->{models} || []};
      is_deeply [ do { my %u; grep { !$u{$_}++ } @models } ], ['m'], "$label entry: with its own grant";
    }
  }

  is $chat->('sk-unlisted', 'other')->res->code, 200, 'an unlisted key takes the default policy';

  SKIP: {
    skip 'Langertha::Manifest not installed (core older than the manifest)', 1 unless $HAS_MANIFEST;
    is $ask->(get => '/.well-known/langertha.json', 'sk-unlisted')->res->code, 403,
      'and gets no manifest: a short id matches only the key it is the prefix of';
  }
  $daemon->stop;
}

done_testing;
