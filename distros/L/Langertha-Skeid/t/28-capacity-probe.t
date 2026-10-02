use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Capacity is a probe, not only a counter (ADR 0009). inflight is exact for one Skeid in front
# of one node and wrong the moment anything else sends work there -- a second frontend, a
# prefork worker, a batch job. A probe reports what the node or the provider actually says.
#
# The rule that makes this safe: a probe may only narrow what max_conns already allows. If a
# reading could widen admission, a stale or broken probe would become an overload.

# --- the reading, and what admission does with it ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 4);

  ok !$skeid->capacity_reading('n1'), 'a node with no probe has no reading';
  is $skeid->route_state(model => 'm')->{has_available}, 1, 'and inflight decides, as before';

  $skeid->set_capacity_reading('n1', used => 2, limit => 8, source => 'prometheus');
  my $reading = $skeid->capacity_reading('n1');
  is $reading->{used}, 2, 'a reading records what is used';
  is $reading->{limit}, 8, 'and the ceiling';
  is $reading->{source}, 'prometheus', 'and which probe said so';
  ok $reading->{at}, 'stamped with when';
  is $skeid->route_state(model => 'm')->{has_available}, 1, 'room on the node means admissible';

  $skeid->set_capacity_reading('n1', used => 8, limit => 8, source => 'prometheus');
  is $skeid->route_state(model => 'm')->{has_available}, 0,
    'a full node is not admissible even though this process holds nothing -- which is the whole '
    . 'point: inflight cannot see the other frontend that filled it';
  is $skeid->route_state(model => 'm')->{has_eligible}, 1,
    'but it stays eligible: being busy is not being unhealthy';
  is $skeid->start_request('n1'), 0, 'and admission refuses it';

  # A probe may only ever narrow. max_conns is this process's own limit -- for a rented node it
  # is a spend limit, and a provider reporting spare capacity must not raise it.
  $skeid->set_capacity_reading('n1', used => 0, limit => 1000, source => 'prometheus');
  ok $skeid->start_request('n1'), 'with the node reported empty, admission resumes';
  $skeid->start_request('n1') for 1 .. 3;
  is $skeid->node_metrics('n1')->{inflight}, 4, 'up to max_conns';
  is $skeid->start_request('n1'), 0,
    'and no further, however much room the probe reports -- a probe cannot widen max_conns';
  $skeid->finish_request('n1', ok => 1) for 1 .. 4;
}

# --- a stale reading is worse than none ---
{
  my $skeid = Langertha::Skeid->new(capacity_max_age_ms => 50);
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 4);

  $skeid->set_capacity_reading('n1', used => 8, limit => 8, at => time - 10);
  ok !$skeid->capacity_reading('n1'), 'a reading past its age is gone, not merely doubted';
  is $skeid->route_state(model => 'm')->{has_available}, 1,
    'so admission degrades to inflight rather than acting on an hour-old description of the node';

  # A backoff is not an observation that goes stale -- it is a statement about the future.
  $skeid->set_capacity_reading('n1', retry_after_ms => 30_000, at => time - 10, source => 'ratelimit');
  ok $skeid->capacity_reading('n1'), 'a pending backoff outlives the age limit';
  is $skeid->route_state(model => 'm')->{has_available}, 0, 'and still holds admission off';
}

# --- forget ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm');
  $skeid->set_capacity_reading('n1', used => 5, limit => 5);
  ok $skeid->capacity_reading('n1'), 'reading present';
  $skeid->forget_capacity('n1');
  ok !$skeid->capacity_reading('n1'), 'forget_capacity drops it -- what a probe calls when it '
    . 'loses its source, because reporting nothing beats reporting last hour';

  $skeid->set_capacity_reading('n1', used => 5, limit => 5);
  $skeid->remove_node('n1');
  $skeid->add_node(id => 'n1', url => 'http://y/v1', model => 'm');
  ok !$skeid->capacity_reading('n1'),
    'removing a node drops its reading, so a re-used id cannot inherit a description of a '
    . 'different machine';
}

# --- rate-limit headers: the probe that costs nothing ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'cloud', url => 'http://x/v1', model => 'm');

  my $r = $skeid->observe_response_headers('cloud', {
    'x-ratelimit-limit-requests'     => '100',
    'x-ratelimit-remaining-requests' => '40',
  });
  is $r->{limit}, 100, 'an OpenAI-style pair becomes a limit';
  is $r->{used}, 60, 'and what it implies is used';
  is $r->{source}, 'ratelimit', 'tagged as inferred, not measured';

  $skeid->observe_response_headers('cloud', {
    'anthropic-ratelimit-requests-limit'     => '50',
    'anthropic-ratelimit-requests-remaining' => '0',
  });
  is $skeid->route_state(model => 'm')->{has_available}, 0,
    'Anthropic spelling works too, and nothing left means nothing admitted';

  # Remaining with no limit still has to stop admission at zero -- that is the case that matters.
  my $skeid2 = Langertha::Skeid->new;
  $skeid2->add_node(id => 'cloud', url => 'http://x/v1', model => 'm');
  $skeid2->observe_response_headers('cloud', { 'x-ratelimit-remaining' => '0' });
  is $skeid2->route_state(model => 'm')->{has_available}, 0, 'remaining 0 without a limit blocks';
  $skeid2->observe_response_headers('cloud', { 'x-ratelimit-remaining' => '7' });
  is $skeid2->route_state(model => 'm')->{has_available}, 1, 'and a positive remaining does not';

  ok !$skeid2->observe_response_headers('cloud', { 'content-type' => 'application/json' }),
    'a response that says nothing about rate limits records nothing';

  # Providers meter requests and tokens separately, and for an LLM API the token budget is
  # usually what runs out first. Reading only the request quota would keep sending to a node
  # with plenty of requests left and no tokens, which answers 429 all the same.
  my $skeid3 = Langertha::Skeid->new;
  $skeid3->add_node(id => 'cloud', url => 'http://x/v1', model => 'm');
  my $tokens_tight = $skeid3->observe_response_headers('cloud', {
    'x-ratelimit-limit-requests'     => '1000',
    'x-ratelimit-remaining-requests' => '990',      # 1% used
    'x-ratelimit-limit-tokens'       => '100000',
    'x-ratelimit-remaining-tokens'   => '0',        # exhausted
  });
  is $tokens_tight->{quota}, 'tokens', 'the tightest quota is the one reported';
  is $skeid3->route_state(model => 'm')->{has_available}, 0, 'and an exhausted token budget blocks';

  my $requests_tight = $skeid3->observe_response_headers('cloud', {
    'x-ratelimit-limit-requests'     => '1000',
    'x-ratelimit-remaining-requests' => '0',
    'x-ratelimit-limit-tokens'       => '100000',
    'x-ratelimit-remaining-tokens'   => '99000',
  });
  is $requests_tight->{quota}, 'requests', 'and the other way round when requests are the tight one';
  is $skeid3->route_state(model => 'm')->{has_available}, 0, 'which also blocks';

  my $roomy = $skeid3->observe_response_headers('cloud', {
    'x-ratelimit-remaining-requests' => '900',
    'x-ratelimit-limit-requests'     => '1000',
    'x-ratelimit-remaining-tokens'   => '50000',
    'x-ratelimit-limit-tokens'       => '100000',
  });
  is $roomy->{quota}, 'tokens', 'half the tokens beats a tenth of the requests as the tighter one';
  is $skeid3->route_state(model => 'm')->{has_available}, 1, 'with room in both, it is admissible';

  my $anthropic_tokens = $skeid3->observe_response_headers('cloud', {
    'anthropic-ratelimit-input-tokens-remaining' => '0',
    'anthropic-ratelimit-input-tokens-limit'     => '20000',
  });
  is $anthropic_tokens->{used}, 20000, "Anthropic's input-token spelling is read too";

  # Header casing is not something a provider promises.
  my $mixed = $skeid2->observe_response_headers('cloud', { 'X-RateLimit-Remaining' => '3' });
  is $mixed->{limit}, 4, 'header names are matched case-insensitively';
}

# --- AKI.IO publishes no capacity signal (karr k16) ---
# Verified live against aki.io on 2026-09-15 with a real key: every route
# (GET /api/endpoints, GET /api/endpoints/<model>, POST /api/call/<model>)
# answers from a bare Apache with only Access-Control-Allow-Origin,
# Content-Length, Content-Type, Date and Server -- no x-ratelimit-*, no
# ratelimit-*, no anthropic-ratelimit-*, no Retry-After. AKI's per-key monthly
# euro budget and endpoint entitlements are enforced server-side and surface in
# the JSON body (success:false / "Client not authorized ...") on an HTTP 200,
# never as a header or a 429 status. So the passive ratelimit probe has nothing
# to read and there is no quota field to poll: AKI nodes fall back to inflight,
# which is correct for a single frontend. This pins that -- if a spelling ever
# grew that matched one of AKI's bare headers, it would fail here.
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'aki', url => 'https://aki.io', model => 'llama3_8b_chat');

  my %aki_headers = (
    'Access-Control-Allow-Origin' => '*',
    'Content-Length'              => '297',
    'Content-Type'                => 'application/json',
    'Date'                        => 'Tue, 15 Sep 2026 17:06:58 GMT',
    'Server'                      => 'Apache',
  );

  ok !$skeid->observe_response_headers('aki', { %aki_headers }),
    'AKI response headers carry no rate-limit signal, so nothing is recorded';

  # A budget/authorization failure rides in the body on a 200 -- it must not be
  # mistaken for a 429 backoff, because the status is what triggers that path.
  ok !$skeid->observe_response_headers('aki', { %aki_headers }, status => 200),
    'and an in-body AKI error on HTTP 200 still records nothing';

  ok !$skeid->capacity_reading('aki'),
    'no capacity reading exists for an AKI node -- admission stays on inflight';
}

# --- 429 becomes a backoff, and touches nothing else ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'cloud', url => 'http://x/v1', model => 'm', healthy => 1);

  my $r = $skeid->observe_response_headers('cloud', { 'retry-after' => '2' }, status => 429);
  ok $r->{retry_after}, 'Retry-After becomes a backoff';
  is $skeid->route_state(model => 'm')->{has_available}, 0, 'and admission stops';
  is $skeid->list_nodes->[0]{healthy}, 1,
    'while healthy is untouched -- rate-limited is busy, not broken, and nothing would ever '
    . 'flip an error-driven health flag back (ADR 0009 decides exactly this)';
  is $skeid->route_state(model => 'm')->{has_eligible}, 1, 'so the node stays eligible';

  my $bare = $skeid->observe_response_headers('cloud', {}, status => 429);
  ok $bare->{retry_after}, 'a 429 with no Retry-After still backs off, briefly';
}

# --- through the proxy: a provider saying "slow down" is heard without an extra request ---
{
  my %hits;
  my $rate_limited = 1;
  my $app = Mojolicious->new;
  $app->log->level('fatal');
  $app->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    $hits{count}++;
    $c->res->headers->header('x-ratelimit-limit-requests' => '10');
    $c->res->headers->header('x-ratelimit-remaining-requests' => $rate_limited ? '0' : '9');
    $c->render(json => {
      id => 'chatcmpl-1', object => 'chat.completion', model => 'm',
      choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
    });
  });
  my $upstream = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1);
  $upstream->start;
  my $port = $upstream->ports->[0];

  my $skeid = Langertha::Skeid->new(route_wait_timeout_ms => 60, route_wait_poll_ms => 5);
  $skeid->add_node(id => 'cloud', url => "http://127.0.0.1:$port/v1", model => 'm', max_conns => 8);

  my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $proxy->log->level('fatal');
  my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
  $proxy_daemon->start;
  my $proxy_port = $proxy_daemon->ports->[0];

  my $ua = Mojo::UserAgent->new;
  my $ask = sub {
    my $tx;
    my $g = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
    $ua->post("http://127.0.0.1:$proxy_port/v1/chat/completions" => json => {
      model => 'm', messages => [{ role => 'user', content => 'hi' }],
    } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    Mojo::IOLoop->remove($g);
    return $tx;
  };

  is $ask->()->res->code, 200, 'the first request goes through';
  my $reading = $skeid->capacity_reading('cloud');
  ok $reading, 'and its response headers were read on the way past';
  is $reading->{limit}, 10, 'giving the provider-reported limit';
  is $reading->{used}, 10, 'and nothing left';

  is $ask->()->res->code, 429,
    'so the next request is held rather than sent into a rate limit we were already told about';
  is $hits{count}, 1, 'the upstream was not asked again -- this probe costs zero extra requests';

  $rate_limited = 0;
  $skeid->forget_capacity('cloud');
  is $ask->()->res->code, 200, 'and once the reading is gone, traffic resumes';
  is $skeid->capacity_reading('cloud')->{used}, 1, 'with the fresh reading in place';

  is $skeid->node_metrics('cloud')->{inflight}, 0, 'no admission leaked';
  is $skeid->node_metrics('cloud')->{capacity}{source}, 'ratelimit',
    'and node_metrics reports where the number came from, so a measured node and an inferred '
    . 'one are not presented as equally known';
}

done_testing;
