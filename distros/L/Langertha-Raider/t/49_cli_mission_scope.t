#!/usr/bin/env perl
# ABSTRACT: -M replaces the instructions only; --bare isolates (ADR 0014)

use strict;
use warnings;
use Test2::V0;
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Skill;

clear_engine_env();

# A Perl workspace (detects the perl pack) with .raider.md and a skill.
sub workspace {
  my $root = path(tempdir(CLEANUP => 1));
  $root->child('cpanfile')->spew_utf8("requires 'Moose';\n");
  $root->child('.raider.md')->spew_utf8("Custom persona.\n");
  $root->child('skills')->mkpath;
  $root->child('skills', 'house.md')->spew_utf8("House skill body.\n");
  return "$root";
}

sub app {
  my ( %args ) = @_;
  return Langertha::Raider::CLI->new(
    root              => workspace(),
    engine            => 'openai',
    api_key           => 'test',
    trace             => 0,
    cli_skill_sources => [ { type => 'dir', path => 'skills' } ],
    %args,
  );
}

sub commands {
  my ( $app ) = @_;
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  my $cmds = Langertha::Raider::CLI::Commands->new(
    app    => $app,
    output => Langertha::Raider::CLI::Output->new(out => $fh, color => 0),
  );
  my $read = sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t };
  return ( $cmds, $read );
}

my $PERSONA = qr/You are Langertha, viking shield-maiden/;
my $TOOLS   = qr/^Tools \(MCP\):$/m;

subtest 'default: persona, .raider.md, tools, skills, packs' => sub {
  my $app = app();
  my $m = $app->mission;
  like($m, $PERSONA, 'default persona');
  like($m, qr/Custom persona/, '.raider.md');
  like($m, $TOOLS, 'tool description');
  like($m, qr/House skill body/, 'skill');
  like($m, qr/### Pack: perl/, 'detected pack');
  like($m, qr/### Pack: caveman/, 'default pack');
  is($app->mission_source, '.raider.md', 'instructions from .raider.md');
};

subtest 'tool description is its own item after the instructions' => sub {
  my $app = app();
  my $m = $app->mission;
  my $custom = index($m, 'Custom persona');
  my $tools  = index($m, 'Tools (MCP):');
  ok($custom > 0 && $tools > $custom, 'tools follow the instructions item');
  like($m, qr/^Working directory: \Q${\ $app->root }\E$/m, 'working directory with the tools');
};

subtest '-M replaces only persona and .raider.md' => sub {
  my $app = app(mission => 'You are the flag mission.');
  my $m = $app->mission;
  like($m, qr/\AYou are the flag mission\./, '-M text leads');
  unlike($m, $PERSONA, 'no default persona');
  unlike($m, qr/Custom persona/, 'no .raider.md');
  like($m, $TOOLS, 'tool description kept');
  like($m, qr/House skill body/, 'skill kept');
  like($m, qr/### Pack: perl/, 'detected pack kept');
  like($m, qr/### Pack: caveman/, 'default pack kept');
  is($app->mission_source, '-M', 'instructions from -M');
  ok(!$app->bare, 'not bare');
};

subtest '-M: /pack, /reload and detection work as without -M' => sub {
  my $app = app(mission => 'You are the flag mission.');
  my ( $cmds, $read ) = commands($app);
  $app->raider;
  $cmds->dispatch('/pack on polite');
  like($app->raider->mission, qr/### Pack: polite/, '/pack on reaches the mission');
  like($app->raider->mission, qr/\AYou are the flag mission\./, '-M kept');
  $cmds->dispatch('/pack off polite');
  unlike($app->raider->mission, qr/### Pack: polite/, '/pack off reaches the mission');

  path($app->root)->child('cpanfile')->remove;
  $cmds->dispatch('/reload');
  unlike($app->raider->mission, qr/### Pack: perl/, 'redetection drops perl');
  path($app->root)->child('cpanfile')->spew_utf8("requires 'Moose';\n");
  $cmds->dispatch('/reload');
  like($read->(), qr/^detected packs: perl$/m, 'redetected');
  like($app->raider->mission, qr/### Pack: perl/, 'perl back in the mission');
  like($app->raider->mission, qr/\AYou are the flag mission\./, '-M still kept');
};

subtest '--bare: default persona and tools, nothing else' => sub {
  my $app = app(bare => 1);
  my $m = $app->mission;
  like($m, $PERSONA, 'default persona');
  like($m, $TOOLS, 'tool description');
  unlike($m, qr/Custom persona/, 'no .raider.md');
  unlike($m, qr/House skill body/, 'no skills');
  unlike($m, qr/### Pack:/, 'no packs');
  is($app->packs->active_pack_names, [], 'no pack active');
  is($app->packs->detections, {}, 'no detection ran');
  is([ $app->detection_state ], [ 0, '--bare' ], 'detection off by --bare');
  is([ $app->loaded_skill_names ], [], 'no skill names');
  is($app->mission_source, 'default', 'instructions default');
  ok(!$app->perl_tools_enabled, 'no pack requests the perl tools');
};

subtest '-M TEXT --bare is TEXT plus the tool description' => sub {
  my $app = app(mission => 'You are the flag mission.', bare => 1);
  my $m = $app->mission;
  like($m, qr/\AYou are the flag mission\.\n\n---\nWorking directory: /, '-M text, then the tools');
  like($m, $TOOLS, 'tool description kept');
  unlike($m, $PERSONA, 'no default persona');
  unlike($m, qr/Custom persona|House skill body|### Pack:/, 'nothing else');
  is($app->reload_mission, $m, 'same after reload');
};

subtest '--bare: /pack NAME still switches a pack on' => sub {
  my $app = app(bare => 1);
  my ( $cmds, $read ) = commands($app);
  $app->raider;
  $cmds->dispatch('/pack polite');
  is($read->(), "pack polite enabled.\n", 'toggled on');
  like($app->raider->mission, qr/### Pack: polite/, 'pack text in the mission');
  $cmds->dispatch('/reload');
  like($app->raider->mission, qr/### Pack: polite/, 'survives /reload');
  unlike($app->raider->mission, qr/### Pack: perl/, '/reload detects nothing');
  unlike($app->raider->mission, qr/Custom persona/, 'still no .raider.md');

  my $flag = app(bare => 1, mission => 'Flag.');
  my ( $fcmds ) = commands($flag);
  $flag->raider;
  $fcmds->dispatch('/pack on polite');
  like($flag->raider->mission, qr/\AFlag\.\n.*Tools \(MCP\):.*### Pack: polite/s, 'with -M too');
};

subtest '--bare: --pack is honoured, packs: from .raider.yml is not' => sub {
  my $app = app(bare => 1, pack_names => ['polite']);
  is($app->packs->active_pack_names, ['polite'], '--pack switches polite on');
  like($app->mission, qr/### Pack: polite/, 'pack text in the mission');
  unlike($app->mission, qr/### Pack: (?:perl|caveman)/, 'no detected or default pack');
  my $report = $app->explain_config;
  is([ map { $_->{name} } @{ $report->{packs} } ], ['polite'], 'explain lists only polite');
  is($report->{detection}, q{off (--bare)}, q{explain names --bare});

  my $cfg = app(bare => 1);
  path($cfg->root)->child('.raider.yml')->spew_utf8("packs: [polite]\n");
  is($cfg->packs->active_pack_names, [], 'packs: in .raider.yml ignored');
};

subtest '--bare: perl tools only by --perl or --pack perl' => sub {
  ok(!app(bare => 1)->perl_tools_enabled, 'detected perl pack does not count');
  ok(app(bare => 1, pack_names => ['perl'])->perl_tools_enabled, '--pack perl');
  ok(app(bare => 1, perl => 1)->perl_tools_enabled, '--perl');
};

subtest 'config explain names the instructions source and bare' => sub {
  like(app()->explain_config, { instructions => '.raider.md', bare => 0 }, '.raider.md');
  like(app(mission => 'X')->explain_config, { instructions => '-M', bare => 0 }, '-M');
  like(app(bare => 1)->explain_config, { instructions => 'default', bare => 1 }, 'bare default');
  like(app(bare => 1, mission => 'X')->explain_config, { instructions => '-M', bare => 1 }, 'bare -M');

  my ( $cmds, $read ) = commands(app(mission => 'X', bare => 1));
  $cmds->dispatch('/config');
  like($read->(), qr/^instructions: -M \(bare\)$/m, '/config prints it');
  ( $cmds, $read ) = commands(app());
  $cmds->dispatch('/config');
  like($read->(), qr/^instructions: \.raider\.md$/m, '/config without bare');
};

subtest 'banner and skill export mention bare' => sub {
  my $persona = sub { $_[0] =~ /^- Persona: (.*)$/m ? $1 : undef };
  is($persona->(Langertha::Raider::Skill->new(app => app(bare => 1))->markdown),
    'Langertha (default viking persona), bare (no .raider.md or skills, only explicit packs)', 'bare default');
  is($persona->(Langertha::Raider::Skill->new(app => app(mission => 'X'))->markdown),
    'from -M (.raider.md not used)', '-M');
};

subtest 'raider --bare on the command line' => sub {
  my $main = Langertha::Raider::CLI::Main->new;
  my ( $opt ) = $main->parse_options(qw( --bare -M X ));
  ok($opt->{bare}, '--bare parsed');
  my %args = $main->app_args($opt);
  is($args{bare}, 1, 'passed to the app');
  like($main->usage, qr/^\s+--bare\s/m, 'in --help');
};

done_testing;
