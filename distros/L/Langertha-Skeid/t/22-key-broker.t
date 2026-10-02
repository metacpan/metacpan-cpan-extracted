use strict;
use warnings;
use Test2::V0;

use Langertha::Skeid::KeyBroker;

# Base class requires subclass to implement resolve_key
my $broker = Langertha::Skeid::KeyBroker->new;
ok $broker, 'base broker instantiates';
is $broker->needs_refresh, 0, 'needs_refresh defaults to false';

# resolve_key dies with useful message
like dies { $broker->resolve_key('some/path') },
  qr/must implement resolve_key/,
  'base resolve_key croaks';

# Subclass works
{
  package TestBroker;
  use Moo;
  extends 'Langertha::Skeid::KeyBroker';
  has _keys => (is => 'ro', default => sub { {} });
  sub resolve_key {
    my ($self, $ref) = @_;
    return $self->_keys->{$ref} // die "no key for $ref";
  }
}

my $tb = TestBroker->new(_keys => { 'provider/groq' => 'gsk_test123' });
is $tb->resolve_key('provider/groq'), 'gsk_test123', 'subclass resolves key';
like dies { $tb->resolve_key('missing') }, qr/no key for/, 'missing key dies';

# Test api_key_ref passes through add_node
use Langertha::Skeid;

my $skeid = Langertha::Skeid->new;
$skeid->add_node(
  id => 'groq-llama',
  url => 'https://api.groq.com/openai/v1',
  model => 'llama-4-scout',
  api_key_ref => 'provider/groq/api-key',
);
my $node = $skeid->list_nodes->[0];
is $node->{api_key_ref}, 'provider/groq/api-key', 'api_key_ref stored on node';
ok !exists $node->{api_key_env}, 'no api_key_env when ref used';

# Test key_broker attribute
my $broker2 = TestBroker->new(_keys => { 'provider/groq/api-key' => 'gsk_test' });
my $skeid2 = Langertha::Skeid->new(key_broker => $broker2);
ok $skeid2->has_key_broker, 'has_key_broker predicate';
is $skeid2->key_broker->resolve_key('provider/groq/api-key'), 'gsk_test', 'broker resolves via skeid2';

# --- caching and coalescing (karr #3) ---
#
# Resolution is a vault round-trip on the request path. The cache is what keeps it off that
# path; the coalescing is what keeps a cold start from turning N concurrent requests into N
# round-trips. Both are in the base class, so every broker gets them.
{
  package CountingBroker;
  use Moo;
  extends 'Langertha::Skeid::KeyBroker';
  has calls   => (is => 'rw', default => sub { 0 });
  has answer  => (is => 'rw', default => sub { 'gsk_counted' });
  has waiting => (is => 'ro', default => sub { [] });
  sub resolve_key {
    my ($self, $ref) = @_;
    $self->calls($self->calls + 1);
    my $answer = $self->answer;
    die "no key for $ref" unless defined $answer;
    return $answer;
  }
  # Holds resolutions open so several can be in flight at once, which is the case coalescing
  # exists for and the only one where a synchronous test would prove nothing.
  sub resolve_key_async {
    my ($self, $ref, $cb) = @_;
    $self->calls($self->calls + 1);
    push @{$self->waiting}, [$ref, $cb];
    return;
  }
  sub release {
    my ($self, $key, $error) = @_;
    my @pending = splice @{$self->waiting};
    $_->[1]->($key, $error) for @pending;
    return scalar @pending;
  }
}

{
  my $broker = CountingBroker->new;
  my @got;
  $broker->key_async('ref/a', sub { push @got, [@_] }) for 1 .. 5;

  is $broker->calls, 1, 'five concurrent misses for one reference are one resolution';
  is scalar(@got), 0, 'and none of them answered before it came back';

  is $broker->release('gsk_counted'), 1, 'so there is one resolution to answer';
  is scalar(@got), 5, 'and its answer fans out to all five callers';
  is [map { $_->[0] } @got], [('gsk_counted') x 5], 'each with the key';

  $broker->key_async('ref/a', sub { push @got, [@_] });
  is $broker->calls, 1, 'a later request is served from cache without a round-trip';
  is $got[5][0], 'gsk_counted', 'with the same key';

  $broker->forget_key('ref/a');
  $broker->key_async('ref/a', sub { });
  is $broker->calls, 2, 'forget_key sends the next one back to the vault -- what rotation calls';
  $broker->release('gsk_rotated');
  my $after;
  $broker->key_async('ref/a', sub { $after = $_[0] });
  is $after, 'gsk_rotated', 'and the new value is what gets cached';
}

{
  # A failure must be remembered too, or a vault outage becomes one round-trip per request --
  # exactly when the vault can least afford it. Briefly, though: it is not a way to make a
  # fixed misconfiguration stick.
  my $broker = CountingBroker->new(negative_cache_ttl => 60);
  my ($key, $error);
  $broker->key_async('ref/bad', sub { ($key, $error) = @_ });
  $broker->release(undef, 'vault said no');

  is $key, undef, 'a failed resolution answers with no key';
  is $error, 'vault said no', 'and the reason';

  my $second;
  $broker->key_async('ref/bad', sub { $second = $_[1] });
  is $broker->calls, 1, 'the failure is cached, so the vault is not asked again immediately';
  is $second, 'vault said no', 'and the caller still learns why';

  ok !$broker->cached_key('ref/never-asked'), 'an unknown reference is simply not cached';
  ok $broker->cached_key('ref/bad'), 'while a cached failure is distinguishable from that';
}

{
  # cache_ttl 0 is the escape hatch for a deployment that would rather pay the round-trip.
  my $broker = CountingBroker->new(cache_ttl => 0);
  $broker->key_async('ref/a', sub { });
  $broker->release('gsk_counted');
  $broker->key_async('ref/a', sub { });
  is $broker->calls, 2, 'cache_ttl 0 disables caching';
}

{
  # A broker that only implements the blocking resolve_key still works through key_async --
  # that is what keeps a three-line custom broker viable.
  my $broker = TestBroker->new(_keys => { 'provider/groq' => 'gsk_test123' });
  my ($key, $error);
  $broker->key_async('provider/groq', sub { ($key, $error) = @_ });
  is $key, 'gsk_test123', 'the default async path falls back to resolve_key';
  is $error, undef, 'without an error';

  $broker->key_async('missing', sub { ($key, $error) = @_ });
  is $key, undef, 'a dying resolve_key becomes an error, not an exception';
  like $error, qr/no key for/, 'carrying the message';
}

# --- header injection ---
use Langertha::Skeid::Proxy;

sub inject {
  my ($headers, $skeid, $node_id) = @_;
  my $done = 0;
  Langertha::Skeid::Proxy::_inject_node_auth_async($headers, $skeid, $node_id, sub { $done = 1 });
  return $done;
}

{
  my $broker = TestBroker->new(_keys => { 'ref/test' => 'secret_key_123' });
  my $skeid = Langertha::Skeid->new(key_broker => $broker);
  $skeid->add_node(id => 'test-node', url => 'http://test', api_key_ref => 'ref/test');

  my %headers = (Authorization => 'Bearer client-key', 'x-api-key' => 'client-key');
  ok inject(\%headers, $skeid, 'test-node'), 'injection calls back';
  is $headers{Authorization}, 'Bearer secret_key_123', 'broker key overrides client key';
  ok !exists $headers{'x-api-key'},
    'and the client x-api-key is dropped, so an Anthropic-style client cannot leak its own key upstream';
}

{
  # Fallback to env var when no broker
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'env-node', url => 'http://test', api_key_env => 'TEST_SKEID_KEY');
  local $ENV{TEST_SKEID_KEY} = 'env_key_456';

  my %headers;
  inject(\%headers, $skeid, 'env-node');
  is $headers{Authorization}, 'Bearer env_key_456', 'env var fallback works';
}

{
  # A node with no key of its own forwards whatever the client sent, untouched.
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'bare-node', url => 'http://test');

  my %headers = (Authorization => 'Bearer client-key');
  ok inject(\%headers, $skeid, 'bare-node'), 'still calls back';
  is $headers{Authorization}, 'Bearer client-key', 'and leaves the client header alone';
}

{
  # An unknown node must still call back, or the request that asked for it hangs forever. It
  # calls back with a reason, though: whether that node had a key of its own can no longer be
  # known, so the client's header must not be what goes upstream in its place.
  my $skeid = Langertha::Skeid->new;
  my %headers = (Authorization => 'Bearer client-key', 'X-Api-Key' => 'client-key', accept => '*/*');
  my @answer;
  Langertha::Skeid::Proxy::_inject_node_auth_async(\%headers, $skeid, 'no-such-node',
    sub { push @answer, [@_] });
  is scalar(@answer), 1, 'an unknown node calls back rather than hanging, exactly once';
  like $answer[0][0], qr/no-such-node/, 'with a reason that names the node, so the caller refuses';
  unlike $answer[0][0], qr/client-key/, 'and not the client key';
  is \%headers, { accept => '*/*' }, 'and the client credentials are taken out of the upstream headers';
}

{
  # The client's credentials go, however the client spelled them. Mojo hands an unknown header
  # name on as it was sent, so an exact-case delete leaves `X-Api-Key` beside the node's key.
  my $broker = TestBroker->new(_keys => { 'ref/test' => 'secret_key_123' });
  my $skeid = Langertha::Skeid->new(key_broker => $broker);
  $skeid->add_node(id => 'test-node', url => 'http://test', api_key_ref => 'ref/test');

  for my $spelling ('x-api-key', 'X-Api-Key', 'X-API-KEY') {
    my %headers = (Authorization => 'Bearer client-key', $spelling => 'client-key', accept => '*/*');
    ok inject(\%headers, $skeid, 'test-node'), "$spelling: injection calls back";
    is \%headers, { Authorization => 'Bearer secret_key_123', accept => '*/*' },
      "$spelling: only the node key is left";
  }

  for my $spelling ('authorization', 'AUTHORIZATION') {
    my %headers = ($spelling => 'Bearer client-key', accept => '*/*');
    inject(\%headers, $skeid, 'test-node');
    is \%headers, { Authorization => 'Bearer secret_key_123', accept => '*/*' },
      "$spelling: a client Authorization in another spelling does not survive beside the node key";
  }
}

{
  # Broker failure falls back to env var
  package FailBroker;
  use Moo;
  extends 'Langertha::Skeid::KeyBroker';
  sub resolve_key { die "royal down" }

  package main;
  my $skeid = Langertha::Skeid->new(key_broker => FailBroker->new);
  $skeid->add_node(id => 'fail-node', url => 'http://test',
    api_key_ref => 'ref/x', api_key_env => 'TEST_SKEID_KEY');
  local $ENV{TEST_SKEID_KEY} = 'fallback_key';

  my %headers;
  inject(\%headers, $skeid, 'fail-node');
  is $headers{Authorization}, 'Bearer fallback_key', 'falls back to env on broker failure';
}

# --- a named key source that yields nothing ---
#
# The pass-through belongs to a node with no key of its own. A node that names one and cannot
# produce it answers with a reason instead, and the caller refuses the request: forwarding the
# client's header there would hand the customer's key to the provider (ADR 0003).
sub refusal {
  my ($headers, $skeid, $node_id) = @_;
  my @answer;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  Langertha::Skeid::Proxy::_inject_node_auth_async($headers, $skeid, $node_id, sub { push @answer, [@_] });
  is scalar(@answer), 1, "$node_id: the callback runs exactly once";
  return ($answer[0][0], join('', @warnings));
}

{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'bare-node', url => 'http://test');
  my %headers = (Authorization => 'Bearer client-key');
  my ($reason) = refusal(\%headers, $skeid, 'bare-node');
  is $reason, undef, 'a node with no key source has nothing to refuse';
}

{
  # What a failed OpenBao login at boot leaves behind: references, and nobody to resolve them.
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'ref-node', url => 'http://test', api_key_ref => 'ref/orphan');

  my %headers = (authorization => 'Bearer client-key', 'X-Api-Key' => 'client-key', accept => '*/*');
  my ($reason) = refusal(\%headers, $skeid, 'ref-node');
  like $reason, qr{api_key_ref 'ref/orphan'}, 'a reference without a broker is refused, by name';
  unlike $reason, qr/client-key/, 'without the client key in the reason';
  is \%headers, { accept => '*/*' },
    'and the client credentials are taken out of the upstream headers, however they were spelled';
}

{
  my $skeid = Langertha::Skeid->new(key_broker => FailBroker->new);
  $skeid->add_node(id => 'fail-node', url => 'http://test', api_key_ref => 'ref/x');

  my %headers = (Authorization => 'Bearer client-key');
  my ($reason, $warned) = refusal(\%headers, $skeid, 'fail-node');
  like $reason, qr{api_key_ref 'ref/x'}, 'a reference the broker cannot resolve is refused';
  ok !exists $headers{Authorization}, 'and the client key does not stay in the upstream headers';
  like $warned, qr{ref/x}, 'the broker failure is still logged with the reference';

  my ($again) = refusal({ Authorization => 'Bearer client-key' }, $skeid, 'fail-node');
  like $again, qr{api_key_ref 'ref/x'}, 'and so is its cached failure';
}

{
  my $skeid = Langertha::Skeid->new(key_broker => FailBroker->new);
  $skeid->add_node(id => 'env-node', url => 'http://test',
    api_key_ref => 'ref/x', api_key_env => 'TEST_SKEID_KEY');

  {
    delete local $ENV{TEST_SKEID_KEY};
    my ($reason) = refusal({ Authorization => 'Bearer client-key' }, $skeid, 'env-node');
    like $reason, qr{api_key_ref 'ref/x'.*api_key_env 'TEST_SKEID_KEY' is not set},
      'an unset variable is refused, and the reason names every source that was tried';
  }
  {
    local $ENV{TEST_SKEID_KEY} = '';
    my ($reason) = refusal({ Authorization => 'Bearer client-key' }, $skeid, 'env-node');
    like $reason, qr{api_key_env 'TEST_SKEID_KEY' is empty}, 'an empty variable is refused too';
  }
}

done_testing;
