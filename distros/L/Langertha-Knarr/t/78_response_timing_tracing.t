use strict;
use warnings;
use Test2::V0;
use Time::Local qw( timegm );
use JSON::MaybeXS;

use Langertha::Response;
use Langertha::RateLimit;

use Langertha::Knarr::Config;
use Langertha::Knarr::Response;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Tracing;

# Real Langertha::Knarr::Tracing, but the flush is captured instead of POSTed
# to Langfuse. Everything below therefore exercises the actual payload
# builder, not a mock of it.
{
  package CapturingTracing;
  use Moo;
  extends 'Langertha::Knarr::Tracing';
  has captured => ( is => 'ro', default => sub { [] } );
  sub flush {
    my ($self) = @_;
    push @{ $self->captured }, @{ $self->_batch };
    $self->_batch([]);
    return;
  }
}

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub build_tracing {
  return CapturingTracing->new(
    config => Langertha::Knarr::Config->new(
      data => {
        models   => {},
        langfuse => {
          public_key => 'pk-lf-test',
          secret_key => 'sk-lf-test',
          url        => 'http://127.0.0.1:1',
        },
      },
    ),
  );
}

# ISO-8601 (UTC, ms) -> epoch float, so the timestamps Tracing emits can be
# compared as durations.
sub iso_epoch {
  my ($iso) = @_;
  my ($Y, $M, $D, $h, $m, $s, $ms) = $iso =~ /
    ^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d{3})Z$
  /x or die "unparsable timestamp: $iso";
  return timegm($s, $m, $h, $D, $M - 1, $Y) + $ms / 1000;
}

sub run_once {
  my ($response) = @_;
  my $tracing = build_tracing;
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub { $response } ),
    tracing => $tracing,
  );
  $handler->handle_chat_f(
    Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new(
      protocol => 'openai',
      model    => 'gpt-timed',
      messages => [ { role => 'user', content => 'hi' } ],
    ),
  )->get;
  my $events = $tracing->captured;
  my ($start) = grep { $_->{type} eq 'generation-create' } @$events;
  my ($end)   = grep { $_->{type} eq 'generation-update' } @$events;
  return ( $start, $end, $events );
}

subtest 'Knarr::Response carries timing, id, thinking and rate_limit' => sub {
  my $rl = Langertha::RateLimit->new(
    requests_remaining => 42,
    tokens_remaining   => 12000,
    raw                => { 'x-ratelimit-remaining-requests' => '42' },
  );
  my $lr = Langertha::Response->new(
    content    => 'answer',
    model      => 'gpt-timed',
    id         => 'chatcmpl-abc123',
    timing     => { ttft_seconds => 0.25, total_seconds => 1.5 },
    thinking   => 'first this, then that',
    rate_limit => $rl,
  );

  my $r = Langertha::Knarr::Response->coerce($lr);
  is $r->id,             'chatcmpl-abc123', 'id survives from_langertha_response';
  is $r->timing,         { ttft_seconds => 0.25, total_seconds => 1.5 }, 'timing survives';
  is $r->ttft_seconds,   0.25, 'ttft_seconds accessor';
  is $r->total_seconds,  1.5,  'total_seconds accessor';
  is $r->thinking,       'first this, then that', 'thinking survives';
  is $r->rate_limit,     $rl, 'rate_limit object survives';

  # Handler::Code clones the response to stamp the model — the metadata must
  # not fall off there either.
  my $c = $r->clone_with( model => 'other' );
  is $c->model,         'other', 'clone_with override applied';
  is $c->timing,        { ttft_seconds => 0.25, total_seconds => 1.5 }, 'clone_with keeps timing';
  is $c->id,            'chatcmpl-abc123', 'clone_with keeps id';
  is $c->thinking,      'first this, then that', 'clone_with keeps thinking';
  is $c->rate_limit,    $rl, 'clone_with keeps rate_limit';
};

subtest 'plain response has no timing' => sub {
  my $r = Langertha::Knarr::Response->coerce('hello');
  is $r->timing,        undef, 'timing undef';
  is $r->ttft_seconds,  undef, 'ttft_seconds undef without timing';
  is $r->total_seconds, undef, 'total_seconds undef without timing';
  is $r->id,            undef, 'id undef';
};

subtest 'engine timing reaches the Langfuse generation payload' => sub {
  my ($start, $end) = run_once(
    Langertha::Response->new(
      content    => 'timed answer',
      model      => 'gpt-timed',
      id         => 'chatcmpl-abc123',
      timing     => { ttft_seconds => 0.25, total_seconds => 1.5, eval_seconds => 1.2 },
      thinking   => 'first this, then that',
      rate_limit => Langertha::RateLimit->new(
        requests_remaining => 42,
        tokens_remaining   => 12000,
        raw                => { 'x-ratelimit-remaining-requests' => '42' },
      ),
    )
  );

  ok $start, 'generation-create emitted';
  ok $end,   'generation-update emitted';

  my $meta = $end->{body}{metadata};
  ok $meta, 'generation carries metadata';
  is $meta->{timing}{ttft_seconds},  0.25, 'ttft_seconds in trace payload';
  is $meta->{timing}{total_seconds}, 1.5,  'total_seconds in trace payload';
  is $meta->{timing}{eval_seconds},  1.2,  'provider stage durations survive verbatim';
  is $meta->{response_id},           'chatcmpl-abc123', 'provider response id in trace payload';
  is $meta->{thinking},              'first this, then that', 'reasoning text in trace payload';
  is $meta->{rate_limit}{requests_remaining}, 42,    'rate limit quota in trace payload';
  is $meta->{rate_limit}{tokens_remaining},   12000, 'token quota in trace payload';
  ok !exists $meta->{rate_limit}{raw}, 'raw rate limit headers deliberately not traced';

  # Langfuse expresses latency as timestamps, not durations: endTime is
  # start + total_seconds, completionStartTime (its TTFT field) is
  # start + ttft_seconds.
  my $t0 = iso_epoch( $start->{body}{startTime} );
  ok defined $end->{body}{completionStartTime}, 'completionStartTime emitted for TTFT';
  my $ttft  = iso_epoch( $end->{body}{completionStartTime} ) - $t0;
  my $total = iso_epoch( $end->{body}{endTime} ) - $t0;
  ok abs( $ttft - 0.25 ) < 0.01, "completionStartTime is start + ttft_seconds ($ttft)";
  ok abs( $total - 1.5 ) < 0.01, "endTime is start + total_seconds ($total)";

  # Nothing blessed may end up in the batch: flush() JSON-encodes it.
  ok lives { $json->encode( { batch => [$end] } ) }, 'payload is JSON-encodable'
    or note $@;
};

subtest 'without timing the proxy wall clock is used and no TTFT is claimed' => sub {
  my ($start, $end) = run_once('plain answer');

  ok $end, 'generation-update emitted';
  ok !defined $end->{body}{completionStartTime},
    'no completionStartTime without an engine-measured ttft';
  ok !exists $end->{body}{metadata},
    'no metadata key when there is nothing to record';

  my $span = iso_epoch( $end->{body}{endTime} ) - iso_epoch( $start->{body}{startTime} );
  ok $span < 1, "endTime falls back to proxy wall clock ($span)";
};

subtest 'error path still closes the generation' => sub {
  my $tracing = build_tracing;
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub { die "boom\n" } ),
    tracing => $tracing,
  );
  my $f = $handler->handle_chat_f(
    Langertha::Knarr::Session->new( id => 's' ),
    Langertha::Knarr::Request->new( protocol => 'openai', model => 'gpt-timed' ),
  );
  ok dies { $f->get }, 'failure propagates';
  my ($end) = grep { $_->{type} eq 'generation-update' } @{ $tracing->captured };
  is $end->{body}{level}, 'ERROR', 'error generation recorded';
};

done_testing;
