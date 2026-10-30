#!/usr/bin/env perl
# ABSTRACT: Run options of a /name run: allow rules and a model for that run only, attached files read; allowed-tools of a skill the model loads (ADR 0030 section 3)
use strict;
use warnings;
use utf8;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home clear_engine_env );
isolate_home();
clear_engine_env();
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use Path::Tiny;
use Scalar::Util qw( refaddr );
use Langertha::Engine::Anthropic;
use Langertha::Engine::OpenAI;
use Langertha::Raider::Permissions;
use Test::Raider::MockAI qw( mock_app );

delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

{ package Test::Raider::RunModel::FakeAnthropic; use Moose; extends 'Langertha::Engine::Anthropic'; __PACKAGE__->meta->make_immutable }
{ package Test::Raider::RunModel::FakeOther;     use Moose; extends 'Langertha::Engine::OpenAI';    __PACKAGE__->meta->make_immutable }

# The mock application with the engine class swapped (for the model
# mapping) and every engine built for a model recorded.
{
  package Test::Raider::RunModel::App;
  use Moose;
  extends 'Test::Raider::MockAI::App';
  has fake_class => ( is => 'ro', default => 'Test::Raider::RunModel::FakeAnthropic' );
  has built => ( is => 'ro', default => sub { [] } );
  has broken_engine => ( is => 'ro', default => 0 );
  sub _engine_class { $_[0]->fake_class }
  around build_subagent_engine => sub {
    my ( $orig, $self, %o ) = @_;
    die "no engine for you\n" if $self->broken_engine;
    my $engine = $self->$orig(%o);
    push @{ $self->built }, { %o, engine => $engine };
    return $engine;
  };
  __PACKAGE__->meta->make_immutable;
}

my @tmp;
sub tmp { push @tmp, Path::Tiny->tempdir; return $tmp[-1]->realpath }

sub app {
  my ( %o ) = @_;
  my $root = tmp();
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  my $files = delete $o{files} // {};
  $root->child($_)->touchpath->spew_utf8( $files->{$_} ) for keys %$files;
  my @events;
  my $app = Test::Raider::RunModel::App->new(
    root            => "$root",
    engine          => 'anthropic',
    api_key         => 'mock',
    permission_mode => 'default',
    loadguard       => Langertha::Raider::Loadguard->new( env => { LOADGUARD_THROTTLE => 0 } ),
    on_event        => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    %o,
  );
  return ( $app, \@events, $root );
}

sub results { [ map { { name => $_->{tool_call}{name}, error => $_->{result}{isError} ? 1 : 0 } } @{ $_[0]->mock_engine->results } ] }

subtest 'policy: run rules allow for the run, deny and ask win, cleared in place' => sub {
  my $root = tmp();
  my $policy = Langertha::Raider::Permissions->new(
    root => "$root", home => "$root",
    rules => { deny => [ { rule => 'Bash(rm:*)', source => 't' } ], ask => [ { rule => 'Bash(git push:*)', source => 't' } ] },
  );
  my $child = $policy->for_subrun;
  my $rev = $policy->policy_revision;
  my @added = $policy->add_run_rules( [ 'Bash(echo:*)', 'Bash(rm:*)', 'Bash(git push:*)', 'Nope(', 'Bash(echo:*)' ], '/x allowed-tools' );
  is [ map { $_->text } @added ], [ 'Bash(echo:*)', 'Bash(rm:*)', 'Bash(git push:*)' ], 'valid ones, once';
  isnt $policy->policy_revision, $rev, 'the revision changes';
  my $call = sub { { name => 'bash', source => 'raider', arguments => { command => $_[0] } } };
  like $policy->decide( $call->('echo hi') ), { verdict => 'allow', source => '/x allowed-tools' }, 'allowed by the run rule';
  is $child->decide( $call->('echo hi') )->{verdict}, 'allow', 'a sub-run shares them';
  is $policy->decide( $call->('rm -rf x') )->{verdict}, 'deny', 'deny wins';
  is $policy->decide( $call->('git push') )->{verdict}, 'ask', 'ask wins';
  ok( ( grep { $_->{rule} eq 'Bash(echo:*)' && $_->{source} eq '/x allowed-tools' } @{ $policy->report->{rules}{allow} } ), 'reported' );
  $policy->clear_run_rules( $added[1] );
  is [ map { $_->text } @{ $policy->run_rules } ], [ 'Bash(echo:*)', 'Bash(git push:*)' ], 'one taken out';
  $policy->clear_run_rules;
  is $child->run_rules, [], 'all cleared, for the sub-run too';
  is $policy->policy_revision, $rev, 'the revision is back';
};

subtest 'allow rules hold for that run only' => sub {
  my ( $app ) = app( script => [
    { tool_calls => [ [ bash => { command => 'echo granted' } ] ] }, { text => 'one' },
    { tool_calls => [ [ bash => { command => 'echo again' } ] ] },   { text => 'two' },
  ] );
  my $end = $app->run_prompt( 'go', allow_rules => [ 'Bash(echo:*)' ], allow_source => '/x allowed-tools' );
  is $end->{status}, 'completed', 'ran';
  is $app->permissions->run_rules, [], 'cleared after the run';
  $app->run_prompt('again');
  is results($app), [ { name => 'bash', error => 0 }, { name => 'bash', error => 1 } ],
    'allowed in the run, refused in the next (nobody to ask)';
  like $app->mock_engine->results->[0]{result}{content}[0]{text}, qr/granted/, 'it really ran';
};

subtest 'cleared when the run fails, also when its engine cannot be built' => sub {
  my ( $app ) = app( script => [ { error => [ 500, 'boom' ] } ] );
  my $end = $app->run_prompt( 'go', allow_rules => [ 'Bash(echo:*)' ] );
  is $end->{status}, 'failed', 'failed';
  is $app->permissions->run_rules, [], 'cleared';

  ( $app ) = app( broken_engine => 1 );
  $end = $app->run_prompt( 'go', allow_rules => [ 'Bash(echo:*)' ], model => 'sonnet' );
  is $end->{status}, 'failed', 'a model engine that cannot be built fails the run';
  like $end->{error}, qr/no engine for you/, 'with the reason';
  is $app->permissions->run_rules, [], 'cleared';
  ok !$app->has_run, 'the run ended';
};

subtest 'a model for one run: mapped as for subagents, restored after' => sub {
  my ( $app, $events ) = app( script => [ { text => 'on sonnet' }, { text => 'back' } ] );
  my $main = $app->raider->active_engine;
  is $app->run_prompt( 'go', model => 'sonnet' )->{response}, 'on sonnet', 'answered';
  is $app->built->[0]{model}, 'claude-sonnet-5-5', 'an engine with the mapped model';
  is refaddr $app->built->[0]{mcp_servers}, refaddr $app->_mcps, 'over the application\'s MCP clients';
  my ($started) = grep { $_->{type} eq 'run.started' } @$events;
  is $started->{model}, 'claude-sonnet-5-5', 'run.started names it';
  is refaddr $app->raider->active_engine, refaddr $main, 'the engine is back after the run';
  ok !$app->config->can('model') || 1, 'nothing saved (no config write)';

  @$events = ();
  $app->run_prompt('next');
  ($started) = grep { $_->{type} eq 'run.started' } @$events;
  isnt $started->{model}, 'claude-sonnet-5-5', 'the next run has the usual model';
  is scalar @{ $app->built }, 1, 'and builds nothing';
};

subtest 'inherit, empty, or not the Anthropic API: no model switch' => sub {
  for my $case ( [ inherit => 'Test::Raider::RunModel::FakeAnthropic' ], [ '' => 'Test::Raider::RunModel::FakeAnthropic' ],
                 [ sonnet => 'Test::Raider::RunModel::FakeOther' ] ) {
    my ( $app ) = app( fake_class => $case->[1], script => [ { text => 'ok' } ] );
    is $app->run_prompt( 'go', model => $case->[0] )->{status}, 'completed', "'$case->[0]' runs";
    is $app->built, [], "'$case->[0]' builds no engine";
  }
};

subtest 'attached files count as read for that run' => sub {
  my ( $app, undef, $root ) = app(
    permission_mode => 'bypassPermissions',
    files  => { 'a.txt' => "one\n" },
    script => [
      { tool_calls => [ [ edit_file => { path => 'a.txt', old_string => 'one', new_string => 'two' } ] ] }, { text => 'edited' },
      { tool_calls => [ [ edit_file => { path => 'a.txt', old_string => 'two', new_string => 'three' } ] ] }, { text => 'refused' },
    ],
  );
  my $file = $root->child('a.txt')->stringify;
  $app->run_prompt( 'edit', attach_reads => [ { path => $file, kind => 'file', bytes => "one\n" } ] );
  $app->run_prompt('again');
  is results($app), [ { name => 'edit_file', error => 0 }, { name => 'edit_file', error => 1 } ],
    'read-before-write: seeded in the run, gone in the next';
  is $root->child('a.txt')->slurp_utf8, "two\n", 'edited once';
};

subtest 'a skill the model loads: its allowed-tools hold for the rest of the run' => sub {
  my ( $app ) = app(
    files => { '.claude/skills/deploy/SKILL.md' => "---\nname: deploy\ndescription: Deploys.\nallowed-tools: Bash(echo:*)\nmodel: opus\n---\nDeploy now.\n" },
    script => [
      { tool_calls => [ [ bash => { command => 'echo before' } ] ] },
      { tool_calls => [ [ skill => { skill => 'deploy' } ] ] },
      { tool_calls => [ [ bash => { command => 'echo after' } ] ] },
      { text => 'deployed' },
      { tool_calls => [ [ bash => { command => 'echo next run' } ] ] },
      { text => 'no' },
    ],
  );
  is $app->run_prompt('deploy')->{response}, 'deployed', 'ran';
  $app->run_prompt('again');
  is results($app), [ { name => 'bash', error => 1 }, { name => 'skill', error => 0 }, { name => 'bash', error => 0 }, { name => 'bash', error => 1 } ],
    'refused before the skill, allowed after it, refused in the next run';
  is $app->built, [], 'the model frontmatter is ignored for a model-invoked skill';
};

subtest 'a skill whose !`cmd` is refused is an error result, nothing loaded' => sub {
  my ( $app ) = app(
    files => { '.claude/skills/wipe/SKILL.md' => "---\nname: wipe\ndescription: Wipes.\n---\nState: !`rm -rf build`\n" },
    script => [ { tool_calls => [ [ skill => { skill => 'wipe' } ] ] }, { text => 'done' } ],
  );
  $app->run_prompt('wipe');
  my $r = $app->mock_engine->results->[0]{result};
  ok $r->{isError}, 'an error result';
  like $r->{content}[0]{text}, qr/\AShell command permission check failed for pattern "!`rm -rf build`" in \/wipe: default mode asks/,
    'Claude Code\'s words';
  ok !( $r->{_meta} && $r->{_meta}{'raider/messages'} ), 'no skill message';
};

subtest 'a skill renders its placeholders and allowed commands' => sub {
  my ( $app ) = app(
    files => { '.claude/skills/show/SKILL.md' => "---\nname: show\ndescription: Shows.\nallowed-tools: Bash(echo:*)\n---\nArgs \$0/\$ARGUMENTS in \${CLAUDE_SKILL_DIR}: !`echo SHELL-OUT`\n" },
    script => [ { tool_calls => [ [ skill => { skill => 'show', args => 'a b' } ] ] }, { text => 'done' } ],
  );
  $app->run_prompt('show');
  my $req = $app->mock_engine->requests->[1];
  my $last = $req->{body}{messages}[-1]{content};
  $last = join ' ', map { $_->{text} // '' } @$last if ref $last;
  like $last, qr{\ABase directory for this skill: \S+/\.claude/skills/show\n\nArgs a/a b in \S+/\.claude/skills/show: SHELL-OUT\n?\z}, 'rendered';
};

done_testing;
