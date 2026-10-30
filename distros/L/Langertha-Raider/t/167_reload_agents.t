#!/usr/bin/env perl
# ABSTRACT: /reload reads the agent files again: the context's catalogue and the agent tool's text (ADR 0020, k153)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::Context;
use Langertha::Raider::CLI;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS CLAUDE_CONFIG_DIR )};

sub project { path(tempdir(CLEANUP => 1))->realpath }
sub put { my ( $base, $rel, $text ) = @_; $base->child($rel)->touchpath->spew_utf8($text) }
sub agent { "---\ndescription: $_[0] agent.\n---\nbody of $_[0]\n" }

sub agent_text {
  my ( $app ) = @_;
  my ($tool) = grep { $_->name eq 'agent' } map { @{ $_->tools } } @{ $app->_tool_servers };
  return $tool ? $tool->description : '';
}

subtest 'Context::reload: the agent catalogue and the skill resolver are read again' => sub {
  my $p = project();
  put($p, '.raider/agents/alpha.md', agent('alpha'));
  my $c = Langertha::Raider::Context->new(root => "$p");
  is([ map { $_->{name} } $c->agent_catalog->agents ], [qw( alpha general-purpose Explore Plan )], 'alpha');
  ok(!$c->skill_resolver->resolve('notes'), 'no skill yet');

  put($p, '.raider/agents/beta.md', agent('beta'));
  put($p, '.raider/skills/notes/SKILL.md', "---\ndescription: Notes.\n---\nN\n");
  is([ map { $_->{name} } $c->agent_catalog->agents ], [qw( alpha general-purpose Explore Plan )], 'cached until reload');
  $c->reload;
  is([ map { $_->{name} } $c->agent_catalog->agents ], [qw( alpha beta general-purpose Explore Plan )], 'agents read again');
  ok($c->skill_resolver->resolve('notes'), 'the resolver sees the new skill catalogue');
};

subtest 'reload_context + reload_mission: the agent tool lists the new agents' => sub {
  my $p = project();
  put($p, '.raider/agents/alpha.md', agent('alpha'));
  my $app = Langertha::Raider::CLI->new(root => "$p", engine => 'openai', api_key => 'x', trace => 0);
  $app->mission;
  like(agent_text($app), qr/- alpha: alpha agent\./, 'alpha listed');
  unlike(agent_text($app), qr/- beta:/, 'beta not yet');

  put($p, '.raider/agents/beta.md', agent('beta'));
  $app->reload_context;
  $app->reload_mission;
  like(agent_text($app), qr/- beta: beta agent\./, 'beta listed after /reload');
};

done_testing;
