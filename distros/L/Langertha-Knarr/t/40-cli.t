use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

# Test that CLI modules load
for my $mod (qw(
  Langertha::Knarr::CLI
  Langertha::Knarr::CLI::Cmd::Start
  Langertha::Knarr::CLI::Cmd::Models
  Langertha::Knarr::CLI::Cmd::Check
  Langertha::Knarr::CLI::Cmd::Init
)) {
  ok(eval "require $mod; 1", "load $mod") or diag $@;
}

# Test MooX::Cmd::Tester if available
my $has_tester = eval { require MooX::Cmd::Tester; 1 };

SKIP: {
  skip 'MooX::Cmd::Tester not available', 3 unless $has_tester;

  # Test: main help output
  my $rv = MooX::Cmd::Tester::test_cmd('Langertha::Knarr::CLI' => []);
  like $rv->stdout, qr/KNARR/, 'banner shown';
  like $rv->stdout, qr/COMMANDS/, 'commands listed';
  like $rv->stdout, qr/start/, 'start command mentioned';
}

SKIP: {
  skip 'MooX::Cmd::Tester not available', 2 unless $has_tester;

  # Test: init command (generates config from env)
  local $ENV{LANGERTHA_OPENAI_API_KEY} = 'test-key-for-init';
  my $rv = MooX::Cmd::Tester::test_cmd('Langertha::Knarr::CLI' => ['init']);
  like $rv->stdout, qr/engine: OpenAI/, 'init found OpenAI from env';
  like $rv->stdout, qr/listen:/, 'init outputs listen';
}

SKIP: {
  skip 'MooX::Cmd::Tester not available', 2 unless $has_tester;

  # Test: check command with valid config
  my ($fh, $file) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
  print $fh "models:\n  test:\n    engine: OpenAI\n";
  close $fh;

  my $rv = MooX::Cmd::Tester::test_cmd('Langertha::Knarr::CLI' => ['--config', $file, 'check']);
  like $rv->stdout, qr/Configuration OK/, 'check passes';
  like $rv->stdout, qr/Models: 1/, 'model count shown';
}

done_testing;
