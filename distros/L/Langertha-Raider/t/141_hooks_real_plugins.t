#!/usr/bin/env perl
# ABSTRACT: The hook runner against the real briefing, loadguard and skilletor plugins (k155)
use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use File::Which qw( which );
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Context::Plugins;
use Langertha::Raider::Context::Settings;
use Langertha::Raider::Hooks;

# Each plugin is "installed" from its checkout into a temp ~/.claude
# (installed_plugins.json + enabledPlugins), so its own hooks/hooks.json,
# ${CLAUDE_PLUGIN_ROOT} and ${CLAUDE_PLUGIN_DATA} are used as Claude Code
# uses them. Checkouts default to ~/dev/<name>; override with
# RAIDER_TEST_BRIEFING_DIR, RAIDER_TEST_LOADGUARD_DIR, RAIDER_TEST_SKILLETOR_DIR.
# A plugin, or the interpreter its script needs, that is missing skips.

my $real_home = ( getpwuid($<) )[7];
my %dir = (
  briefing  => $ENV{RAIDER_TEST_BRIEFING_DIR}  // "$real_home/dev/briefing",
  loadguard => $ENV{RAIDER_TEST_LOADGUARD_DIR} // "$real_home/dev/loadguard",
  skilletor => $ENV{RAIDER_TEST_SKILLETOR_DIR} // "$real_home/dev/skilletor",
);

my $home = path(tempdir(CLEANUP => 1));
local $ENV{HOME} = "$home";
local $ENV{CLAUDE_CONFIG_DIR} = '';
my $claude = $home->child('.claude');

my $loop = IO::Async::Loop->new;
my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $T = JSON::MaybeXS->true;

sub spew_json { my ( $file, $data ) = @_; path($file)->parent->mkpath; path($file)->spew_raw($json->encode($data)) }

# A runner for $proj with only plugin $name installed and enabled.
sub runner_for {
  my ( $name, $proj, %args ) = @_;
  my $key = $name.'@getty';
  spew_json( $claude->child('plugins/installed_plugins.json'), { version => 2, plugins => {
    $key => [ { scope => 'user', installPath => $dir{$name}, version => 'dev' } ],
  } } );
  spew_json( $claude->child('settings.json'), { enabledPlugins => { $key => $T } } );
  my $settings = Langertha::Raider::Context::Settings->new( project_dir => "$proj" );
  my $plugins = Langertha::Raider::Context::Plugins->new( cwd => "$proj", enabled => $settings->enabled_plugin_map );
  return Langertha::Raider::Hooks->new( loop => $loop, root => "$proj", settings => $settings, plugins => $plugins, %args );
}

subtest 'briefing: PreToolUse on Agent puts the declared skills in front of the prompt' => sub {
  my $script = path($dir{briefing})->child('hooks/briefing-preload');
  skip_all 'no briefing checkout at '.$dir{briefing} unless -x $script && -f path($dir{briefing})->child('hooks/hooks.json');
  skip_all 'no python3 on PATH' unless which('python3');

  my $proj = path(tempdir(CLEANUP => 1));
  $proj->child('.claude/agents')->mkpath;
  $proj->child('.claude/agents/reviewer.md')->spew_utf8(
    "---\nname: reviewer\ndescription: Reviews code\nbriefing:\n  skills:\n    - house-style\n---\nYou review code.\n");
  $proj->child('.claude/skills/house-style')->mkpath;
  $proj->child('.claude/skills/house-style/SKILL.md')->spew_utf8(
    "---\nname: house-style\ndescription: The house style\n---\nTwo spaces, never tabs.\n");

  my $call = { session_id => 's', tool_name => 'agent', tool_input => { description => 'review', prompt => 'Review lib/A.pm', subagent_type => 'reviewer' } };
  my $r = runner_for( briefing => $proj )->run( PreToolUse => $call );
  is( $r->errors, [], 'no errors' ) or diag $json->encode($r->runs);
  is( $r->decision, undef, 'no decision' );
  my $prompt = $r->updated_input ? $r->updated_input->{prompt} : '';
  like( $prompt, qr/\A# Briefing — pre-loaded skills/, 'the briefing header comes first' );
  like( $prompt, qr{<skill name="house-style" dir="\Q$proj\E/\.claude/skills/house-style">\nTwo spaces, never tabs\.\n</skill>}, 'the skill body' );
  like( $prompt, qr/# Original task\n\nReview lib\/A\.pm\z/, 'the task last' );
  is( $r->updated_input->{subagent_type}, 'reviewer', 'the rest of the input is kept' );
  like( $r->system_messages->[0] // '', qr/\Abriefing: reviewer ← house-style/, 'the audit line as systemMessage' );

  $proj->child('.claude/skills/house-style/SKILL.md')->remove;
  $r = runner_for( briefing => $proj )->run( PreToolUse => $call );
  is( $r->decision, 'deny', 'an unknown skill denies the spawn' );
  like( $r->reason, qr/references unknown skill\(s\): house-style/, '... naming it' );

  $r = runner_for( briefing => $proj, native_briefing => 1 )->run( PreToolUse => $call );
  is( [ $r->decision, $r->updated_input, $r->runs->[0]{outcome} ], [ undef, undef, 'skipped' ], 'native briefing: the hook is skipped' );
};

subtest 'loadguard: PreToolUse on Bash denies a heavy command under pressure' => sub {
  my $starter = path($dir{loadguard})->child('hooks/loadguard');
  skip_all 'no loadguard checkout at '.$dir{loadguard} unless -x $starter && -f path($dir{loadguard})->child('hooks/hooks.json');
  my ( $binary ) = grep { -x } path($dir{loadguard})->child('build/bin/loadguard-hook'),
    path($real_home)->child('.claude/plugins/data/loadguard-getty/bin/loadguard-hook');
  skip_all 'no built loadguard-hook (make in the checkout)' unless $binary;

  # The deny needs memory pressure or swap in use; the thresholds go down to
  # 1 %, so any swap use is enough. No load is created.
  my ( $total, $free ) = map { /(\d+)/ ? $1 : 0 } grep { /\ASwap(?:Total|Free):/ } path('/proc/meminfo')->lines;
  my $swap = $total ? 100 * ( $total - $free ) / $total : 0;
  my ( $psi ) = eval { path('/proc/pressure/memory')->slurp } =~ /full avg10=([\d.]+)/;
  skip_all sprintf('the host has neither swap in use (%.1f %%) nor memory pressure; a deny cannot be forced without load', $swap)
    unless $swap >= 1 || ( $psi // 0 ) >= 1;
  local $ENV{LOADGUARD_PSI_FULL}  = 1;
  local $ENV{LOADGUARD_SWAP_USED} = 1;

  my $data = $claude->child('plugins/data/loadguard-getty/bin');
  $data->mkpath;
  symlink "$binary", $data->child('loadguard-hook') or die "symlink: $!";

  my $proj = path(tempdir(CLEANUP => 1));
  my $h = runner_for( loadguard => $proj );
  my $r = $h->run( PreToolUse => { session_id => 's', tool_name => 'bash', tool_input => { command => 'prove -lr t' } } );
  is( $r->errors, [], 'no errors' ) or diag $json->encode($r->runs);
  is( $r->decision, 'deny', 'prove is refused' );
  like( $r->reason, qr/\Aloadguard: heavy command refused \(prove\)/, 'with loadguard\'s reason' );
  is( $r->runs->[0]{argv}[1], $claude->child('plugins/data/loadguard-getty')->stringify, '${CLAUDE_PLUGIN_DATA} as the argument' );

  $r = $h->run( PreToolUse => { session_id => 's', tool_name => 'bash', tool_input => { command => 'ls' } } );
  is( [ $r->decision, $r->errors ], [ undef, [] ], 'a light command passes' );

  $r = $h->run( PreToolUse => { session_id => 's', tool_name => 'read_file', tool_input => { path => 'x' } } );
  is( $r->runs, [], 'Read does not match the Bash matcher' );
};

subtest 'skilletor: SessionStart reports a broken skilletor.json as systemMessage' => sub {
  my $bin = path($dir{skilletor})->child('bin/skilletor');
  skip_all 'no skilletor checkout at '.$dir{skilletor} unless -x $bin && -f path($dir{skilletor})->child('dist/skilletor.js');
  skip_all 'no node on PATH' unless which('node');

  my $proj = path(tempdir(CLEANUP => 1));
  $proj->child('.claude')->mkpath;
  $proj->child('.claude/skilletor.json')->spew_raw('{broken');
  my $h = runner_for( skilletor => $proj );
  my $r = $h->run( SessionStart => { session_id => 's', source => 'startup' } );
  is( $r->errors, [], 'no errors' ) or diag $json->encode($r->runs);
  like( $r->system_messages->[0] // '', qr/\Askilletor: \Q$proj\E\/\.claude\/skilletor\.json: invalid JSON/, 'the systemMessage' );
  is( $h->run( SessionStart => { session_id => 's', source => 'compact' } )->runs, [], 'its matcher startup|resume: not on compact' );
};

done_testing;
