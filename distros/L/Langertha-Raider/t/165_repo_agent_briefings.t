#!/usr/bin/env perl
# ABSTRACT: The real case: this repository's own .claude/agents/raider-*.md are briefed from its .claude/skills (ADR 0020 section 6, k153)
use strict;
use warnings;
use utf8;
use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Tiny;
use YAML::PP ();

# The skills are build artifacts (skilletor installs them, .gitignore keeps
# them out of git), so a fresh clone or a built dist has none.
my $repo = path("$FindBin::Bin/..")->realpath;
plan skip_all => 'needs the installed project skills (.claude/skills/getty-perl-core/SKILL.md, installed by skilletor sync)'
  unless -f $repo->child('.claude/skills/getty-perl-core/SKILL.md');
my @files = sort $repo->child('.claude/agents')->children(qr/\Araider-.*\.md\z/);
plan skip_all => 'no .claude/agents/raider-*.md here' unless @files;

use Test::Raider::Env qw( isolate_home );
isolate_home();   # the agents' skills are all project skills; no user skill may stand in
use Langertha::Raider::Context;
use Langertha::Raider::Briefing;

my $context = Langertha::Raider::Context->new( root => "$repo", force_claude => 1 );
my $catalog = $context->agent_catalog;
my $header  = Langertha::Raider::Briefing->header;
my %report  = map { $_->{name} => $_ } @{ $context->report->{agents} };

for my $file (@files) {
  # What the file declares, read here with YAML::PP as the oracle: Claude
  # Code's skills first, then briefing.skills, each once.
  my ($fm) = $file->slurp_utf8 =~ /\A---\r?\n(.*?)\r?\n---\r?\n/s;
  my $data = YAML::PP->new->load_string($fm);
  my %seen;
  my @declared = grep { !$seen{$_}++ } map { ref $_ ? @$_ : split /\s*,\s*/ } grep { defined }
    $data->{skills}, ( ref $data->{briefing} eq 'HASH' ? $data->{briefing}{skills} : () );
  my $name = $data->{name} // $file->basename(qr/\.md\z/);

  subtest $name => sub {
    my $agent = $catalog->find($name);
    ok( $agent, 'in the agent catalogue' ) or return;
    ok( scalar @declared, 'declares skills' );
    is( $agent->{skills}, \@declared, 'the catalogue reads the same skills' );

    my $b = Langertha::Raider::Briefing->new( agent => $name, skills => $agent->{skills}, resolver => $context->skill_resolver );
    is( [ $b->missing ], [], 'every skill resolves' );
    my $prompt = $b->prompt('TASK');
    ok( index( $prompt, $header ) == 0, 'starts with the header' );
    like( $prompt, qr/\n<\/skill>\n\n---\n\n# Original task\n\nTASK\z/, 'ends with the task' );
    my @blocks = $prompt =~ /^<skill name="([^"]+)" dir="([^"]+)">\n/mg;
    my @names = @blocks[ grep { !( $_ % 2 ) } 0 .. $#blocks ];
    is( \@names, \@declared, 'one block per declared skill, in order' );
    for my $skill (@declared) {
      my $dir = $repo->child( '.claude/skills', $skill );
      my ( $body ) = $dir->child('SKILL.md')->slurp_utf8 =~ /\A---\r?\n.*?\r?\n---\r?\n(.*)\z/s;
      $body =~ s/\A\s+|\s+\z//g;
      ok( index( $prompt, '<skill name="'.$skill.'" dir="'.$dir.'">'."\n".$body."\n</skill>" ) >= 0,
        $skill.': its project directory, the body without frontmatter' );
    }
    note sprintf '%s: %d skills, %d bytes of skill text (%.1f kB)%s', $name, scalar @declared, $b->size, $b->size / 1024,
      $b->oversized ? ' -- OVER the 64 kB budget' : '';
    is( $report{$name}{missing_skills}, [], 'config explain: nothing missing' );
  };
}

done_testing;
