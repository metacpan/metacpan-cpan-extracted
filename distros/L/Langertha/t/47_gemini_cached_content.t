#!/usr/bin/env perl
# ABSTRACT: Test Engine::Gemini cachedContent wire integration + lifecycle role (karr #22)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use HTTP::Request;

use Langertha::Engine::Gemini;
use Langertha::CachedContent;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- Build-time gates on Langertha::CachedContent ---

{
  # ttl + expire_time together is the wire's `expiration` oneof: croak.
  eval {
    Langertha::CachedContent->new(
      model => 'models/gemini-2.5-pro',
      ttl   => '300s',
      expire_time => '2030-01-01T00:00:00Z',
    );
  };
  like($@, qr/mutually exclusive/i, 'ttl + expire_time croaks');

  # Malformed name is rejected.
  eval {
    Langertha::CachedContent->new(
      name  => 'abc123',
      model => 'models/gemini-2.5-pro',
    );
  };
  like($@, qr/cachedContents\/\{id\}/, 'name without prefix croaks');
}

# --- to_create_body shape ---

{
  my $cc = Langertha::CachedContent->new(
    model              => 'models/gemini-2.5-pro',
    system_instruction => 'You are careful.',
    ttl                => '300s',
    contents           => [ { role => 'user', parts => [ { text => 'long prompt' } ] } ],
    display_name       => 'reviewer',
  );
  my $body = $cc->to_create_body;
  is($body->{model}, 'models/gemini-2.5-pro', 'create body has model');
  is($body->{ttl}, '300s', 'create body has ttl');
  is($body->{displayName}, 'reviewer', 'create body has displayName');
  is(ref $body->{contents}, 'ARRAY', 'create body has contents arrayref');
  is_deeply(
    $body->{systemInstruction},
    { parts => [ { text => 'You are careful.' } ] },
    'systemInstruction wrapped in {parts:[{text}]}',
  );
}

{
  # expire_time instead of ttl: emits expireTime key, not ttl.
  my $cc = Langertha::CachedContent->new(
    model       => 'models/gemini-2.5-pro',
    expire_time => '2030-01-01T00:00:00Z',
  );
  my $body = $cc->to_create_body;
  is($body->{expireTime}, '2030-01-01T00:00:00Z', 'expire_time -> expireTime');
  ok(!exists $body->{ttl}, 'ttl absent when expire_time set');
}

{
  # to_reference requires name; drops the resource name string.
  my $cc = Langertha::CachedContent->new(
    name  => 'cachedContents/xyz',
    model => 'models/gemini-2.5-pro',
  );
  is_deeply($cc->to_reference, { cachedContent => 'cachedContents/xyz' },
    'to_reference returns the engine wire field');

  eval { Langertha::CachedContent->new(model => 'models/gemini-2.5-pro')->to_reference };
  like($@, qr/cannot reference an unnamed cache/i,
    'to_reference croaks without a name');
}

# --- from_hash upgrades a server response ---
# The resource's `expiration` is a proto oneof; its JSON form is flat, so the
# server answers with a top-level expireTime (ttl is input only) --
# ai.google.dev/api/caching, CachedContent JSON representation (karr k327).

{
  my $hash = {
    name          => 'cachedContents/abc123',
    model         => 'models/gemini-2.5-pro',
    displayName   => 'reviewer',
    createTime    => '2026-08-11T10:00:00Z',
    updateTime    => '2026-08-11T10:00:00Z',
    expireTime    => '2099-01-01T00:00:00Z',
    usageMetadata => { totalTokenCount => 4096 },
    systemInstruction => { parts => [ { text => 'be brief' } ] },
  };
  my $cc = Langertha::CachedContent->from_hash($hash);
  isa_ok($cc, 'Langertha::CachedContent');
  is($cc->name, 'cachedContents/abc123', 'name from response');
  is($cc->model, 'models/gemini-2.5-pro', 'model from response');
  is($cc->display_name, 'reviewer', 'display_name extracted');
  is($cc->create_time, '2026-08-11T10:00:00Z', 'create_time extracted');
  is($cc->update_time, '2026-08-11T10:00:00Z', 'update_time extracted');
  is($cc->expire_time, '2099-01-01T00:00:00Z', 'expire_time extracted');
  is($cc->total_token_count, 4096, 'total_token_count extracted');
  is($cc->system_instruction, 'be brief', 'system_instruction text extracted');

  ok(!$cc->is_expired, 'far-future expireTime is not expired');
}

# --- is_expired relative to wall clock ---

{
  my $past = Langertha::CachedContent->from_hash({
    name          => 'cachedContents/past',
    model         => 'models/gemini-2.5-pro',
    expireTime    => '2020-01-01T00:00:00Z',
  });
  ok($past->is_expired, 'past expireTime is_expired');

  my $absent = Langertha::CachedContent->from_hash({
    name  => 'cachedContents/x',
    model => 'models/gemini-2.5-pro',
  });
  ok(!$absent->is_expired,
    'no expiry info is conservative (returns false)');
}

# --- age_seconds + duration parser ---

{
  # createTime just under 60s ago; ttl 120s -> not expired.
  my $now = time;
  my $rfc = sub {
    my ($offset) = @_;
    my @t = gmtime( $now + $offset );
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ',
      $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
  };
  my $cc = Langertha::CachedContent->from_hash({
    name       => 'cachedContents/young',
    model      => 'models/gemini-2.5-pro',
    createTime => $rfc->(-30),
    updateTime => $rfc->(-30),
    ttl        => '120s',
  });
  my $age = $cc->age_seconds;
  ok(defined $age && $age >= 25 && $age <= 40,
    "age_seconds in 25..40 (got $age)");
  ok(!$cc->is_expired, 'young cache with 120s ttl is not expired');

  # Older cache with the same ttl -> expired. Written in the older
  # `expiration` wrapper spelling, which from_hash still reads (ADR 0018).
  my $old = Langertha::CachedContent->from_hash({
    name       => 'cachedContents/old',
    model      => 'models/gemini-2.5-pro',
    createTime => $rfc->(-200),
    updateTime => $rfc->(-200),
    expiration => { ttl => '120s' },
  });
  ok($old->is_expired, 'old cache past 120s ttl is_expired');
}

# --- Engine::Gemini chat_request injects cachedContent ---

{
  my $cc = Langertha::CachedContent->new(
    name  => 'cachedContents/abc',
    model => 'models/gemini-2.5-pro',
  );
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k',
    model   => 'gemini-2.5-pro',
    cached_content => $cc,
  );
  my $body = $json->decode($engine->chat('hi')->content);
  is($body->{cachedContent}, 'cachedContents/abc',
    'chat() injects cachedContent when bound');
}

# Without cached_content bound, no field reaches the wire.
{
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro',
  );
  my $body = $json->decode($engine->chat('hi')->content);
  ok(!exists $body->{cachedContent},
    'chat() omits cachedContent when not bound');
}

# Streaming path: cachedContent present in streamGenerateContent body.
{
  my $cc = Langertha::CachedContent->new(
    name  => 'cachedContents/stream',
    model => 'models/gemini-2.5-pro',
  );
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro', cached_content => $cc,
  );
  my $sbody = $json->decode($engine->chat_stream('hi')->content);
  is($sbody->{cachedContent}, 'cachedContents/stream',
    'chat_stream() injects cachedContent when bound');
}

# Croak loudly when cached_content is set but lacks a name.
{
  my $cc = Langertha::CachedContent->new(
    model => 'models/gemini-2.5-pro', ttl => '300s',
  );
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro', cached_content => $cc,
  );
  eval { $engine->chat('hi') };
  like($@, qr/must be a Langertha::CachedContent with a 'name'/i,
    'croaks on unnamed cached_content at request build time');
}

# --- engine_capabilities: cached_content flag per model family (ADR 0002) ---

{
  for my $m (qw(gemini-2.5-pro gemini-2.5-flash)) {
    my $e = Langertha::Engine::Gemini->new(api_key => 'k', model => $m);
    ok( $e->supports('cached_content'),
      "$m advertises cached_content" );
  }

  for my $m (qw(gemini-3-flash-preview gemini-3.1-pro-preview gemini-3-pro-preview)) {
    my $e = Langertha::Engine::Gemini->new(api_key => 'k', model => $m);
    ok( $e->supports('cached_content'),
      "$m advertises cached_content" );
  }

  my $old = Langertha::Engine::Gemini->new(api_key => 'k', model => 'gemini-2.0-flash');
  ok( !$old->supports('cached_content'),
    'gemini-2.0-flash does NOT advertise cached_content (older generation)' );
}

# --- chat_response surfaces cached_content_token_count (karr #22, 22e) ---

{
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro',
  );

  my $payload = {
    candidates => [ {
      content => { parts => [ { text => 'cached answer' } ], role => 'model' },
      finishReason => 'STOP',
    } ],
    usageMetadata => {
      promptTokenCount        => 100,
      candidatesTokenCount    => 5,
      totalTokenCount         => 105,
      cachedContentTokenCount => 80,
    },
    modelVersion => 'gemini-2.5-pro',
  };
  my $http_res = HTTP::Response->new(200, 'OK');
  $http_res->header('Content-Type' => 'application/json');
  $http_res->content($json->encode($payload));

  my $resp = $engine->chat_response($http_res);
  is($resp->content, 'cached answer', 'content extracted');
  is($resp->usage->{cached_content_token_count}, 80,
    'cached_content_token_count surfaced in Response.usage');

  # Negative case: usageMetadata without cachedContentTokenCount -> key absent.
  my $payload2 = {
    candidates => [ {
      content => { parts => [ { text => 'plain' } ], role => 'model' },
      finishReason => 'STOP',
    } ],
    usageMetadata => {
      promptTokenCount => 10,
      candidatesTokenCount => 5,
      totalTokenCount => 15,
    },
  };
  my $http_res2 = HTTP::Response->new(200, 'OK');
  $http_res2->header('Content-Type' => 'application/json');
  $http_res2->content($json->encode($payload2));

  my $resp2 = $engine->chat_response($http_res2);
  ok(!exists $resp2->usage->{cached_content_token_count},
    'cached_content_token_count key absent when usageMetadata does not set it');
}

# --- Role::CachedContent lifecycle methods exist + URL shape (offline) ---

{
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro',
  );

  # Confirm the lifecycle methods exist and that _normalize_name does the
  # right thing (we don't issue network requests).
  my @lifecycle = qw(
    create_cached_content_f
    get_cached_content_f
    list_cached_contents_f
    update_cached_content_f
    delete_cached_content_f
    create_cached_content
    get_cached_content
    list_cached_contents
    update_cached_content
    delete_cached_content
  );
  for my $m (@lifecycle) {
    ok( $engine->can($m), "engine has method $m" );
  }

  # Internal URL builders: confirm shape (offline check, no HTTP issued).
  my $list_url = $engine->_cached_contents_url;
  like($list_url, qr{/v1beta/cachedContents\z},
    '_cached_contents_url ends in /v1beta/cachedContents');

  my $item_url = $engine->_cached_content_url('cachedContents/zzz');
  like($item_url, qr{/v1beta/cachedContents/zzz\z},
    '_cached_content_url embeds the name after /v1beta/');
}

# --- Role::CachedContent update_cached_content_f builds the right URL+body ---

# Helper: capture the next request built by $engine->generate_http_request
# and short-circuit user_agent dispatch so no network is issued.
#
# Strategy: override generate_http_request to record the call AND to return
# a real Langertha::Request::HTTP whose response_call is monkey-patched on
# the instance to call back into our canned-response closure. We then
# override user_agent to return a fake LWP-shaped object whose ->request
# just returns the canned HTTP::Response without touching the network.
sub _with_capture {
  my ( $engine, $response_for ) = @_;
  my @captured;
  require Langertha::Request::HTTP;

  # 'once': Gemini inherits both methods and FakeUA exists only here, so each
  # glob is named a single time in this file.
  no warnings qw( redefine once );
  *Langertha::Engine::Gemini::generate_http_request = sub {
    my ( $self, $method, $url, $cb, %body ) = @_;
    push @captured, { method => $method, url => $url, body => \%body };
    my $r = $response_for->( $method, $url );
    my $req = Langertha::Request::HTTP->new(
      http => [ uc($method), $url, [], [] ],
      request_source => $self,
      response_call  => $cb,
    );
    $req->{_canned_res} = $r;
    return $req;
  };
  *Langertha::Engine::Gemini::user_agent = sub {
    return bless {}, 'FakeUA';
  };
  *FakeUA::request = sub {
    my ( $u, $req ) = @_;
    return $req->{_canned_res};
  };

  return ( \@captured, $engine );
}

{
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro',
  );

  my ( $cap, $e ) = _with_capture( $engine, sub {
    my $r = HTTP::Response->new(200, 'OK');
    $r->header('Content-Type' => 'application/json');
    $r->content($json->encode({
      name => 'cachedContents/xyz',
      model => 'models/gemini-2.5-pro',
      expiration => { ttl => '600s' },
    }));
    return $r;
  } );

  my $cc = $e->update_cached_content('cachedContents/xyz', ttl => '600s');
  is($cap->[0]{method}, 'PATCH', 'update issues PATCH');
  like($cap->[0]{url}, qr{/v1beta/cachedContents/xyz\?},
    'update URL has /v1beta/cachedContents/xyz');
  like($cap->[0]{url}, qr/updateMask=ttl/,
    'update URL carries updateMask=ttl query param');
  is($cap->[0]{body}{ttl}, '600s', 'update body has ttl');
  is($cc->name, 'cachedContents/xyz', 'update returns parsed CachedContent');

  # croak when neither ttl nor expire_time is given.
  eval {
    $e->update_cached_content('cachedContents/xyz');
  };
  like($@, qr/exactly one of ttl \/ expire_time/i,
    'update without ttl/expire_time croaks');

  # croak when both ttl and expire_time are given.
  eval {
    $e->update_cached_content('cachedContents/xyz', ttl => '300s', expire_time => '2030-01-01T00:00:00Z');
  };
  like($@, qr/exactly one of ttl \/ expire_time/i,
    'update with both ttl and expire_time croaks');

  # Bare id is normalized to cachedContents/{id}
  @$cap = ();
  $e->update_cached_content('xyz', ttl => '600s');
  like($cap->[0]{url}, qr{/v1beta/cachedContents/xyz\?},
    'update normalizes bare id to cachedContents/{id}');

  # stubs persist for the rest of the file (Moose method-resolution
  # caching makes a clean teardown unreliable within a single test
  # process); the teardown closure is intentionally not invoked here.
}

# --- Lifecycle role create / list / delete also build the right URL ---

{
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro',
  );

  my $resp_for = sub {
    my ( $method, $uri, $req ) = @_;
    my $r = HTTP::Response->new(200, 'OK');
    $r->header('Content-Type' => 'application/json');
    if ( $method eq 'GET' ) {
      $r->content($json->encode({ cachedContents => [
        { name => 'cachedContents/a', model => 'models/gemini-2.5-pro' },
      ], nextPageToken => undef }));
    }
    elsif ( $method eq 'DELETE' ) {
      $r->content($json->encode({}));
    }
    else {
      $r->content($json->encode({
        name => 'cachedContents/created',
        model => 'models/gemini-2.5-pro',
        expiration => { ttl => '300s' },
      }));
    }
    return $r;
  };

  my ( $cap, $e ) = _with_capture( $engine, $resp_for );

  # create
  my $cc = $e->create_cached_content(
    model => 'models/gemini-2.5-pro', ttl => '300s',
  );
  is($cap->[-1]{method}, 'POST', 'create issues POST');
  like($cap->[-1]{url}, qr{/v1beta/cachedContents\?},
    'create URL is /v1beta/cachedContents');
  is($cap->[-1]{body}{model}, 'models/gemini-2.5-pro',
    'create body carries model');
  is($cc->name, 'cachedContents/created',
    'create returns parsed Langertha::CachedContent');

  # list — sync wrapper returns an arrayref of CachedContent objects.
  my $items_aref = $e->list_cached_contents;
  is($cap->[-1]{method}, 'GET', 'list issues GET');
  like($cap->[-1]{url}, qr{/v1beta/cachedContents\?},
    'list URL is /v1beta/cachedContents');
  is(scalar @$items_aref, 1, 'list returns 1 parsed CachedContent');
  is($items_aref->[0]->name, 'cachedContents/a', 'list item name extracted');

  # delete
  my $ok = $e->delete_cached_content('cachedContents/a');
  is($cap->[-1]{method}, 'DELETE', 'delete issues DELETE');
  like($cap->[-1]{url}, qr{/v1beta/cachedContents/a\?},
    'delete URL embeds the name');
  is($ok, 1, 'delete returns 1 on success');
}

done_testing;
