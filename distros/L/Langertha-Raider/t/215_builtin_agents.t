#!/usr/bin/env perl
# ABSTRACT: Built-in Explore and Plan: catalogue, read-only tool set, mission without memory; nesting depth default 3 (ADR 0027 §6, §8, k161)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use Path::Tiny;
use Test::Raider::MockAI qw( mock_app );
use Langertha::Raider::Context::Agents;
use Langertha::Raider::Subagent;

delete @ENV{qw( ANTHROPIC_API_KEY OPENAI_API_KEY RAIDER_HALL_SOCKET RAIDER_PACK_DIRS
  CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH )};

sub root { path( tempdir( CLEANUP => 1 ) )->realpath }

sub names { [ map { $_->name } map { @{ $_->tools } } @{ $_[0] } ] }

sub child {
  my ( $app, $name, %o ) = @_;
  return Langertha::Raider::Subagent->new(
    app             => $app,
    agent           => $app->context->agent_catalog->find($name),
    depth           => $o{depth} // 1,
    prompt          => 'look around',
    caller_servers  => $app->_tool_servers,
    on_caller_event => sub { },
  );
}

# A Claude project: CLAUDE.md makes the layout, the memory item is what a
# memory-less agent must not see.
sub claude_project {
  my $root = root();
  $root->child('CLAUDE.md')->spew_utf8("PROJECT-MEMORY-MARKER: be nice.\n");
  return $root;
}

my @read_only = qw( agent send_message write_file edit_file multi_edit exit_plan_mode );

subtest 'catalogue: Explore and Plan beside general-purpose' => sub {
  my $c = Langertha::Raider::Context::Agents->new( roots => [] );
  is( [ map { $_->{name} } $c->agents ], [qw( general-purpose Explore Plan )], 'the built-ins, general-purpose first' );
  like( $c->find('general-purpose'), { builtin => 1, one_shot => 0, memory => 1, disallowed => [] },
    'general-purpose keeps memory and every tool' );
  for my $name (qw( Explore Plan )) {
    like( $c->find($name), {
      name => $name, source => 'built-in', file => undef, builtin => 1, one_shot => 1, memory => 0,
      tools => undef, model => undef, skills => [], disallowed => \@read_only,
    }, $name.': built-in, one-shot, without memory, read-only' );
  }
  like( $c->find('Explore')->{description},
    qr/\ARead-only search agent for broad fan-out searches \x{2014} when answering .*"quick" for targeted lookups, "medium" for moderate exploration, "very thorough" for multiple locations and naming conventions\.\z/,
    'Explore: Claude Code\'s description, with the thoroughness levels' );
  like( $c->find('Plan')->{description},
    qr/\ASoftware architect agent for designing implementation plans\. .*considers architectural trade-offs\.\z/,
    'Plan: Claude Code\'s description' );
  like( $c->find('Explore')->{body}, qr/\AYou are a file search specialist/, 'Explore body' );
  like( $c->find('Explore')->{body}, qr/READ-ONLY MODE.*including \/tmp.*heredocs.*bash ONLY for read-only.*absolute paths.*parallel/s,
    'Explore: read-only rules, absolute paths, parallel searches' );
  like( $c->find('Plan')->{body}, qr/\AYou are a software architect and planning specialist/, 'Plan body' );
  like( $c->find('Plan')->{body}, qr/READ-ONLY MODE.*### Critical Files for Implementation\n.*REMEMBER: You can ONLY explore and plan/s,
    'Plan: read-only, ends with the critical files' );

  my $file = Langertha::Raider::Context::Agents->new( roots => [] )->report( engine_class => undef );
  like( [ map { $_->{name} } @{ $file->{agents} } ], [qw( general-purpose Explore Plan )], 'the report lists them' );
  my ( $explore ) = grep { $_->{name} eq 'Explore' } @{ $file->{agents} };
  is( $explore->{disallowed}, \@read_only, 'with their disallowed tools' );
  ok( JSON::MaybeXS->new( canonical => 1, utf8 => 1 )->encode($file), 'JSON-safe' );
};

subtest 'a file agent named Explore shadows the built-in' => sub {
  my $dir = root();
  $dir->child('Explore.md')->spew_utf8("---\nname: Explore\ndescription: My explorer.\n---\nMINE\n");
  my $c = Langertha::Raider::Context::Agents->new( roots => [ { dir => "$dir", source => '.claude/agents' } ] );
  is( [ map { $_->{name} } $c->agents ], [qw( Explore general-purpose Plan )], 'one Explore' );
  like( $c->find('Explore'), { source => '.claude/agents', body => "MINE\n", builtin => 0, one_shot => 0, memory => 1,
    disallowed => [] }, 'the file wins, with its own (default) traits' );
  is( [ $c->shadowed ], [ { name => 'Explore', source => 'built-in', file => undef, by => '.claude/agents' } ],
    'the built-in is reported as shadowed' );
};

subtest 'Explore\'s tool set: read and search, no write, no agent' => sub {
  my $app = mock_app( root => ''.claude_project() );
  my @parent = @{ names( $app->_tool_servers ) };
  ok( ( grep { $_ eq 'agent' } @parent ) && ( grep { $_ eq 'write_file' } @parent ),
    'the caller has agent and write_file' );
  for my $name (qw( Explore Plan )) {
    my $tools = names( child( $app, $name )->tool_servers );
    my %has = map { $_ => 1 } @$tools;
    ok( $has{$_}, $name.' has '.$_ ) for qw( read_file grep glob list_files bash );
    ok( !$has{$_}, $name.' has no '.$_ ) for qw( write_file edit_file agent exit_plan_mode ask_user );
  }
  my %gp = map { $_ => 1 } @{ names( child( $app, 'general-purpose' )->tool_servers ) };
  ok( $gp{write_file} && $gp{agent}, 'general-purpose keeps write_file and (below the limit) agent' );
};

subtest 'mission: Explore without memory, general-purpose with it' => sub {
  my $root = claude_project();
  $root->child('.claude/skills/notes/SKILL.md')->touchpath->spew_utf8("---\ndescription: Notes skill.\n---\nbody\n");
  my $app = mock_app( root => "$root" );
  ok( $app->context->claude_layout, 'a Claude project' );
  like( $app->mission, qr/PROJECT-MEMORY-MARKER/, 'the main mission has the memory' );

  my $gp = child( $app, 'general-purpose' )->mission;
  like( $gp, qr/PROJECT-MEMORY-MARKER/, 'general-purpose: CLAUDE.md in its mission' );

  for my $name (qw( Explore Plan )) {
    my $mission = child( $app, $name )->mission;
    unlike( $mission, qr/PROJECT-MEMORY-MARKER/, $name.': no CLAUDE.md' );
    unlike( $mission, qr/Codebase and user instructions are shown below/, $name.': no memory header' );
    like( $mission, qr/\AYou are a/, $name.': the body first' );
    like( $mission, qr/^  - read_file\(/m, $name.': its tools' );
    unlike( $mission, qr/^  - write_file\(/m, $name.': not the denied ones' );
    like( $mission, qr/- notes: Notes skill\./, $name.': the skill listing, its set has skill' );
  }
};

subtest 'compile_mission memory => 0 keeps no AGENTS.md and no listing without skill' => sub {
  my $root = root();
  $root->child('AGENTS.md')->spew_utf8("AGENTS-MARKER\n");
  $root->child('.raider.yml')->spew_utf8("skills:\n  - openai\n");
  $root->child('.raider/skills/notes/SKILL.md')->touchpath->spew_utf8("---\ndescription: Notes skill.\n---\nbody\n");
  my $app = mock_app( root => "$root" );
  my @servers = grep { !grep { $_->name eq 'skill' } @{ $_->tools } } @{ $app->_tool_servers };
  my $with = $app->compile_mission( 'BODY', $app->_tool_servers );
  my $without = $app->compile_mission( 'BODY', $app->_tool_servers, memory => 0 );
  like( $with, qr/AGENTS-MARKER/, 'with memory: AGENTS.md' );
  like( $without, qr/\ABODY\n\n---\n/, 'the body first' );
  like( $without, qr/- notes: Notes skill\./, 'skill listing with the skill tool' );
  unlike( $without, qr/AGENTS-MARKER/, 'no AGENTS.md' );
  like( $with, qr/^Active packs:/m, 'with memory: the active packs' );
  unlike( $without, qr/Active packs:/, 'no packs' );
  unlike( $app->compile_mission( 'BODY', \@servers, memory => 0 ), qr/- notes: Notes skill\./,
    'no skill tool: no listing' );
  is( $app->compile_mission( 'BODY', $app->_tool_servers, memory => 1 ), $with, 'memory => 1 is the default' );
};

subtest 'an Explore call runs with the memory-less mission' => sub {
  my $app = mock_app(
    root   => ''.claude_project(),
    script => [
      { tool_calls => [ [ agent => { description => 'Find', prompt => 'Find the config.', subagent_type => 'Explore' } ] ] },
      { text => 'found it in /x/config.yml' },
      { text => 'done' },
    ],
  );
  my $outcome = $app->run_prompt('go');
  is( $outcome->{status}, 'completed', 'the run completes' );
  my $json = JSON::MaybeXS->new( canonical => 1, allow_blessed => 1, convert_blessed => 1 );
  my @requests = map { $json->encode($_) } @{ $app->mock_engine->requests };
  is( scalar @requests, 3, 'three model requests' );
  like( $requests[0], qr/PROJECT-MEMORY-MARKER/, 'the main request has the memory' );
  like( $requests[1], qr/file search specialist/, 'the child request is Explore\'s' );
  unlike( $requests[1], qr/PROJECT-MEMORY-MARKER/, 'without the memory' );
  like( $requests[2], qr/found it in \/x\/config\.yml/, 'the report goes back to the caller' );
};

subtest 'max_agent_depth: default 3, the Claude env var, the config key first' => sub {
  my $plain = root();
  is( mock_app( root => "$plain" )->max_agent_depth, 3, 'default 3' );
  {
    local $ENV{CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH} = 1;
    is( mock_app( root => "$plain" )->max_agent_depth, 3, 'the env var outside the Claude layout: ignored' );
    my $app = mock_app( root => ''.claude_project() );
    is( $app->max_agent_depth, 1, 'in the Claude layout: from the env var' );
    my $explain = $app->explain_config;
    like( [ grep { $_->{key} eq 'max_agent_depth' } @{ $explain->{values} } ],
      [ { value => 1, source => 'env CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH', applies_to => 'raider' } ], 'config explain names the source' );

    my $cfg = claude_project();
    $cfg->child('.raider.yml')->spew_utf8("max_agent_depth: 2\n");
    is( mock_app( root => "$cfg" )->max_agent_depth, 2, 'the config key wins over the env var' );
  }
  {
    local $ENV{CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH} = 0;
    my $app = mock_app( root => ''.claude_project() );
    is( $app->max_agent_depth, 3, 'env 0: not a positive integer, default' );
    like( [ grep { $_->{key} =~ /SPAWN_DEPTH/ } @{ $app->explain_config->{ignored} } ],
      [ { key => 'env CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH', reason => 'not a positive integer' } ], 'and listed as ignored' );
  }
  {
    local $ENV{CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH} = 'deep';
    is( mock_app( root => ''.claude_project() )->max_agent_depth, 3, 'env not a number: default' );
  }

  my $set = root();
  $set->child('.claude/settings.json')->touchpath->spew_utf8('{ "env": { "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "2" } }');
  $set->child('CLAUDE.md')->spew_utf8("x\n");
  my $app = mock_app( root => "$set" );
  is( $app->max_agent_depth, 2, 'from the Claude settings env' );
  delete $ENV{CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH};

  my $default = mock_app( root => "$plain" );
  like( [ grep { $_->{key} eq 'max_agent_depth' } @{ $default->explain_config->{values} } ],
    [ { value => 3, source => 'default', applies_to => 'raider' } ], 'config explain: the default' );

  my $deep = mock_app( root => ''.claude_project() );
  my $sub = child( $deep, 'general-purpose', depth => 1 );
  ok( ( grep { $_ eq 'agent' } @{ names( $sub->tool_servers ) } ), 'depth 3: a subagent at depth 1 has agent' );
  ok( !( grep { $_ eq 'agent' } @{ names( child( $deep, 'general-purpose', depth => 3 )->tool_servers ) } ),
    'at depth 3: no agent' );
};

done_testing;
