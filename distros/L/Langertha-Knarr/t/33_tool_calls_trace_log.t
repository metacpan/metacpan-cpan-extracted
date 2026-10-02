use strict;
use warnings;
use Test2::V0;
use Future;
use File::Temp qw( tempdir );
use HTTP::Response ();
use JSON::MaybeXS;
use Path::Tiny;

use Langertha::Response;
use Langertha::ToolCall;

use Langertha::Knarr::Config;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::RequestLog;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;

# tool_calls are recorded in both the Langfuse trace and the JSONL request log
# (karr #11). A routed response carries them as Langertha::ToolCall objects; on
# Langertha 0.503 those have a TO_JSON, but both sinks still flatten them to
# plain hashes so the entry stays a clean structure -- and so the shape is what
# each sink wants:
#   * the trace records the FULL call (name + id + complete arguments)
#   * the JSONL log records a TRIMMED call (name + id + capped arguments)
# Every assertion goes through the real encoder (Tracing's flush builds the
# actual Langfuse POST body; RequestLog's writers swallow encode errors, so a
# broken payload would just lose the line) -- the exact "encode mine" #11 is
# about.

my $json    = JSON::MaybeXS->new( utf8 => 1 );
my $session = Langertha::Knarr::Session->new( id => 's' );

# A big argument value: long enough that the JSONL preview must truncate it,
# proving the log trims while the trace keeps it whole.
my $BIG = 'x' x 300;

sub tool_response {
  Langertha::Response->new(
    content       => 'done',
    model         => 'gpt-test',
    tool_calls    => [
      Langertha::ToolCall->new(
        id        => 'call_1',
        name      => 'lookup',
        arguments => { q => $BIG },
      ),
      Langertha::ToolCall->new(
        id        => 'call_2',
        name      => 'ping',
        arguments => { host => 'localhost' },
      ),
    ],
    finish_reason => 'tool_calls',
  );
}

sub chat_request {
  Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-test',
    messages => [ { role => 'user', content => 'hi' } ],
  );
}

# Stands in for Net::Async::HTTP inside Tracing::flush (t/79 pattern): the whole
# path up to and including the JSON encode is the real code.
{
  package CapturingHTTP;
  sub new { bless { requests => [] }, shift }
  sub requests { $_[0]{requests} }
  sub do_request {
    my ($self, %args) = @_;
    push @{ $self->{requests} }, $args{request};
    return Future->done( HTTP::Response->new(200) );
  }
}

sub build_tracing {
  my $http = CapturingHTTP->new;
  my $tracing = Langertha::Knarr::Tracing->new(
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
    _http => $http,
  );
  return ( $tracing, $http );
}

subtest 'the Langfuse trace records the full tool calls' => sub {
  my ( $tracing, $http ) = build_tracing;
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub { tool_response() } ),
    tracing => $tracing,
  );
  my $r = $handler->handle_chat_f( $session, chat_request() )->get;
  ok $r->has_tool_calls, 'response passed through the decorator with tool_calls';

  is scalar @{ $http->requests }, 1, 'one Langfuse batch posted' or return;
  my $batch = $json->decode( $http->requests->[0]->content )->{batch};
  my ($gen) = grep { $_->{type} eq 'generation-update' } @$batch;
  ok $gen, 'generation-update in the batch';

  my $tcs = $gen->{body}{metadata}{tool_calls};
  is ref $tcs, 'ARRAY', 'tool_calls recorded under generation metadata';
  is scalar @$tcs, 2, 'both tool calls present';
  is $tcs->[0]{name}, 'lookup', 'first call name';
  is $tcs->[0]{id},   'call_1', 'first call id';
  is $tcs->[0]{arguments}{q}, $BIG, 'trace keeps the FULL argument value';
  ok exists $tcs->[0]{synthetic}, 'the full ToolCall shape is preserved';
  is $tcs->[1]{name}, 'ping', 'second call name';
};

subtest 'the JSONL request log records trimmed tool calls' => sub {
  my $tmp      = tempdir( CLEANUP => 1 );
  my $log_file = "$tmp/requests.jsonl";

  my $rlog = Langertha::Knarr::RequestLog->new(
    config => Langertha::Knarr::Config->new(
      data => { models => {}, logging => { file => $log_file } },
    ),
  );
  ok $rlog->_enabled, 'request log enabled';

  my $handler = Langertha::Knarr::Handler::RequestLog->new(
    wrapped     => Langertha::Knarr::Handler::Code->new( code => sub { tool_response() } ),
    request_log => $rlog,
  );
  $handler->handle_chat_f( $session, chat_request() )->get;

  my @lines = grep { length } split /\n/, path($log_file)->slurp_utf8;
  is scalar @lines, 1, 'the JSONL line was written, not lost in the encode';
  my $entry = $json->decode( $lines[0] );

  my $tcs = $entry->{tool_calls};
  is ref $tcs, 'ARRAY', 'tool_calls logged';
  is scalar @$tcs, 2, 'both tool calls present';

  is $tcs->[0]{name}, 'lookup', 'trimmed call keeps the tool name';
  is $tcs->[0]{id},   'call_1', 'trimmed call keeps the call id';
  is ref $tcs->[0]{arguments}, '', 'arguments is a capped preview string, not the raw hash';
  ok $tcs->[0]{truncated}, 'the oversized argument is flagged truncated';
  is length $tcs->[0]{arguments}, 200, 'preview capped at 200 chars';
  unlike $tcs->[0]{arguments}, qr/\Q$BIG\E/, 'the full 300-char value is not on disk';

  is $tcs->[1]{name}, 'ping', 'small call name';
  ok !$tcs->[1]{truncated}, 'a small argument set is not truncated';
  is $tcs->[1]{arguments}, '{"host":"localhost"}', 'small args kept as a compact preview';
};

subtest 'no tool_calls: the fields stay empty, nothing breaks' => sub {
  my ( $tracing, $http ) = build_tracing;
  my $th = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new(
      code => sub { Langertha::Response->new( content => 'plain', model => 'gpt-test' ) },
    ),
    tracing => $tracing,
  );
  $th->handle_chat_f( $session, chat_request() )->get;
  my $batch = $json->decode( $http->requests->[0]->content )->{batch};
  my ($gen) = grep { $_->{type} eq 'generation-update' } @$batch;
  ok !( $gen->{body}{metadata} && $gen->{body}{metadata}{tool_calls} ),
    'no tool_calls key in the trace metadata for a plain response';

  my $tmp  = tempdir( CLEANUP => 1 );
  my $rlog = Langertha::Knarr::RequestLog->new(
    config => Langertha::Knarr::Config->new(
      data => { models => {}, logging => { file => "$tmp/r.jsonl" } },
    ),
  );
  my $lh = Langertha::Knarr::Handler::RequestLog->new(
    wrapped     => Langertha::Knarr::Handler::Code->new(
      code => sub { Langertha::Response->new( content => 'plain', model => 'gpt-test' ) },
    ),
    request_log => $rlog,
  );
  $lh->handle_chat_f( $session, chat_request() )->get;
  my @lines = grep { length } split /\n/, path("$tmp/r.jsonl")->slurp_utf8;
  is scalar @lines, 1, 'plain response still logs a line';
  ok !defined $json->decode( $lines[0] )->{tool_calls},
    'tool_calls is null when the response had none';
};

done_testing;
