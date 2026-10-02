#!/usr/bin/env perl
# ABSTRACT: The raider REPL slash commands, offline

use strict;
use warnings;
use utf8;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Skill;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY
  GROQ_API_KEY MISTRAL_API_KEY GEMINI_API_KEY )};

# A fake engine for /model: lists models, or dies.
package My::FakeEngine {
  sub new { my ( $class, %a ) = @_; bless {%a}, $class }
  sub list_models { my ( $self ) = @_; die "no network\n" if $self->{die}; $self->{models} }
}

sub app {
  my ( %args ) = @_;
  return Langertha::Raider::CLI->new(
    root    => tempdir(CLEANUP => 1),
    engine  => 'openai',
    api_key => 'test',
    model   => 'gpt-4o-mini',
    trace   => 0,
    %args,
  );
}

# Commands on $app writing into a buffer; returns the commands object and a
# reader for everything printed since the last read.
sub commands {
  my ( $app, %args ) = @_;
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  my $cmds = Langertha::Raider::CLI::Commands->new(
    app    => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0),
    %args,
  );
  my $read = sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t };
  return ( $cmds, $read );
}

subtest '/help and unknown commands' => sub {
  my ( $cmds, $read ) = commands(app());
  ok($cmds->dispatch('/help'), '/help known');
  my $help = $read->();
  like($help, qr{^  /$_\b}m, "/help lists /$_") for qw( config model pack packs reload skill skill-claude prompt quit );
  ok(!$cmds->dispatch('/frobnicate now'), 'unknown returns false');
  is($read->(), "error: unknown command: /frobnicate (try /help)\n", 'unknown reported');
};

subtest '/clear, /metrics, /stats' => sub {
  my $app = app();
  my ( $cmds, $read ) = commands($app);
  $app->raider->add_history(user => 'hello');
  $cmds->dispatch('/clear');
  is(scalar @{ $app->raider->history }, 0, 'history cleared');
  is($read->(), "history cleared.\n", '/clear message');
  $cmds->dispatch('/metrics');
  like($read->(), qr/^raids=0 iterations=0 tool_calls=0 time_ms=\d+\n\z/, '/metrics');
  $cmds->dispatch('/stats');
  like($read->(), qr/^stats unavailable \(trace is off/, '/stats without trace');
};

subtest '/reload names where the mission comes from' => sub {
  my $app = app();
  my ( $cmds, $read ) = commands($app);
  $cmds->dispatch('/reload');
  like($read->(), qr/^mission reloaded: Langertha \(default, no \.raider\.md\) \(\d+ chars\)$/, 'default');
  path($app->root)->child('.raider.md')->spew_utf8("Custom persona.\n");
  $cmds->dispatch('/reload');
  like($read->(), qr/^mission reloaded: custom \(\.raider\.md loaded\)/, '.raider.md');
  like($app->raider->mission, qr/Custom persona/, 'mission swapped');

  my $flag = app(mission => 'The -M mission.');
  path($flag->root)->child('.raider.md')->spew_utf8("Custom persona.\n");
  my ( $fcmds, $fread ) = commands($flag);
  $fcmds->dispatch('/reload');
  like($fread->(), qr/^mission reloaded: -M mission kept, \.raider\.md not used \(\d+ chars\)\n\z/, '-M');
  like($flag->raider->mission, qr/\AThe -M mission\./, '-M kept');
  unlike($flag->raider->mission, qr/Custom persona/, '.raider.md not used');
};

subtest '/config' => sub {
  my $app = app();
  my ( $cmds, $read ) = commands($app);
  $cmds->dispatch('/config');
  like($read->(), qr/^engine: openai\n.*^  model\s+gpt-4o-mini\s+\(from -m; engine\)$/ms, 'report');

  my $broken = app();
  path($broken->root)->child('.raider.yml')->spew_utf8("- a\n- b\n");
  my ( $bcmds, $bread ) = commands($broken);
  $bcmds->dispatch('/config');
  like($bread->(), qr/^error: .*\.raider\.yml/, 'broken file reported, REPL goes on');
};

subtest '/skill and /skill-claude' => sub {
  my $app = app();
  my ( $cmds, $read ) = commands($app);
  my $root = path($app->root);
  $cmds->dispatch('/skill');
  ok(-f $root->child('RAIDER-SKILL.md'), '/skill default path');
  is($read->(), 'wrote '.$root->child('RAIDER-SKILL.md')."\n", '/skill message');
  $cmds->dispatch('/skill '.$root->child('doc/x.md'));
  ok(-f $root->child('doc/x.md'), '/skill PATH');
  $read->();

  $root->child('.claude/skills/app-raider')->mkpath;
  $root->child('.claude/skills/app-raider/SKILL.md')->spew_utf8("old\n");
  $cmds->dispatch('/skill-claude');
  my $new = $root->child('.claude/skills/raider/SKILL.md');
  ok(-f $new, '/skill-claude default path');
  like($read->(), qr/^wrote \Q$new\E\nnote: .*app-raider.*remove it\n\z/, 'legacy skill pointed out');
};

subtest '/model' => sub {
  my $app = app();
  my ( $cmds, $read ) = commands($app);
  $cmds->dispatch('/model gpt-4o');
  is($read->(), "model saved: gpt-4o (takes effect on next start)\n", 'saved');
  is(YAML::PP->new->load_file($app->root.'/.raider.yml'), { default => { model => 'gpt-4o' } }, 'in .raider.yml');

  my $engine = My::FakeEngine->new(models => [qw(
    gpt-4o gpt-4o-2024-08-06 gpt-4o-2024-11-20 gpt-4o-mini o1-2024-12-17 )]);
  my ( $lcmds, $lread ) = commands(app(_engine => $engine));
  $lcmds->dispatch('/model list');
  is($lread->(), <<'OUT', 'list, snapshots folded, current marked');
engine:  openai
model:   gpt-4o-mini
models:
    gpt-4o  [+2 snapshots]
  * gpt-4o-mini
    o1  [+1 snapshot]
OUT
  $lcmds->dispatch('/model list mini');
  like($lread->(), qr{models \(/mini/\):\n  \* gpt-4o-mini\n\z}, 'filtered');

  my ( $dcmds, $dread ) = commands(app(_engine => My::FakeEngine->new(die => 1)));
  $dcmds->dispatch('/model');
  like($dread->(), qr/^error: list_models failed: no network$/m, 'list failure reported');
};

subtest '/packs and /pack' => sub {
  my $app = app();
  my ( $cmds, $read ) = commands($app);
  $app->raider;
  my @all = @{ $app->packs->all_pack_names } or skip_all 'no packs installed';
  ok((grep { $_ eq 'polite' } @all), 'polite pack bundled');

  $cmds->dispatch('/pack on polite');
  is($read->(), "pack enabled: polite\n", 'on');
  ok($app->packs->is_active('polite'), 'active');
  like($app->raider->mission, qr/Pack: polite/, 'mission reloaded with the pack');
  $cmds->dispatch('/packs');
  like($read->(), qr/^packs:\n.*^  \* polite \(/ms, '/packs marks it');
  $cmds->dispatch('/pack off polite');
  is($read->(), "pack disabled: polite\n", 'off');
  unlike($app->raider->mission, qr/Pack: polite/, 'pack text gone');
  $cmds->dispatch('/pack polite');
  is($read->(), "pack polite enabled.\n", 'toggle');
  $cmds->dispatch('/pack');
  like($read->(), qr/^error: usage: \/pack on NAME/, 'bare /pack');
  $cmds->dispatch('/pack frob polite');
  is($read->(), "error: unknown /pack subcommand: frob (try /help)\n", 'unknown subcommand');
};

subtest '/prompt' => sub {
  my $app = app();
  path($app->root)->child('.raider.md')->spew_utf8("Custom persona.\n");
  open my $in, '<', \"\n/cancel\n" or die $!;
  my ( $cmds, $read ) = commands($app, in => $in);
  $cmds->dispatch('/prompt');
  is($read->(), "entering prompt-builder. /done to return, /cancel to discard.\n"
    ."raider:prompt> raider:prompt> prompt-builder cancelled.\n", 'cancel');

  open my $done, '<', \"/done\n" or die $!;
  my ( $dcmds, $dread ) = commands($app, in => $done);
  $dcmds->dispatch('/prompt');
  like($dread->(), qr/prompt-builder finished\. mission reloaded \(\d+ chars\)\.\n\z/, 'done reloads');
  like($app->raider->mission, qr/Custom persona/, 'mission has .raider.md');
};

subtest 'every slash command is in the generated skill' => sub {
  my $md = Langertha::Raider::Skill->new(app => app())->markdown;
  my @cmds = map { s/^cmd_//r =~ tr/_/-/r } grep { /^cmd_/ }
    Langertha::Raider::CLI::Commands->meta->get_method_list;
  ok(scalar @cmds >= 12, 'commands found');
  like($md, qr{^\| `/$_\b}m, "/$_ in the slash command table") for sort @cmds;
};

subtest 'generated skill names where the persona comes from' => sub {
  my $persona = sub { $_[0] =~ /^- Persona: (.*)$/m ? $1 : undef };

  my $app = app();
  is($persona->(Langertha::Raider::Skill->new(app => $app)->markdown),
    'Langertha (default viking persona)', 'default');
  my $file = path($app->root)->child('.raider.md');
  $file->spew_utf8("Custom persona.\n");
  is($persona->(Langertha::Raider::Skill->new(app => $app)->markdown),
    'custom (loaded from '.$file.')', '.raider.md');

  my $flag = app(mission => 'The -M mission.');
  path($flag->root)->child('.raider.md')->spew_utf8("Custom persona.\n");
  is($persona->(Langertha::Raider::Skill->new(app => $flag)->markdown),
    'from -M (.raider.md not used)', '-M wins over .raider.md');
};

done_testing;
