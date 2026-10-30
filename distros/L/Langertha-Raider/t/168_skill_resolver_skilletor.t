#!/usr/bin/env perl
# ABSTRACT: The Skilletor skill resolver: skills skilletor.json declares, read from their source without installing; reasons for what does not resolve (ADR 0020 section 6, k153)
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
use File::Which qw( which );
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Context;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::SkillResolver::Skilletor;
use Test::Raider::MockAI qw( mock_app );

delete @ENV{qw( RAIDER_HALL_SOCKET RAIDER_PACK_DIRS )};

# Never the network: every source below is local, and git (one subtest) only
# ever sees a path that does not exist.
my @tmp;
sub tmp { push @tmp, Path::Tiny->tempdir; return $tmp[-1]->realpath }

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

# A home, a project and a local source with skills foo (plain) and tpl (a
# Nunjucks template); the project's skilletor.json declares %install (default
# foo, tpl and nope@mine). The source is trusted unless untrusted => 1.
sub setup {
  my ( %o ) = @_;
  my $home = tmp();
  my $root = tmp();
  my $src  = tmp();
  $src->child('skills/foo/SKILL.md')->touchpath->spew_utf8("---\nname: foo\ndescription: Foo.\n---\n\nFOO-FROM-SKILLETOR\n");
  $src->child('skills/tpl/SKILL.md.njk')->touchpath->spew_utf8("---\nname: tpl\ndescription: T.\n---\n{{ x }}\n");
  $root->child('CLAUDE.md')->spew_utf8("Project.\n") unless $o{native};
  my $config = $o{config} // $json->encode( {
    sources => { mine => { local => "$src" } },
    install => { skills => $o{skills} // [qw( foo@mine tpl@mine nope@mine )] },
  } );
  $root->child('.claude/skilletor.json')->touchpath->spew_utf8($config);
  $home->child('.claude/skilletor/trust.json')->touchpath->spew_utf8(
    $json->encode( { mine => { kind => 'local', address => "$src" } } ) ) unless $o{untrusted};
  return ( $home, $root, $src );
}

sub resolver {
  my ( $home, $root ) = @_;
  return Langertha::Raider::SkillResolver::Skilletor->new( home => "$home", project_dir => "$root" );
}

subtest 'a declared skill: its SKILL.md in the source, nothing installed' => sub {
  my ( $home, $root, $src ) = setup();
  my $r = resolver( $home, $root );
  is( $r->resolve('foo'),
    { name => 'foo', dir => "$src/skills/foo", file => "$src/skills/foo/SKILL.md", via => 'skilletor:mine' },
    'name, dir and file point into the local source; via names it' );
  is( $r->why_unresolved('foo'), undef, 'no reason for a skill that resolves' );
  ok( !$root->child('.claude/skills')->exists, 'nothing installed into the project' );
  ok( !$home->child('.claude/skills')->exists, 'nor into the home' );
};

subtest 'what does not resolve says why' => sub {
  my ( $home, $root ) = setup();
  my $r = resolver( $home, $root );
  is( $r->resolve('tpl'), undef, 'a template does not resolve' );
  is( $r->why_unresolved('tpl'), 'skilletor: tpl@mine is a template; templates are not supported in Perl', '... because it is one' );
  is( $r->resolve('nope'), undef, 'a declared skill the source lacks' );
  is( $r->why_unresolved('nope'), 'skilletor: item not found in source mine: skill nope', '... skilletor\'s warning' );
  is( $r->resolve('ghost'), undef, 'a name nobody declares' );
  is( $r->why_unresolved('ghost'), undef, '... has no reason' );
};

subtest 'an untrusted project source: unresolved, the trust request as reason' => sub {
  my ( $home, $root ) = setup( untrusted => 1 );
  my $r = resolver( $home, $root );
  is( $r->resolve('foo'), undef, 'does not resolve' );
  is( $r->why_unresolved('foo'), 'skilletor: source "mine" is not trusted -- run: skilletor trust mine', 'the reason' );
};

subtest 'a broken skilletor.json never dies; every name gets the error' => sub {
  my ( $home, $root ) = setup( config => '{ "sources": ' );
  my $r = resolver( $home, $root );
  is( dies { is( $r->resolve('foo'), undef, 'does not resolve' ) }, undef, 'no exception' );
  like( $r->why_unresolved('foo'), qr/\Askilletor: .*skilletor\.json/, 'the config error, naming the file' );
  like( $r->why_unresolved('other'), qr/\Askilletor: /, 'for every name' );
};

subtest 'a source that cannot be fetched: unresolved with the reason, no exception' => sub {
  skip_all 'no git on PATH' unless which('git');
  my $missing = tmp()->child('no-such-repo');
  my ( $home, $root ) = setup( config => $json->encode( {
    sources => { remote => { git => 'file://'.$missing } },
    install => { skills => ['foo@remote'] },
  } ), untrusted => 1 );
  $home->child('.claude/skilletor/trust.json')->touchpath->spew_utf8(
    $json->encode( { remote => { kind => 'git', address => 'file://'.$missing } } ) );
  my $r = resolver( $home, $root );
  is( $r->resolve('foo'), undef, 'does not resolve' );
  like( $r->why_unresolved('foo'), qr/\Askilletor: source remote: /, 'skilletor says why' );
};

subtest 'without any skilletor.json nothing is asked and nothing written' => sub {
  my $home = tmp();
  my $root = tmp();
  my $r = resolver( $home, $root );
  ok( !$r->has_config, 'no config' );
  is( $r->resolve('foo'), undef, 'nothing resolves' );
  is( $r->why_unresolved('foo'), undef, 'no reason' );
  ok( !$r->has_skilletor, 'no Skilletor object built' );
  ok( !$home->child('.claude')->exists, 'nothing under the home' );
};

subtest 'the context: catalogue first, skilletor after it, only in the Claude layout' => sub {
  my ( $home, $root, $src ) = setup();
  local $ENV{HOME} = "$home";
  my $c = Langertha::Raider::Context->new( root => "$root" );
  ok( $c->claude_layout, 'a Claude layout' );
  is( $c->skill_resolver->resolve('foo')->{dir}, "$src/skills/foo", 'not installed: from skilletor' );
  isa_ok( $c->skill_resolver->resolvers->[1], ['Langertha::Raider::SkillResolver::Skilletor'], 'resolver 2' );

  $root->child('.claude/skills/foo/SKILL.md')->touchpath->spew_utf8("---\ndescription: Installed.\n---\nINSTALLED\n");
  my $c2 = Langertha::Raider::Context->new( root => "$root" );
  is( $c2->skill_resolver->resolve('foo'),
    { name => 'foo', dir => "$root/.claude/skills/foo", file => "$root/.claude/skills/foo/SKILL.md" },
    'installed: the catalogue wins' );
  ok( !$c2->skill_resolver->resolvers->[1]->has_skilletor, 'and skilletor is not even built' );

  my ( $nhome, $nroot ) = setup( native => 1 );
  $nroot->child('.raider')->mkpath;
  $nroot->child('.raider/config.yml')->spew_utf8("engine: openai\n");
  local $ENV{HOME} = "$nhome";
  my $native = Langertha::Raider::Context->new( root => "$nroot" );
  ok( !$native->claude_layout, 'a raider project' );
  is( scalar @{ $native->skill_resolver->resolvers }, 1, 'the catalogue alone' );
  is( $native->skill_resolver->resolve('foo'), undef, 'skilletor.json is not read' );
};

# A Claude project whose agent "briefed" declares @skills; the agent tool spawns it.
sub project {
  my ( @skills ) = @_;
  my ( $home, $root, $src ) = setup();
  $ENV{HOME} = "$home";
  $root->child('.claude/agents/briefed.md')->touchpath->spew_utf8(
    "---\nname: briefed\ndescription: Briefed.\nbriefing:\n  skills: [ ".join( ', ', @skills )." ]\n---\nBRIEFED-BODY\n" );
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
  return ( $app, \@events, $root, $src );
}

sub user_text {
  my ( $req ) = @_;
  my ($m) = grep { $_->{role} eq 'user' } @{ $req->{body}{messages} };
  my $c = $m->{content};
  my $text = ref $c ? join( '', map { $_->{text} // '' } @$c ) : $c;
  $text =~ s/\A\[situation\][^\n]*\n\n//;
  return $text;
}

subtest 'spawn: briefed with the skill read from its source' => sub {
  local $ENV{HOME} = $ENV{HOME};
  my ( $app, $events, $root, $src ) = project('foo');
  is( '' . $app->run('go'), 'parent answer', 'the caller answers' );
  like( user_text( $app->mock_engine->requests->[1] ),
    qr{<skill name="foo" dir="\Q$src\E/skills/foo">\nFOO-FROM-SKILLETOR\n</skill>\n\n---\n\n# Original task\n\nTHE-TASK\z},
    'the body and the source dir' );
  like( $app->mock_engine->results->[-1]{result}{content}[0]{text}, qr/\Achild answer\nagentId: agent_1 /, 'the caller gets the answer' );
};

subtest 'spawn: a template is refused with the reason; without a reason the plain note' => sub {
  local $ENV{HOME} = $ENV{HOME};
  my ( $app, $events ) = project(qw( foo tpl ghost ));
  is( '' . $app->run('go'), 'child answer', 'the caller goes on' );
  my $r = $app->mock_engine->results->[-1];
  ok( $r->{result}{isError}, 'the agent call fails' );
  is( $r->{result}{content}[0]{text},
    "briefing: agent 'briefed' references unknown skill(s): tpl (skilletor: tpl\@mine is a template; templates are not supported in Perl), ghost",
    'the reason per skill, none for the unknown one' );
  is( scalar @{ $app->mock_engine->requests }, 2, 'no child request' );
  is( [ grep { $_->{type} =~ /\Aagent\./ } @$events ], [], 'nothing started' );
};

subtest 'config explain: where each skill resolved, why the others did not' => sub {
  local $ENV{HOME} = $ENV{HOME};
  my ( $app, undef, $root ) = project(qw( foo tpl ghost ));
  my %agent = map { $_->{name} => $_ } @{ $app->explain_config->{agents} };
  is( $agent{briefed}{missing_skills}, [qw( tpl ghost )], 'missing_skills' );
  is( $agent{briefed}{missing_reasons},
    { tpl => 'skilletor: tpl@mine is a template; templates are not supported in Perl' }, 'missing_reasons' );
  is( $agent{briefed}{skill_via}, { foo => 'skilletor:mine' }, 'skill_via' );

  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  Langertha::Raider::CLI::Output->new( out => $fh )->config_report( {
    file => '/x/.raider.yml', exists => 1, engine => 'openai', values => [], ignored => [],
    agents => [ $agent{briefed} ],
  } );
  close $fh;
  my $text = Encode::decode( 'UTF-8', $buf );
  like( $text, qr/skills foo \(skilletor:mine\), tpl, ghost$/m, 'the skill found in skilletor is marked' );
  like( $text,
    qr/^    unknown skills: tpl \(skilletor: tpl\@mine is a template; templates are not supported in Perl\), ghost \(the agent tool refuses to start it\)$/m,
    'the unknown ones with their reasons' );
};

done_testing;
