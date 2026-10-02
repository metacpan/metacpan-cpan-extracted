use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();

# Regression: bin/raider must read the agent profile table from
# $Langertha::Raider::CLI::AGENT_PROFILES (formerly $App::Raider::...).
# Looking it up in the engine package crashed --claude/--openai/--codex with
# "Can't use an undefined value as an ARRAY reference".

clear_engine_env();

my $repo = path(__FILE__)->absolute->parent->parent;
my $bin  = $repo->child('bin', 'raider');

for my $flag (qw( --claude --openai --codex )) {
  my $dir = tempdir(CLEANUP => 1);
  my $out = path($dir)->child('SKILL.md');
  my @cmd = ($^X, '-I' . $repo->child('lib'), $bin,
    '-e', 'openai', '-k', 'test', '-r', $dir, $flag,
    "--export-skill=$out");
  my $stderr = `@{[ join ' ', map { "'$_'" } @cmd ]} 2>&1 </dev/null`;
  is($?, 0, "raider $flag exits cleanly") or diag $stderr;
  unlike($stderr, qr/undefined value as an ARRAY reference/, "raider $flag finds AGENT_PROFILES");
  ok(-f $out, "raider $flag reached skill export");
}

done_testing;
