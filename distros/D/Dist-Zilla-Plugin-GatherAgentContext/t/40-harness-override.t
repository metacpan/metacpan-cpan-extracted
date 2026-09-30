use strict;
use warnings;
use Test::More;
use Dist::Zilla::Tester;

sub build_tzil {
  my (%opt) = @_;
  my @ini = @{ $opt{ini} || [] }; my $files = $opt{files} || {};
  Dist::Zilla::Tester->from_config(
    { dist_root => 't/does-not-exist' },
    { add_files => {
        'source/dist.ini' => join("\n",
          'name = AC-Test','author = Test <test@example.com>','license = Perl_5',
          'copyright_holder = Test','version = 0.001','','[GatherAgentContext]',@ini,''),
        'source/lib/AC/Test.pm' => "package AC::Test;\n# ABSTRACT: t\nour \$VERSION='0.001';\n1;\n",
        %$files,
      } },
  );
}
sub plugin { my $t = shift; (grep { $_->isa('Dist::Zilla::Plugin::GatherAgentContext') } @{ $t->plugins })[0] }
sub under  { my ($t,$p)=@_; sort map { $_->name } grep { index($_->name,$p)==0 } @{ $t->files } }

my %ALL = (
  'source/CLAUDE.md'                    => "c\n",
  'source/AGENTS.md'                    => "a\n",
  'source/.claude/skills/foo/SKILL.md'  => "s\n",
  'source/.codex/agents/.local.x.toml'  => "x\n",
  'source/.agents/skills/bar/SKILL.md'  => "b\n",
);

# harness = claude -> nur .claude + CLAUDE.md
{
  my $t = build_tzil( ini => ['harness = claude'], files => { %ALL } );
  plugin($t)->gather_files;
  my @g = under($t,'misc/agent-context/');
  ok(  scalar( grep { $_ eq 'misc/agent-context/CLAUDE.md' } @g ), 'claude: CLAUDE.md in' );
  ok(  scalar( grep { $_ eq 'misc/agent-context/.claude/skills/foo/SKILL.md' } @g ), 'claude: .claude in' );
  ok( !scalar( grep { m{/AGENTS\.md$} } @g ), 'claude: AGENTS.md out' );
  ok( !scalar( grep { m{/\.codex/} } @g ),    'claude: .codex out' );
  ok( !scalar( grep { m{/\.agents/} } @g ),   'claude: .agents out' );
}

# harness = codex -> .codex + .agents/skills + AGENTS.md
{
  my $t = build_tzil( ini => ['harness = codex'], files => { %ALL } );
  plugin($t)->gather_files;
  my @g = under($t,'misc/agent-context/');
  ok(  scalar( grep { $_ eq 'misc/agent-context/AGENTS.md' } @g ), 'codex: AGENTS.md in' );
  ok(  scalar( grep { $_ eq 'misc/agent-context/.codex/agents/.local.x.toml' } @g ), 'codex: .codex in' );
  ok(  scalar( grep { $_ eq 'misc/agent-context/.agents/skills/bar/SKILL.md' } @g ), 'codex: .agents/skills in' );
  ok( !scalar( grep { m{/CLAUDE\.md$} } @g ), 'codex: CLAUDE.md out' );
  ok( !scalar( grep { m{/\.claude/} } @g ),   'codex: .claude out' );
}

# explizites dir + to -> ersetzt Default-dirs, eigener Zielpfad
{
  my $t = build_tzil(
    ini   => ['dir = only/here', 'to = misc/prov'],
    files => { 'source/only/here/x.md' => "x\n",
               'source/.claude/skills/foo/SKILL.md' => "s\n" },
  );
  plugin($t)->gather_files;
  is_deeply [ under($t,'misc/prov/') ], [ 'misc/prov/only/here/x.md' ],
    'explicit dir + to wins; default dirs ignored';
  ok !( grep { index($_->name,'misc/agent-context/')==0 } @{ $t->files } ),
    'nothing gathered under the default to';
}

done_testing;
