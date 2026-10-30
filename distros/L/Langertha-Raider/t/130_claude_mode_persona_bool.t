#!/usr/bin/env perl
# ABSTRACT: Claude mode follow-ups (k157): no persona and no default packs; one boolean parser for -o claude/perl/detect
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::CLI;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY DEEPSEEK_API_KEY
  GROQ_API_KEY MISTRAL_API_KEY GEMINI_API_KEY )};

sub project {
  my (%files) = @_;
  my $root = path(tempdir(CLEANUP => 1))->realpath;
  $root->child($_)->touchpath->spew_utf8($files{$_}) for keys %files;
  return $root;
}

sub app {
  my ( $root, %args ) = @_;
  return Langertha::Raider::CLI->new(
    root => "$root", engine => 'openai', api_key => 'test', model => 'gpt-4o-mini', %args,
  );
}

subtest 'Claude mode: neutral base text, no persona, no default packs' => sub {
  my $app = app(project('CLAUDE.md' => "Project rule.\n"));
  ok($app->claude_persona_off, 'persona off');
  my $m = $app->mission;
  like($m, qr/\AYou are an interactive agent/, 'neutral base first');
  unlike($m, qr/Langertha|shield-maiden|Caveman|Active packs/i, 'no persona, no caveman');
  like($m, qr/Project rule\./, 'CLAUDE.md memory');
  is($app->mission_source, 'claude base', 'mission_source');
  is($app->packs->enabled_pack_names, [], 'no default pack');

  my $explain = $app->explain_config;
  is($explain->{instructions}, 'claude base', 'config explain names the instructions source');
  my ($caveman) = grep { $_->{name} eq 'caveman' } @{ $explain->{packs} };
  like($caveman, { active => 0, source => 'layout', reason => 'Claude mode: no packs by default' },
    'config explain: caveman is off, and why');
};

subtest 'Claude mode: explicit packs and -M still apply' => sub {
  my $root = project('CLAUDE.md' => "Rule.\n");
  my $m = app($root, pack_names => ['caveman'])->mission;
  like($m, qr/Caveman Mode/, '--pack caveman works');
  like($m, qr/\AYou are an interactive agent/, 'base text stays');

  my $cfg = project('CLAUDE.md' => "Rule.\n", '.raider.yml' => "packs: [polite]\n");
  # a .raider.yml makes this a raider project: persona stays there
  ok(!app($cfg)->claude_persona_off, 'raider project: persona stays');

  is(app($root, mission => 'Mine.')->mission, match qr/\AMine\./, '-M leads');
  unlike(app($root, mission => 'Mine.')->mission, qr/interactive agent/, '-M replaces the base text');
};

subtest 'other modes keep the persona' => sub {
  my $native = app(project());
  ok(!$native->claude_persona_off, 'native: persona stays');
  like($native->mission, qr/Langertha/, 'native mission');
  is($native->mission_source, 'default', 'default');
  ok(app(project('.raider/config.yml' => "claude: true\n", 'CLAUDE.md' => "x\n"))->mission =~ /Langertha/,
    'raider project with claude: true keeps the persona');
  ok(!app(project('CLAUDE.md' => "x\n"), bare => 1)->claude_persona_off, 'bare: no Claude mode');
};

subtest 'one boolean parser for claude, perl and detect' => sub {
  my $config = app(project())->config;
  is([ map { $config->parse_bool($_) } qw( true TRUE yes on y 1 ) ], [ (1) x 6 ], 'true words');
  is([ map { $config->parse_bool($_) } qw( false False no off n 0 ), '' ], [ (0) x 7 ], 'false words');
  is($config->parse_bool(undef), undef, 'undef');
  is($config->parse_bool(JSON::MaybeXS::JSON()->false), 0, 'JSON false');
  like(dies { $config->parse_bool('maybe', 'claude') }, qr/Invalid claude: 'maybe' is not a boolean/, 'garbage croaks');

  my $raider = project('.raider/config.yml' => "claude: true\n");
  for my $off ('false', 'False', 'no', 'off', 0, '0') {
    ok(!app($raider, engine_options => { claude => $off })->context->claude_layout, "claude=$off is false");
  }
  ok(app($raider)->context->claude_layout, 'config claude: true');
  ok(app($raider, engine_options => { claude => 'true' })->context->claude_layout, 'claude=true');

  my $perl = app($raider, engine_options => { perl => 'false' });
  is($perl->perl_tools_grant->{enabled}, 0, 'perl=false is false');
  is(app($raider, engine_options => { perl => 'true' })->perl_tools_grant->{enabled}, 1, 'perl=true is true');
  my ($on) = app($raider, engine_options => { detect => 'false' })->detection_state;
  is($on, 0, 'detect=false switches detection off');

  my $yaml = project('.raider/config.yml' => "claude: \"false\"\n", 'CLAUDE.md' => "x\n");
  ok(!app($yaml)->context->claude_layout, 'claude: "false" in the config file is false too');
};

done_testing;
