#!/usr/bin/env perl
# ABSTRACT: Briefing: an agent's declared skills in front of its task, the resolver chain, refusal and size warning (ADR 0020 section 6, k153)
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
use Encode ();
use Path::Tiny;
use Langertha::Raider::Briefing;
use Langertha::Raider::SkillResolver;
use Langertha::Raider::Context;
use Langertha::Raider::CLI::Output;
use Test::Raider::MockAI qw( mock_app );

delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# The briefing plugin's BRIEFING_HEADER (hooks/briefing-preload) with the
# Claude Code {dont}, copied here as the oracle.
my $HEADER = "# Briefing — pre-loaded skills\n\n"
  ."The skills below have been injected directly into your context by the\n"
  ."briefing plugin, one <skill> element each. Treat them as already loaded —\n"
  ."do NOT call the Skill tool for any of these names; their content is already here. Only the SKILL.md body is\n"
  ."included: paths a skill mentions (references/, scripts/, …) are relative to\n"
  ."its element's dir, so read them from there when you need them.\n\n";

my @tmp;
sub tmp { push @tmp, Path::Tiny->tempdir; return $tmp[-1]->realpath }

# A resolver over a { name => { dir, file } } table.
{
  package Test::Raider::Briefing::Table;
  sub new { my ( $class, %t ) = @_; return bless {%t}, $class }
  sub resolve { my ( $self, $n ) = @_; return $self->{$n} ? { name => $n, %{ $self->{$n} } } : undef }
}

sub skill_dir {
  my ( $base, $name, $text ) = @_;
  my $f = $base->child( $name, 'SKILL.md' );
  $f->touchpath->spew_utf8($text);
  return { dir => $f->parent->stringify, file => $f->stringify };
}

subtest 'the format: header, one block per skill in declared order, the task' => sub {
  my $base = tmp();
  my $table = Test::Raider::Briefing::Table->new(
    alpha => skill_dir( $base, 'alpha', "---\nname: alpha\ndescription: A.\n---\n\n  Alpha body.\n\n" ),
    beta  => skill_dir( $base, 'beta', "No frontmatter here.\n" ),
    crlf  => skill_dir( $base, 'crlf', "---\r\ndescription: C.\r\n---\r\nCRLF body\r\n" ),
    open  => skill_dir( $base, 'open', "---\ndescription: never closed\nbody\n" ),
  );
  my $b = Langertha::Raider::Briefing->new( agent => 'w', skills => [qw( beta alpha crlf open )], resolver => $table );
  ok( !$b->has_missing, 'every skill resolves' );
  my $text = join "\n\n",
    '<skill name="beta" dir="'.$base.'/beta">'."\nNo frontmatter here.\n</skill>",
    '<skill name="alpha" dir="'.$base.'/alpha">'."\nAlpha body.\n</skill>",
    '<skill name="crlf" dir="'.$base.'/crlf">'."\nCRLF body\n</skill>",
    '<skill name="open" dir="'.$base.'/open">'."\n---\ndescription: never closed\nbody\n</skill>";
  is( $b->text, $text, 'blocks: declared order, frontmatter cut, body stripped; no closing --- means no frontmatter' );
  is( $b->header, $HEADER, 'the plugin\'s header, word for word' );
  is( $b->prompt('Do the task.'), $HEADER.$text."\n\n---\n\n# Original task\n\nDo the task.", 'the prompt' );
  is( [ map { $_->{name} } $b->blocks ], [qw( beta alpha crlf open )], 'blocks' );
  is( $b->size, length Encode::encode( 'UTF-8', $text ), 'size in bytes' );

  my $none = Langertha::Raider::Briefing->new( agent => 'w', resolver => $table );
  is( $none->prompt('Plain.'), 'Plain.', 'no skill declared: the task unchanged' );
  is( $none->text, '', 'no text' );
};

subtest 'unknown skills: listed, the plugin\'s note' => sub {
  my $table = Test::Raider::Briefing::Table->new( known => skill_dir( tmp(), 'known', "k\n" ) );
  my $b = Langertha::Raider::Briefing->new( agent => 'raider-worker', skills => [qw( a known b )], resolver => $table );
  ok( $b->has_missing, 'has_missing' );
  is( [ $b->missing ], [qw( a b )], 'in order' );
  is( $b->missing_note, "briefing: agent 'raider-worker' references unknown skill(s): a, b", 'the note' );
};

subtest 'the budget: 64 kB of UTF-8, the plugin\'s size note' => sub {
  my $base = tmp();
  my $shell = length '<skill name="s" dir="'.$base.'/s">'."\n\n</skill>";
  my $brief = sub {
    my ( $body ) = @_;
    my $table = Test::Raider::Briefing::Table->new( s => skill_dir( $base, 's', $body ) );
    return Langertha::Raider::Briefing->new( agent => 'big', skills => ['s'], resolver => $table );
  };
  my $at = $brief->( 'x' x ( 65536 - $shell ) );
  is( $at->size, 65536, 'exactly 64 kB' );
  ok( !$at->oversized, 'is not over' );
  my $over = $brief->( 'x' x ( 65536 - $shell - 1 ).'ä' );
  is( $over->size, 65537, 'a two-byte character counts twice' );
  ok( $over->oversized, 'one byte over' );
  my $big = $brief->( 'x' x 70000 );
  is( $big->size_note,
    "briefing: agent 'big' is briefed with ".int( $big->size / 1024 )." kB of skill text (over 64 kB) — consider declaring fewer or smaller skills.",
    'the note' );
};

subtest 'the resolver chain: first that knows the name wins' => sub {
  my $base = tmp();
  my $first  = Test::Raider::Briefing::Table->new( a => { dir => '/first/a', file => '/first/a/SKILL.md' } );
  my $second = Test::Raider::Briefing::Table->new(
    a => { dir => '/second/a', file => '/second/a/SKILL.md' },
    b => { dir => '/second/b', file => '/second/b/SKILL.md' },
  );
  my $chain = Langertha::Raider::SkillResolver->new( resolvers => [ $first, $second ] );
  is( $chain->resolve('a')->{dir}, '/first/a', 'the first resolver' );
  is( $chain->resolve('b')->{dir}, '/second/b', 'falls through' );
  is( $chain->resolve('c'), undef, 'nobody knows it' );
  is( $chain->resolve(''), undef, 'an empty name' );
  is( Langertha::Raider::SkillResolver->new->resolve('a'), undef, 'an empty chain' );
};

{
  package Test::Raider::Briefing::Context;
  use Moose;
  extends 'Langertha::Raider::Context';
  # What slice 4 does for Skilletor: one more resolver behind the catalogue.
  around skill_resolvers => sub {
    my ( $orig, $self ) = @_;
    return ( $self->$orig, Test::Raider::Briefing::Table->new( extra => { dir => '/x/extra', file => '/x/extra/SKILL.md' } ) );
  };
  __PACKAGE__->meta->make_immutable;
}

subtest 'the context\'s chain: the skill catalogue first, hidden skills too; one more resolver is one entry' => sub {
  my $root = tmp();
  $root->child('.raider/skills/shown/SKILL.md')->touchpath->spew_utf8("---\ndescription: Shown.\n---\nshown\n");
  $root->child('.raider/skills/hidden/SKILL.md')->touchpath->spew_utf8(
    "---\ndescription: Hidden.\ndisable-model-invocation: true\n---\nhidden\n");
  my $c = Langertha::Raider::Context->new( root => "$root" );
  is( $c->skill_resolver->resolve('shown'),
    { name => 'shown', dir => "$root/.raider/skills/shown", file => "$root/.raider/skills/shown/SKILL.md" }, 'a skill' );
  ok( $c->skill_resolver->resolve('hidden'), 'one that is not model-invocable' );
  is( $c->skill_resolver->resolve('nope'), undef, 'unknown' );
  my $more = Test::Raider::Briefing::Context->new( root => "$root" );
  ok( $more->skill_resolver->resolve('shown'), 'the catalogue still first' );
  is( $more->skill_resolver->resolve('extra')->{dir}, '/x/extra', 'and the added resolver after it' );
};

# A project with one agent file and its skills; the agent tool spawns it.
sub project {
  my ( %o ) = @_;
  my $root = tmp();
  $root->child('CLAUDE.md')->spew_utf8("Project.\n");
  $root->child(".claude/skills/$_/SKILL.md")->touchpath->spew_utf8( $o{skills}{$_} ) for keys %{ $o{skills} // {} };
  $root->child('.claude/agents/briefed.md')->touchpath->spew_utf8(
    "---\nname: briefed\ndescription: Briefed.\n$o{decl}---\nBRIEFED-BODY\n" );
  my @events;
  my $app = mock_app(
    root     => "$root",
    on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
    script   => [
      { tool_calls => [ [ agent => { description => 'd', prompt => 'THE-TASK', subagent_type => 'briefed' } ] ] },
      { text => 'child answer' },
      { text => 'parent answer' },
    ],
  );
  return ( $app, \@events, $root );
}

sub user_text {
  my ( $req ) = @_;
  my ($m) = grep { $_->{role} eq 'user' } @{ $req->{body}{messages} };
  my $c = $m->{content};
  my $text = ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c;
  # The situation plugin puts its line in front of every raid's first message.
  $text =~ s/\A\[situation\][^\n]*\n\n//;
  return $text;
}

subtest 'spawn: the child\'s prompt is the briefing; skills before briefing.skills' => sub {
  my ( $app, $events, $root ) = project(
    decl   => "skills: style\nbriefing:\n  skills:\n    - notes\n    - style\n",
    skills => {
      notes => "---\ndescription: Notes.\n---\nNOTES-BODY\n",
      style => "---\ndescription: Style.\ndisable-model-invocation: true\n---\nSTYLE-BODY\n",
    },
  );
  my $session = $app->create_session;
  my $outcome = $app->run_prompt( 'go', session => $session );
  is( $outcome->{response}, 'parent answer', 'the caller answers' );
  my $want = $HEADER
    .'<skill name="style" dir="'.$root.'/.claude/skills/style">'."\nSTYLE-BODY\n</skill>\n\n"
    .'<skill name="notes" dir="'.$root.'/.claude/skills/notes">'."\nNOTES-BODY\n</skill>"
    ."\n\n---\n\n# Original task\n\nTHE-TASK";
  is( user_text( $app->mock_engine->requests->[1] ), $want, 'the child\'s first request: exactly the briefed prompt' );
  like( $app->mock_engine->results->[-1]{result}{content}[0]{text}, qr/\Achild answer\nagentId: agent_1 /,
    'the caller gets the child\'s answer' );
  my ($started) = grep { $_->{type} eq 'agent.started' } @$events;
  my ($message) = grep { $_->{type} eq 'message' && $_->{role} eq 'user' }
    @{ $app->session_store->read( $started->{session} )->events };
  is( $message->{content}, $want, 'the child journal has the prompt it was given' );
  ok( !( grep { $_->{type} eq 'agent.warning' } @$events ), 'small: no warning' );
};

subtest 'an unknown skill: an error result, and nothing starts' => sub {
  my ( $app, $events ) = project(
    decl   => "briefing:\n  skills: [ notes, ghost, phantom ]\n",
    skills => { notes => "---\ndescription: Notes.\n---\nN\n" },
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'child answer', 'the caller goes on' );
  my $r = $app->mock_engine->results->[-1];
  ok( $r->{result}{isError}, 'the agent call fails' );
  is( $r->{result}{content}[0]{text}, "briefing: agent 'briefed' references unknown skill(s): ghost, phantom", 'the exact message' );
  is( scalar @{ $app->mock_engine->requests }, 2, 'no child request' );
  is( [ grep { $_->{type} =~ /\Aagent\./ } @$events ], [], 'no agent.started, no agent.finished' );
  is( [ $app->session_store->ids ], [ $session->id ], 'no child session' );
  my ($result) = grep { $_->{type} eq 'tool.result' && $_->{name} eq 'agent' } @$events;
  is( $result->{status}, 'failed', 'tool.result failed' );
};

subtest 'over 64 kB: the spawn goes ahead with agent.warning in stream and journal' => sub {
  my ( $app, $events ) = project(
    decl   => "briefing:\n  skills: [ huge ]\n",
    skills => { huge => "---\ndescription: Huge.\n---\n".( "word " x 14000 )."\n" },
  );
  my $session = $app->create_session;
  is( $app->run_prompt( 'go', session => $session )->{response}, 'parent answer', 'the run completes' );
  my @agent = grep { $_->{type} =~ /\Aagent\./ } @$events;
  is( [ map { $_->{type} } @agent ], [qw( agent.warning agent.started agent.finished )], 'the warning comes first' );
  like( $agent[0], { call => 'c1', agent => 'briefed',
    message => qr/\Abriefing: agent 'briefed' is briefed with 68 kB of skill text \(over 64 kB\) — consider declaring fewer or smaller skills\.\z/ },
    'agent.warning: call, agent, the size note' );
  my ($journaled) = grep { $_->{type} eq 'agent.warning' } @{ $app->session_store->read( $session->id )->events };
  like( $journaled, { call => 'c1', agent => 'briefed', message => qr/68 kB/ }, 'in the caller\'s journal' );
  like( user_text( $app->mock_engine->requests->[1] ), qr/<skill name="huge" /, 'the child is briefed all the same' );
};

subtest 'config explain flags agents whose skills do not resolve' => sub {
  my ( $app ) = project(
    decl   => "skills: [ notes, ghost ]\n",
    skills => { notes => "---\ndescription: Notes.\n---\nN\n" },
  );
  my %agent = map { $_->{name} => $_ } @{ $app->explain_config->{agents} };
  is( $agent{briefed}{missing_skills}, ['ghost'], 'missing_skills' );
  is( $agent{'general-purpose'}{missing_skills}, [], 'none for an agent without skills' );

  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  Langertha::Raider::CLI::Output->new( out => $fh )->config_report( {
    file => '/x/.raider.yml', exists => 1, engine => 'openai', values => [], ignored => [],
    agents => [ $agent{briefed} ],
  } );
  close $fh;
  like( Encode::decode( 'UTF-8', $buf ), qr/^    unknown skills: ghost \(the agent tool refuses to start it\)$/m, 'the agents section says so' );
};

done_testing;
