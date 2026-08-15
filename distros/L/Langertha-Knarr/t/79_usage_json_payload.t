use strict;
use warnings;
use Test2::V0;
use Future;
use File::Temp qw( tempdir );
use HTTP::Response ();
use JSON::MaybeXS;
use Path::Tiny;

use Langertha::Response;
use Langertha::Usage;

use Langertha::Knarr::Config;
use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::RequestLog;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;

# A routed response carries usage as a Langertha::Usage object, and that
# object has no TO_JSON — handing it straight to JSON::MaybeXS dies with
# "encountered object 'Langertha::Usage=HASH(...)'". Both decorators put
# usage into a structure that is JSON-encoded moments later, so every
# assertion below goes through the real encoder: Tracing's flush (which
# builds the actual Langfuse POST body) and RequestLog's writers (which
# swallow encode errors, so a broken payload just loses the whole line).
# Inspecting the payload as a Perl structure would let both regress.

# Stands in for Net::Async::HTTP inside Tracing::flush. Everything up to and
# including the JSON encode is the real code path; this only keeps the
# request instead of putting it on a socket.
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

my $json    = JSON::MaybeXS->new( utf8 => 1 );
my $session = Langertha::Knarr::Session->new( id => 's' );

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

sub chat_request {
  return Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'gpt-test',
    messages => [ { role => 'user', content => 'hi' } ],
  );
}

# The one POSTed batch, decoded back from the bytes flush produced.
sub posted_batch {
  my ($http) = @_;
  is scalar @{ $http->requests }, 1, 'exactly one Langfuse batch posted'
    or return undef;
  return $json->decode( $http->requests->[0]->content )->{batch};
}

subtest 'routed usage survives the Langfuse encode' => sub {
  my $lr = Langertha::Response->new(
    content => 'hi',
    model   => 'gpt-test',
    usage   => { prompt_tokens => 42, completion_tokens => 17 },
  );
  # What the decorator is actually handed — the reason this test exists.
  isa_ok( Langertha::Knarr::Response->coerce($lr)->usage, ['Langertha::Usage'],
    'routed response carries a blessed usage' );

  my ( $tracing, $http ) = build_tracing;
  my $handler = Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Code->new( code => sub { $lr } ),
    tracing => $tracing,
  );
  my $r = $handler->handle_chat_f( $session, chat_request() )->get;
  is $r->content, 'hi', 'response passed through the decorator';

  my $batch = posted_batch($http) or return;
  my ($gen) = grep { $_->{type} eq 'generation-update' } @$batch;
  ok $gen, 'generation-update in the batch';
  is $gen->{body}{usage}, {
    input_tokens  => 42,
    output_tokens => 17,
    total_tokens  => 59,
  }, 'usage flattened to canonical token counts';
};

subtest 'plain hashref usage is recorded verbatim' => sub {
  my ( $tracing, $http ) = build_tracing;
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai' );
  $tracing->end_trace( $trace,
    output => 'hi',
    usage  => { input => 100, output => 50, total => 150 },
  );

  my $batch = posted_batch($http) or return;
  my ($gen) = grep { $_->{type} eq 'generation-update' } @$batch;
  is $gen->{body}{usage}, { input => 100, output => 50, total => 150 },
    'documented hashref shape passes through untouched';
};

subtest 'flush drops an unencodable batch instead of failing the request' => sub {
  my ( $tracing, $http ) = build_tracing;
  my $trace = $tracing->start_trace( model => 'gpt-test', format => 'openai' );
  push @{ $tracing->_batch }, {
    id   => 'poison',
    type => 'generation-update',
    body => { metadata => bless( {}, 'Test::Unencodable' ) },
  };

  ok lives { $tracing->flush }, 'flush survives a payload it cannot encode'
    or note $@;
  is scalar @{ $http->requests }, 0, 'nothing posted for the broken batch';

  # The poisoned batch must not wedge the buffer for the next request.
  my $t2 = $tracing->start_trace( model => 'gpt-test', format => 'openai' );
  $tracing->end_trace( $t2, output => 'later' );
  is scalar @{ $http->requests }, 1, 'the following trace still ships';
};

subtest 'routed usage survives the RequestLog encode' => sub {
  my $tmp      = tempdir( CLEANUP => 1 );
  my $log_file = "$tmp/requests.jsonl";
  my $log_dir  = "$tmp/per-request";

  my $rlog = Langertha::Knarr::RequestLog->new(
    config => Langertha::Knarr::Config->new(
      data => {
        models  => {},
        logging => { file => $log_file, dir => $log_dir },
      },
    ),
  );
  ok $rlog->_enabled, 'request log enabled';

  my $handler = Langertha::Knarr::Handler::RequestLog->new(
    wrapped => Langertha::Knarr::Handler::Code->new(
      code => sub {
        Langertha::Response->new(
          content => 'hi',
          model   => 'gpt-test',
          usage   => { prompt_tokens => 42, completion_tokens => 17 },
        );
      },
    ),
    request_log => $rlog,
  );
  $handler->handle_chat_f( $session, chat_request() )->get;

  my @lines = grep { length } split /\n/, path($log_file)->slurp_utf8;
  is scalar @lines, 1, 'the JSONL line was written, not lost in the encode';
  my $entry = $json->decode( $lines[0] );
  is $entry->{output}, 'hi', 'output logged';
  is $entry->{usage}, {
    input_tokens  => 42,
    output_tokens => 17,
    total_tokens  => 59,
  }, 'usage flattened to canonical token counts';

  # The per-request file goes through a second, separately configured encoder.
  my @files = sort grep { $_->basename =~ /\.json$/ } path($log_dir)->children;
  is scalar @files, 1, 'one per-request file written';
  is $json->decode( $files[0]->slurp_raw )->{usage}{total_tokens}, 59,
    'per-request file carries the same usage';
};

subtest 'RequestLog keeps a plain hashref usage verbatim' => sub {
  my $tmp      = tempdir( CLEANUP => 1 );
  my $log_file = "$tmp/requests.jsonl";
  my $rlog = Langertha::Knarr::RequestLog->new(
    config => Langertha::Knarr::Config->new(
      data => { models => {}, logging => { file => $log_file } },
    ),
  );
  my $handle = $rlog->start_request( model => 'gpt-test', format => 'openai' );
  $rlog->end_request( $handle,
    output => 'hi',
    usage  => { input => 100, output => 50, total => 150 },
  );

  my @lines = grep { length } split /\n/, path($log_file)->slurp_utf8;
  is scalar @lines, 1, 'one log entry';
  is $json->decode( $lines[0] )->{usage},
    { input => 100, output => 50, total => 150 },
    'documented hashref shape passes through untouched';
};

done_testing;
