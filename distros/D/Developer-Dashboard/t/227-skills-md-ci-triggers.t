use strict;
use warnings FATAL => 'all';

use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;
use YAML::XS ();

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );

plan skip_all => 'workflow YAML files are excluded from the built distribution'
  if !-d File::Spec->catdir( $ROOT, '.github', 'workflows' );

# _slurp($path)
# Purpose: read a whole text file into one string.
# Input: a filesystem path.
# Output: the file's full content, or dies on open failure.
# Matches t/15-release-metadata.t's own _slurp helper, rather than adding a
# new slurp dependency this project's other tests do not already use.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

# trigger_block($workflow_file)
# Purpose: resolve a GitHub Actions workflow's `on:` trigger block by value,
#   never by assuming a key name - YAML 1.1 reads a bare `on` as the boolean
#   true, and this file is parsed by whichever YAML::XS the host happens to
#   carry (t/34's own documented gotcha).
# Input: a workflow filename under .github/workflows/ (e.g. 'test.yml').
# Output: a hashref of that workflow's trigger block, or {} if none is found.
sub trigger_block {
    my ($workflow_file) = @_;
    my $doc = YAML::XS::LoadFile( File::Spec->catfile( $ROOT, '.github', 'workflows', $workflow_file ) );
    my ($block) = grep { ref $_ eq 'HASH' }
      map { $doc->{$_} } grep { m/\A(?:on|true|1)\z/ } keys %$doc;
    return $block // {};
}

my %triggers = map { $_ => trigger_block($_) }
  qw(test.yml codeql.yml package-ghcr.yml fuzz-js.yml);

for my $file ( sort keys %triggers ) {
    ok( ref $triggers{$file} eq 'HASH' && keys %{ $triggers{$file} },
        "the on: trigger block for $file was located, so the assertions below have a subject" );
}

# AC-1: SKILLS.md's CI description must match the current on: blocks exactly.
# Each workflow's REAL trigger set, read live rather than trusted from memory -
# this is the same fact this ticket's own card was filed to correct, and it had
# already drifted again by the time of the fix (test.yml/fuzz-js.yml gained
# pull_request, package-ghcr.yml gained tags/workflow_dispatch since the card
# was written), which is exactly why this is a standing regression test and not
# a one-off doc edit.
ok( exists $triggers{'test.yml'}{push}, 'test.yml runs on push' );
is_deeply( $triggers{'test.yml'}{push}{branches}, ['master'], 'test.yml pushes are scoped to master' );
ok( exists $triggers{'test.yml'}{pull_request}, 'test.yml also runs on pull_request' );
ok( !exists $triggers{'test.yml'}{schedule}, 'test.yml has no schedule trigger' );
ok( !exists $triggers{'test.yml'}{workflow_dispatch}, 'test.yml has no manual-dispatch trigger' );

ok( exists $triggers{'codeql.yml'}{push}, 'codeql.yml runs on push' );
is_deeply( $triggers{'codeql.yml'}{push}{branches}, ['**'], 'codeql.yml pushes are NOT scoped to master - every branch' );
ok( exists $triggers{'codeql.yml'}{pull_request}, 'codeql.yml also runs on pull_request' );
ok( exists $triggers{'codeql.yml'}{schedule}, 'codeql.yml also runs on a schedule' );

ok( exists $triggers{'package-ghcr.yml'}{push}, 'package-ghcr.yml runs on push' );
is_deeply( $triggers{'package-ghcr.yml'}{push}{branches}, ['master'], 'package-ghcr.yml branch pushes are scoped to master' );
ok( exists $triggers{'package-ghcr.yml'}{push}{tags}, 'package-ghcr.yml ALSO runs on version tags, not only branch pushes' );
ok( exists $triggers{'package-ghcr.yml'}{workflow_dispatch}, 'package-ghcr.yml also runs via manual dispatch' );
ok( !exists $triggers{'package-ghcr.yml'}{pull_request}, 'package-ghcr.yml has no pull_request trigger' );

ok( exists $triggers{'fuzz-js.yml'}{push}, 'fuzz-js.yml runs on push' );
is_deeply( $triggers{'fuzz-js.yml'}{push}{branches}, ['master'], 'fuzz-js.yml pushes are scoped to master' );
ok( exists $triggers{'fuzz-js.yml'}{pull_request}, 'fuzz-js.yml also runs on pull_request' );
ok( exists $triggers{'fuzz-js.yml'}{workflow_dispatch}, 'fuzz-js.yml also runs via manual dispatch' );

# The actual regression guard: SKILLS.md's prose must acknowledge that none of
# the four workflows runs ONLY on push to master. The old wording ("runs Test,
# CodeQL, Package GHCR, and JS Fuzz on every push to master") was wrong for all
# four, not only CodeQL as originally filed.
my $skills_md = _slurp( File::Spec->catfile( $ROOT, 'SKILLS.md' ) );
unlike( $skills_md, qr/runs\s+Test,\s*CodeQL,\s*Package\s*GHCR,\s*and\s*JS\s*Fuzz\s+on\s+every\s*\n?\s*push\s+to\s+`master`/s,
    'SKILLS.md no longer makes the single blanket push-to-master claim for all four workflows' );
like( $skills_md, qr/pull request/i,
    "SKILLS.md's CI description mentions pull requests, which test.yml, codeql.yml and fuzz-js.yml all trigger on" );
like( $skills_md, qr/tag/i,
    "SKILLS.md's CI description mentions tags, which package-ghcr.yml also triggers on" );
like( $skills_md, qr/schedule|weekly/i,
    "SKILLS.md's CI description mentions the schedule, which only codeql.yml has" );
like( $skills_md, qr/every branch/i,
    "SKILLS.md's CI description states that codeql.yml's push trigger is NOT scoped to master" );

# AC-2: no other workflow-trigger claim in SKILLS.md or README.md is left
# inconsistent. Neither file may still assert the disproven "only master" claim.
my $readme = _slurp( File::Spec->catfile( $ROOT, 'README.md' ) );
unlike( $readme, qr/runs\s+Test,\s*CodeQL,\s*Package\s*GHCR,\s*and\s*JS\s*Fuzz\s+on\s+every\s*\n?\s*push\s+to\s+`master`/s,
    'README.md does not repeat the disproven blanket push-to-master claim either' );

done_testing();

__END__

=for comment FULL-POD-DOC START

=head1 NAME

t/227-skills-md-ci-triggers.t - the project's skills guide describes CI triggers that match the real workflow YAML

=head1 PURPOSE

This test is the executable regression contract for the claim the top-level project skills guide makes about which events trigger C<.github/workflows/*.yml>. It runs in a source checkout and skips in a built distribution, which intentionally excludes GitHub workflow files. Read it when you need to understand what each workflow's real C<on:> block contains and what that guide is required to say about it, instead of trusting either source from memory.

=head1 WHY IT EXISTS

DD-1001 found that the skills guide's single sentence ("runs Test, CodeQL, Package GHCR, and JS Fuzz on every push to C<master>") was wrong for CodeQL, which also runs on every branch push, every pull request, and a weekly schedule. Re-verifying live while fixing it found the claim had ALSO drifted for the other three workflows in the few days since the card was filed - test.yml and fuzz-js.yml gained C<pull_request>, and package-ghcr.yml gained C<tags> and C<workflow_dispatch>. A one-off prose edit would drift again the same way; this test re-reads the real YAML every run so the next drift fails loudly instead of sitting unnoticed.

=head1 WHEN TO USE

Use this file in a repository checkout whenever a C<.github/workflows/*.yml> trigger block changes, when the skills guide's CI description is edited, or when a focused CI failure points here. In a packaged installation the workflow directory is absent, so the test reports a documented skip.

=head1 HOW TO USE

Run it directly with C<prove -lv t/227-skills-md-ci-triggers.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the release verification loop all rely on this file to keep the skills guide's CI description from silently drifting away from the real workflow definitions again.

=head1 EXAMPLES

Example 1:

  prove -lv t/227-skills-md-ci-triggers.t

Run the focused regression test by itself while changing a workflow's C<on:> block or the skills guide's CI prose.

Example 2:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
