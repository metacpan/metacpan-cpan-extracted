use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Dist::Zilla::Tester;

# Excluded directories (e.g. .claude/worktrees/ — full agent checkouts, often
# thousands of files) must be PRUNED before descending, not walked-then-dropped
# per leaf. Proxy for "did not descend": a directory under worktrees/ that we
# cannot even opendir (mode 0000). The old per-leaf iterator descends into it and
# dies with a permission error; a pruning walk never opens it.
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
sub gathered { my $t = shift; sort map { $_->name } grep { index($_->name,'misc/agent-context/')==0 } @{ $t->files } }

SKIP: {
  skip 'running as root: 0000 dir is still readable', 2 if $> == 0;

  my $tzil = build_tzil( files => {
    'source/.claude/skills/foo/SKILL.md' => "keep\n",
  });
  my $locked = path($tzil->root)->child('.claude/worktrees/locked');
  $locked->mkpath;
  $locked->child('deep.md')->spew_utf8("deep\n");
  skip 'cannot chmod on this filesystem', 2
    unless eval { chmod 0000, "$locked"; 1 };

  my $ok  = eval { plugin($tzil)->gather_files; 1 };
  my $err = $@;
  chmod 0700, "$locked";          # restore so the tempdir can be cleaned up

  ok $ok, 'excluded worktrees/ is pruned, not descended (no permission error)'
    or diag "gather_files died: $err";
  ok( ( grep { $_ eq 'misc/agent-context/.claude/skills/foo/SKILL.md' } gathered($tzil) ),
    'sibling skills are still gathered while worktrees/ is pruned' );
}

# Same for harness state that is not agent content: .claude/projects/ holds
# every session transcript of the checkout. It must not be opened at all.
SKIP: {
  skip 'running as root: 0000 dir is still readable', 2 if $> == 0;

  my $tzil = build_tzil( files => {
    'source/.claude/skills/foo/SKILL.md' => "keep\n",
  });
  my $locked = path($tzil->root)->child('.claude/projects');
  $locked->mkpath;
  $locked->child('session.jsonl')->spew_utf8("log\n");
  skip 'cannot chmod on this filesystem', 2
    unless eval { chmod 0000, "$locked"; 1 };

  my $ok  = eval { plugin($tzil)->gather_files; 1 };
  my $err = $@;
  chmod 0700, "$locked";          # restore so the tempdir can be cleaned up

  ok $ok, 'harness state dir is pruned, not descended (no permission error)'
    or diag "gather_files died: $err";
  is_deeply [ gathered($tzil) ],
    [ 'misc/agent-context/.claude/skills/foo/SKILL.md' ],
    'only the agent content next to it is gathered';
}

done_testing;
