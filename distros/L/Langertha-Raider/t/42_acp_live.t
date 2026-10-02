use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw( tempdir );
use IO::Socket::IP;
use JSON::MaybeXS;
use YAML::PP;
use POSIX qw( WNOHANG );
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
use Test::Raider::Hall qw( fake_hall wait_until );
use Langertha::Raider::Hall;
use Langertha::Raider::Hall::ACP;

# Two parts:
#  * offline (always runs): drive the hall's ACP adapter against a fake
#    raider whose run fails, and prove a *failed* run does NOT end the turn
#    as end_turn and does NOT leak its error text as a normal answer -- it
#    ends session/prompt as a JSON-RPC error (karr #87). No live API.
#  * live (opt-in): TEST_LIVE=1 plus OPENAI_API_KEY spins a real hall and
#    sends a real (paid) prompt to confirm a completed run ends end_turn.

isolate_home();

my $J = JSON::MaybeXS->new;

# A stand-in for bin/raider: it writes one run.finished event to stdout,
# which the hall reads as the run's outcome. A mission mentioning "fail"
# ends the run "failed" (what a 429 / out-of-credits engine call yields),
# anything else ends "completed" with a response.
my $FAKE = <<'PERL';
use strict;
use warnings;
use JSON::PP;
$| = 1;
my $mission = $ARGV[-1] // '';
my $json = JSON::PP->new->canonical->utf8;
my %finished = ( version => 1, type => 'run.finished', seq => 1, time => time );
if ($mission =~ /fail/) {
  print $json->encode({ %finished,
    status => 'failed', error => 'Error code: 429 - insufficient_quota' }), "\n";
} else {
  print $json->encode({ %finished,
    status => 'completed', response => 'answer: '.$mission }), "\n";
}
exit 0;
PERL

subtest 'offline: a failed run ends as a JSON-RPC error, not end_turn' => sub {
  my $yml = YAML::PP->new->dump_string({
    raiders => { Oli => { persona => 'caveman', packs => [], mcp => [], isolated => 0 } },
  });
  my ($hall, $tmp) = fake_hall(script => $FAKE, yml => $yml);
  my $acp = Langertha::Raider::Hall::ACP->new(
    hall => $hall, port => 0, host => '127.0.0.1',
  );

  # Collect every JSON-RPC frame the adapter writes back to the client.
  my $stream = do {
    package Test::ACP::CaptureStream;
    sub new { bless { frames => [] }, shift }
    sub write { my ($s, $d) = @_; push @{$s->{frames}}, $d; 1 }
    sub frames { @{$_[0]->{frames}} }
    __PACKAGE__->new;
  };
  my $frames = sub { map { my $l = $_; chomp $l; $J->decode($l) } $stream->frames };
  my $reply_to = sub {
    my ($id) = @_;
    my ($f) = grep { defined $_->{id} && $_->{id} eq $id } $frames->();
    return $f;
  };
  my $chunks_of = sub {
    my ($sid) = @_;
    return grep { defined } map { $_->{params}{update}{content}{text} }
      grep { ($_->{method} // '') eq 'session/update'
        && ($_->{params}{sessionId} // '') eq $sid } $frames->();
  };
  my $new_session = sub {
    my ($id) = @_;
    $acp->_dispatch($stream, $J->encode({
      jsonrpc => '2.0', id => $id, method => 'session/new', params => { cwd => "$tmp" },
    }));
    return $reply_to->($id)->{result}{sessionId};
  };
  my $prompt = sub {
    my ($id, $sid, $text) = @_;
    $acp->_dispatch($stream, $J->encode({
      jsonrpc => '2.0', id => $id, method => 'session/prompt',
      params => { sessionId => $sid, prompt => [ { type => 'text', text => $text } ] },
    }));
    wait_until($hall, sub { defined $reply_to->($id) }, 20);
    return $reply_to->($id);
  };

  # A failed model request.
  my $fail_sid = $new_session->(1);
  like($fail_sid, qr/^acp-/, 'session created for the failing run');
  my $fail = $prompt->(2, $fail_sid, 'please fail');
  ok(defined $fail, 'session/prompt for the failed run was answered');

  ok(!(defined $fail->{result} && ($fail->{result}{stopReason} // '') eq 'end_turn'),
    'a failed run does NOT end the turn as end_turn');
  ok($fail->{error}, 'a failed run ends session/prompt as a JSON-RPC error');
  like($fail->{error}{message} // '', qr/run failed/,
    'the JSON-RPC error names it a failed run');
  like($fail->{error}{message} // '', qr/insufficient_quota/,
    'the failure text rides in the JSON-RPC error message');
  ok(!grep({ /insufficient_quota/ } $chunks_of->($fail_sid)),
    'the failure text was NOT streamed as a normal agent_message_chunk');

  # Contrast: a completed run still streams its answer and ends end_turn.
  my $ok_sid = $new_session->(3);
  my $done = $prompt->(4, $ok_sid, 'hello');
  is($done->{result}{stopReason}, 'end_turn', 'a completed run ends end_turn')
    or diag "got: " . $J->encode($done);
  ok(grep({ $_ eq 'answer: hello' } $chunks_of->($ok_sid)),
    'a completed run streams its response as an agent_message_chunk');
};

subtest 'live: real hall, real paid LLM round-trip' => sub {
  plan skip_all => 'live test: set TEST_LIVE=1 (plus OPENAI_API_KEY) to run'
    unless $ENV{TEST_LIVE} && $ENV{OPENAI_API_KEY};

  # Pick a free port.
  my $probe = IO::Socket::IP->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
  ) or plan skip_all => "cannot bind local TCP socket: $!";
  my $port = $probe->sockport;
  close $probe;

  # Locate our dev raider binary so the hall spawns the in-tree one, not
  # whatever is on $PATH from a previous install. cwd during `prove -l`
  # is the distribution root.
  my $repo = Path::Tiny::path('.')->absolute;
  my $raider_bin = $repo->child('bin', 'raider');
  die "bin/raider not executable: $raider_bin" unless -x $raider_bin;
  $ENV{RAIDER_HALL_RAIDER_BIN} = $raider_bin->stringify;

  # Make sure the spawned raider finds Langertha::Raider::CLI from the tree too.
  $ENV{PERL5LIB} = join ':', grep { defined && length }
    ($repo->child('lib')->stringify, $ENV{PERL5LIB});

  my $tmp = tempdir(CLEANUP => 1);
  path("$tmp/.raider-hall.yml")->spew_utf8(YAML::PP->new->dump_string({
    raiders => {
      Oli => {
        engine => 'openai',
        model  => 'gpt-4o-mini',
        persona => 'caveman',
        packs => [],
        mcp => [],
        isolated => 0,
      },
    },
    acp => { port => $port, host => '127.0.0.1' },
  }));

  my $pid = fork();
  die "fork: $!" unless defined $pid;

  if ($pid == 0) {
    require Langertha::Raider::Hall;
    my $hall = Langertha::Raider::Hall->new(root => path($tmp));
    $SIG{TERM} = sub { $hall->shutdown };
    eval { $hall->run };
    exit 0;
  }

  # Wait for the listener.
  my $deadline = time + 5;
  my $up;
  while (time < $deadline) {
    $up = IO::Socket::IP->new(PeerHost => '127.0.0.1', PeerPort => $port, Timeout => 1);
    last if $up;
    select undef, undef, undef, 0.1;
  }
  ok($up, "hall ACP up on $port") or do {
    kill 'TERM', $pid; waitpid $pid, 0; return;
  };
  close $up;

  require Langertha::Raider::ACP::Client;
  my $c = Langertha::Raider::ACP::Client->new(host => '127.0.0.1', port => $port);

  my $init = $c->initialize;
  ok($init->{protocolVersion}, 'initialize');

  my $sess = $c->new_session;
  like($sess->{sessionId}, qr/^acp-/, 'session created');

  my @chunks;
  my $result = eval {
    $c->prompt_stream(
      $sess->{sessionId},
      'say hi in exactly three words',
      sub {
        my ($params) = @_;
        my $text = $params->{update}{content}{text};
        push @chunks, $text if defined $text && length $text;
      },
    );
  };
  my $err = $@;

  ok(!$err, "prompt_stream returned without dying")
    or diag "error: $err";
  ok($result, 'got a final result');
  ok(scalar @chunks, 'received at least one session/update chunk')
    or diag "no streaming chunks at all";
  is($result->{stopReason}, 'end_turn', 'stopReason is end_turn')
    or diag "got: " . (defined $result->{stopReason} ? $result->{stopReason} : '(undef)');

  # Peek at what we captured — the prompt was deliberately tiny so the
  # reply should fit on one line. Useful for eyeballing a local run.
  diag "captured " . scalar(@chunks) . " chunk(s)";
  diag "last chunk: $chunks[-1]" if @chunks;

  $c->close;

  kill 'TERM', $pid;
  my $reaped;
  for (1..60) {
    if (waitpid($pid, WNOHANG) > 0) { $reaped = 1; last }
    select undef, undef, undef, 0.2;
  }
  if (!$reaped) {
    kill 'KILL', $pid;
    waitpid $pid, 0;
  }
};

done_testing;
