use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Spec;
use FindBin qw($RealBin);
use Test::More;
use YAML::XS ();

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $repo_workflow = File::Spec->catfile( $ROOT, '.github', 'workflows', 'test.yml' );

# Detect the checkout by EXISTENCE, never by directory-ness. In the primary
# checkout .git is a directory, but in a linked git worktree it is a regular file
# holding a "gitdir:" pointer - and ticket work in this repository is done in
# per-ticket worktrees. A -d test here therefore skipped this entire file exactly
# where changes are authored, so every guardrail below (SHA pins, workflow
# permission scoping, dependency floors) was inert at the one moment it was most
# needed. An unpacked release tarball has neither shape, so the original intent -
# do not run source-tree checks against an installed dist - is unchanged.
plan skip_all => 'Scorecard guardrails are source-tree-only checks'
  if !-e File::Spec->catdir( $ROOT, '.git' ) || !-f $repo_workflow;

ok( _git_tracks('LICENSE'), 'root LICENSE is tracked for Scorecard license detection' );
ok( _git_tracks('SECURITY.md'), 'root SECURITY.md is tracked for Scorecard security-policy detection' );
ok( _git_tracks('SECURITY_CHECKS.md'), 'root SECURITY_CHECKS.md is tracked so OWASP and release audit tests read the same repo state on CI' );
ok( _git_tracks('.github/dependabot.yml'), 'Dependabot config is tracked for Scorecard dependency-update-tool detection' );
ok( _git_tracks('.github/workflows/codeql.yml'), 'CodeQL workflow is tracked for Scorecard SAST detection' );
ok( _git_tracks('.github/workflows/package-ghcr.yml'), 'GHCR packaging workflow is tracked for Scorecard packaging detection' );
ok( _git_tracks('.github/workflows/fuzz-js.yml'), 'fuzzing workflow is tracked for Scorecard fuzzing detection' );
ok( _git_tracks('.github/workflows/release-github.yml'), 'GitHub release workflow is tracked for Scorecard signed-release detection' );
ok( _git_tracks('.clusterfuzzlite/Dockerfile'), 'ClusterFuzzLite Dockerfile is tracked for Scorecard fuzzing detection' );

my $license = _slurp('LICENSE');
like( $license, qr/\AMIT License\n\nCopyright \(c\) \d{4} Developer Dashboard Contributors\n\nPermission is hereby granted, free of charge, to any person obtaining a copy/s, 'LICENSE uses the canonical MIT text that GitHub can classify' );
like( $license, qr/THE SOFTWARE IS PROVIDED "AS IS"/, 'LICENSE includes the canonical MIT warranty disclaimer' );

my $security = _slurp('SECURITY.md');
like( $security, qr/Reporting A Vulnerability/i, 'SECURITY.md documents vulnerability reporting' );
like( $security, qr/security@/i, 'SECURITY.md includes a private reporting contact' );

my $dependabot = _slurp('.github/dependabot.yml');
like( $dependabot, qr/package-ecosystem:\s*["']github-actions["']/, 'Dependabot manages GitHub Actions updates' );
like( $dependabot, qr/package-ecosystem:\s*["']npm["']/, 'Dependabot manages npm-based fuzzing dependencies' );

my $codeql = _slurp('.github/workflows/codeql.yml');
unlike( $codeql, qr/^permissions:\s*$(?:\n^[^\n]*:\s*write\s*$)+/ms, 'CodeQL workflow does not use top-level write permissions' );
like( $codeql, qr/jobs:\n\s+analyze:\n(?:.+\n)*?\s+permissions:\n(?:.+\n)*?\s+security-events:\s*write\b/ms, 'CodeQL workflow grants security-events write only at the job level' );
like( $codeql, qr/uses:\s*github\/codeql-action\/init\@[0-9a-f]{40}/, 'CodeQL init action is pinned by full SHA' );
like( $codeql, qr/uses:\s*github\/codeql-action\/analyze\@[0-9a-f]{40}/, 'CodeQL analyze action is pinned by full SHA' );

my $package_workflow = _slurp('.github/workflows/package-ghcr.yml');
unlike( $package_workflow, qr/^permissions:\s*$(?:\n^[^\n]*:\s*write\s*$)+/ms, 'packaging workflow does not use top-level write permissions' );
like( $package_workflow, qr/jobs:\n\s+package:\n(?:.+\n)*?\s+permissions:\n(?:.+\n)*?\s+packages:\s*write\b/ms, 'packaging workflow grants package publish access only at the job level' );
like( $package_workflow, qr/ghcr\.io/i, 'packaging workflow publishes to GHCR' );
like( $package_workflow, qr/uses:\s*docker\/build-push-action\@[0-9a-f]{40}/, 'docker build-push action is pinned by full SHA' );
like( $package_workflow, qr/uses:\s*docker\/login-action\@[0-9a-f]{40}/, 'docker login action is pinned by full SHA' );

# The login step is the only one in the pipeline that handles registry
# credentials, so its execution must not depend on GitHub rerouting a stale
# runtime for it: the docker/login-action v3 line declares node20 while the v4
# line declares node24 natively. Keep the pin on v4+, and keep an auditable
# vX.Y.Z comment beside the SHA so a reviewer can tell which upstream release the
# 40-hex pin resolves to without a network round-trip. DD-449 removed the
# FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 shim these jobs used to set, because it is
# documented as removable once no pinned action still declares node20, and none
# does - script/audit-action-pins is what keeps that true.
my ($login_pin_version) = $package_workflow =~ m{uses:\s*docker/login-action\@[0-9a-f]{40}\s+\#\s*v(\d+(?:\.\d+){2})\b};
ok( defined $login_pin_version, 'docker login action pin carries an auditable vX.Y.Z comment beside its SHA' )
  or diag('no "# vX.Y.Z" comment found beside the docker/login-action SHA pin');
cmp_ok( ( split /\./, ( $login_pin_version // '0.0.0' ) )[0],
    '>=', 4, 'docker login action is pinned on the node24-native v4 line, not the node20 v3 line' );

my $github_release_workflow = _slurp('.github/workflows/release-github.yml');
unlike( $github_release_workflow, qr/^permissions:\s*$(?:\n^[^\n]*:\s*write\s*$)+/ms, 'GitHub release workflow does not use top-level write permissions' );
like( $github_release_workflow, qr/jobs:\n\s+release:\n(?:.+\n)*?\s+permissions:\n(?:.+\n)*?\s+contents:\s*write\b/ms, 'GitHub release workflow grants release-publish access only at the job level' );
like( $github_release_workflow, qr/gh\s+release\s+create\b/, 'GitHub release workflow creates GitHub releases' );
like( $github_release_workflow, qr/gh\s+release\s+upload\b/, 'GitHub release workflow updates existing GitHub releases' );
like( $github_release_workflow, qr/cpanm\s+--notest\s+Devel::Cover\b/, 'GitHub release workflow installs Devel::Cover before it runs the numeric coverage gate' );
like( $github_release_workflow, qr/\.asc\b/, 'GitHub release workflow publishes a detached signature asset next to the release tarball' );
like( $github_release_workflow, qr/Developer-Dashboard-\*\.tar\.gz/, 'GitHub release workflow locates built distribution tarballs from the repo root' );

# Scorecard's Signed-Releases check scores a signed artifact 8 and reserves the
# last 2 points for build provenance, so the signing half alone caps the check at
# 8/10 (checks/evaluation/signed_releases.go sets releaseMap[release]=8 for
# releasesAreSigned and =10 for releasesHaveProvenance). The decisive detail is
# HOW the provenance probe looks: probes/releasesHaveProvenance/impl.go matches
# release ASSETS by name against provenanceExtensions = {".intoto.jsonl"} and
# nothing else. Recording the attestation in GitHub's attestation store is
# therefore necessary but NOT sufficient - without an asset whose name ends
# .intoto.jsonl the check stays at 8 no matter how the attestation was produced.
# Pin the asset, the action, and the pin's auditability together, because losing
# any one of them silently returns the check to 8 with the workflow still green.
like( $github_release_workflow, qr/uses:\s*actions\/attest-build-provenance\@[0-9a-f]{40}/,
    'GitHub release workflow generates a build-provenance attestation via a SHA-pinned first-party action' );
like( $github_release_workflow, qr/\.intoto\.jsonl\b/,
    'GitHub release workflow publishes the provenance as an .intoto.jsonl asset, the only name Scorecard scores as provenance' );
my ($attest_pin_version) =
  $github_release_workflow =~ m{uses:\s*actions/attest-build-provenance\@[0-9a-f]{40}\s+\#\s*v(\d+(?:\.\d+){2})\b};
ok( defined $attest_pin_version, 'attest-build-provenance pin carries an auditable vX.Y.Z comment beside its SHA' )
  or diag('no "# vX.Y.Z" comment found beside the actions/attest-build-provenance SHA pin');
cmp_ok( ( split /\./, ( $attest_pin_version // '0.0.0' ) )[0],
    '>=', 4, 'attest-build-provenance is pinned on the v4 line that ships the node24-native attest core' );

# Least privilege across the split, asserted structurally rather than by regex:
# minting an OIDC token is what lets this workflow speak as the repository, and
# the `release` job is the one that runs the whole Perl suite, the coverage pass
# and `dzil build` - thousands of lines of project code plus every CPAN
# dependency they pull in. Handing OIDC to that job would put the repository's
# identity behind the largest block of executable code in the pipeline. The
# attestation therefore belongs in its own job that runs no project code, and
# this pair of assertions is what stops a later edit from "simplifying" the two
# jobs back into one.
my $release_yaml = YAML::XS::LoadFile( File::Spec->catfile( $ROOT, '.github', 'workflows', 'release-github.yml' ) );
is( ref $release_yaml, 'HASH', 'GitHub release workflow parses as YAML' );

my $release_job    = $release_yaml->{jobs}{release}    // {};
my $provenance_job = $release_yaml->{jobs}{provenance} // {};

is( $release_job->{permissions}{'id-token'}, undef,
    'the job that runs the test suite, coverage pass and dzil build is NOT granted OIDC token minting' );
is( $release_job->{permissions}{'attestations'}, undef,
    'the job that runs project code is NOT granted attestation write access' );
is( $provenance_job->{permissions}{'id-token'}, 'write',
    'the dedicated provenance job mints its OIDC token at the job level' );
is( $provenance_job->{permissions}{'attestations'}, 'write',
    'the dedicated provenance job holds attestation write access at the job level' );
is( $provenance_job->{permissions}{'contents'}, 'write',
    'the dedicated provenance job may attach its asset to the release' );
is( $provenance_job->{needs}, 'release',
    'the provenance job runs only after the release job has published the artifact it attests' );
like( $provenance_job->{'timeout-minutes'} // '', qr/\A\d+\z/,
    'the provenance job sets its own explicit timeout' );

# The provenance job attests the bytes GitHub actually published, not a local
# rebuild that merely ought to match, so it must prove the download is the
# signed artifact before it puts its name to it.
my $provenance_steps = join "\n", map { $_->{run} // '' } @{ $provenance_job->{steps} // [] };
like( $provenance_steps, qr/sha256sum\s+(?:--check|-c)\b/,
    'the provenance job verifies the published checksum before attesting the downloaded artifact' );
unlike( $provenance_steps, qr/\bprove\b|\bdzil\b|\bcpanm\b/,
    'the provenance job runs no project code, so its OIDC grant sits behind nothing executable from this repo' );
like( $provenance_steps, qr/gh\s+release\s+upload\b/,
    'the provenance job attaches its asset to the release instead of leaving it in the attestation store only' );
like( $provenance_steps, qr/\.intoto\.jsonl\b/,
    'the provenance job names its published asset .intoto.jsonl inside the job that produces it' );

# Every `gh` call in this job must name its repository explicitly, and that is a
# correctness gate rather than a style preference. The job deliberately does not
# check the repository out - it runs no project code - so there are no git
# remotes in its working directory. gh resolves the base repository from `--repo`
# first, then the GH_REPO environment variable (pkg/cmdutil/repo_override.go,
# OverrideBaseRepoFunc), and only then falls back to reading git remotes, which
# fails as "no git remotes found". GITHUB_REPOSITORY is an Actions variable that
# gh never consults. A gh call here without an explicit selector therefore fails
# at run time on a real tag push, and it fails in the worst possible place: the
# attestation would be minted and then never attached, leaving Signed-Releases
# capped at exactly the 8/10 this whole job exists to lift.
my @provenance_step_list = @{ $provenance_job->{steps} // [] };
ok( !( grep { ( $_->{uses} // '' ) =~ m{\bactions/checkout\b} } @provenance_step_list ),
    'the provenance job checks out no repository, so gh has no git remote to fall back on' );

# Fold backslash continuations first, so a `gh` call whose --repo sits on a
# later physical line is judged as the one logical command it actually is.
my @gh_commands;
for my $step (@provenance_step_list) {
    my $run = $step->{run} // '';
    $run =~ s/\\\n\s*/ /g;
    my $env_has_repo = exists +( $step->{env} // {} )->{GH_REPO}
        || exists +( $provenance_job->{env} // {} )->{GH_REPO};
    for my $line ( split /\n/, $run ) {
        next unless $line =~ /(?:\A|[;&|(]\s*)gh\s+\S/;
        push @gh_commands, { line => $line, env_has_repo => $env_has_repo };
    }
}
ok( scalar @gh_commands, 'the provenance job invokes gh at least once' );
for my $cmd (@gh_commands) {
    my ($label) = $cmd->{line} =~ /\bgh\s+(\S+(?:\s+\S+)?)/;
    ok( $cmd->{env_has_repo} || $cmd->{line} =~ /(?:--repo|\s-R)[=\s]/,
        "provenance job's `gh $label` selects its repository explicitly, so it cannot fall back to absent git remotes" )
      or diag("gh call without --repo/-R or GH_REPO in scope: $cmd->{line}");
}

# DD-492. A tag push runs the workflow file AS FROZEN AT THAT TAG, so a fix
# landed on master is invisible to a tag that already exists. That is not a
# hypothetical: v4.23 (run 30496507981) and v4.24 (run 31235774599) both died at
# "Setup Perl" because each tag carries the pre-DD-449 node20 pin for
# shogo82148/actions-setup-perl v1.32.0, and the runner now forces node24. Since
# re-running that run, and dispatching at the tag ref, both replay the same
# frozen file, neither tag can ever reach its publish step. A release pipeline
# whose only trigger is frozen at the tag is therefore unrecoverable by
# construction, and this recurs on every runtime retirement, because the
# platform keeps moving while a tag does not.
#
# The recovery path is a dispatch that names an EXISTING tag and runs under the
# current definition on master. Three properties make that safe rather than a
# way to publish anything under any name, and each is asserted below because
# losing any one of them republishes the bug in a quieter form.
# Resolve the trigger block by hand rather than assuming a key name. YAML 1.1
# reads a bare `on` as the boolean true, YAML 1.2 keeps it a string, and this
# file is parsed by whichever YAML::XS the host happens to carry. If that lookup
# ever came back empty the assertions below would all pass against nothing,
# which is the "test aimed at an empty set" failure - so find the block, then
# fail loudly when it cannot be found.
my ($trigger_block) = grep { ref $_ eq 'HASH' && exists $_->{push} }
  map { $release_yaml->{$_} } grep { m/\A(?:on|true|1)\z/ } keys %$release_yaml;
ok( defined $trigger_block, 'the release workflow trigger block was located, so the trigger assertions have a subject' )
  or diag( 'no trigger block among top-level keys: ' . join( ',', sort keys %$release_yaml ) );
my $dispatch = ( $trigger_block // {} )->{workflow_dispatch};
ok( ref $dispatch eq 'HASH' && ref $dispatch->{inputs} eq 'HASH' && exists $dispatch->{inputs}{tag},
    'GitHub release workflow takes a tag input, so a tag whose frozen workflow cannot run is still publishable from master' )
  or diag('no workflow_dispatch input named "tag" in release-github.yml');

# The artifact must come from the TAGGED tree even though the definition comes
# from master, or a dispatch would publish master's code under an old tag's
# name - which is worse than not publishing at all, because it looks published.
my @release_step_list = @{ $release_job->{steps} // [] };
my ($release_checkout) = grep { ( $_->{uses} // '' ) =~ m{\bactions/checkout\b} } @release_step_list;
ok( defined $release_checkout, 'the release job checks the repository out' );
like( ( $release_checkout->{with} // {} )->{ref} // '', qr/\S/,
    'the release job checks out the resolved release tag, so a dispatch builds the tagged tree and not master' );

# One resolution, used by both jobs. The provenance job read GITHUB_REF_NAME
# directly, which is the TAG on a push and the BRANCH on a dispatch - so under
# the recovery path it would have downloaded and attested a release named
# "master". Both jobs must therefore agree on one resolved value.
my $release_tag_expr = ( $release_yaml->{env} // {} )->{RELEASE_TAG} // '';
like( $release_tag_expr, qr/inputs\.tag/,
    'the release tag resolves from the dispatch input at workflow level, where both jobs see the same value' );
like( $release_tag_expr, qr/github\.ref_name/,
    'the resolved release tag falls back to github.ref_name, so an ordinary tag push behaves exactly as before' );

my $every_release_step = join "\n", map { $_->{run} // '' } ( @release_step_list, @provenance_step_list );
unlike( $every_release_step, qr/\$\{?GITHUB_REF_NAME\b/,
    'no step derives the release tag from GITHUB_REF_NAME directly, which is the branch when the workflow is dispatched' );
like( $every_release_step, qr/\$\{?RELEASE_TAG\b/,
    'the publish steps name the resolved release tag' );

# A dispatch names an arbitrary ref, so without a shape guard "master" would be
# accepted and published as a release. Every one of this repository's 21 v-tags
# conforms to vN.NN, so the guard cannot break an existing path. It must also
# run BEFORE anything is created: refusing after `gh release create` would leave
# exactly the junk release it exists to prevent.
my $release_runs = join "\n", map { $_->{run} // '' } @release_step_list;
like( $release_runs, qr/v\[0-9\]|v\[\[:digit:\]\]|\[0-9\]\+\\\.\[0-9\]|\^v/,
    'the release job validates the release tag shape before it publishes anything' );
my $guard_index = -1;
my $create_index = -1;
for my $i ( 0 .. $#release_step_list ) {
    my $run = $release_step_list[$i]{run} // '';
    $guard_index  = $i if $guard_index < 0  && $run =~ /RELEASE_TAG/ && $run =~ /exit\s+1/;
    $create_index = $i if $create_index < 0 && $run =~ /gh\s+release\s+(?:create|upload)/;
}
cmp_ok( $guard_index, '>=', 0, 'the release job has a step that refuses a malformed release tag' );
cmp_ok( $create_index, '>=', 0, 'the release job has a step that creates or uploads the release' );
cmp_ok( $guard_index, '<', $create_index,
    'the tag guard runs before the release is created, so a refused tag cannot leave a junk release behind' );

my $fuzz_workflow = _slurp('.github/workflows/fuzz-js.yml');
like( $fuzz_workflow, qr/fast-check/, 'fuzz workflow runs the fast-check property-based suite' );
like( $fuzz_workflow, qr/uses:\s*actions\/setup-node\@[0-9a-f]{40}/, 'setup-node action is pinned by full SHA in the fuzz workflow' );
like( $fuzz_workflow, qr/uses:\s*shogo82148\/actions-setup-perl\@[0-9a-f]{40}/, 'fuzz workflow installs Perl before invoking dashboard commands' );
like( $fuzz_workflow, qr/cpanm\s+--installdeps\s+--notest\s+\./, 'fuzz workflow installs the repo Perl runtime prerequisites' );

my $clusterfuzz = _slurp('.clusterfuzzlite/Dockerfile');
like( $clusterfuzz, qr/\AFROM\s+ubuntu:24\.04\@sha256:/, 'ClusterFuzzLite Dockerfile pins its base image by digest' );
like( $clusterfuzz, qr/\bcpanm\b/, 'ClusterFuzzLite Dockerfile provisions the Perl fuzz runner stack' );

my $package_json = _slurp('package.json');
like( $package_json, qr/"fast-check"\s*:/, 'package.json declares fast-check for fuzz/property testing' );

my $package_lock = _slurp('package-lock.json');
like( $package_lock, qr/"fast-check"/, 'package-lock.json locks the fast-check dependency' );

# fast-check is the whole of the project's property-based fuzzing, so Scorecard's
# Fuzzing signal rests on it staying a maintained dependency rather than merely a
# declared one. Upstream ended the 3.x line at 3.23.2 and ships only 4.x, so a
# range still floored on 3 pins the one fuzz gate to an abandoned major and makes
# the weekly Dependabot npm update a permanent no-op nobody drains. Keep both the
# declared range and the resolved lock entry on 4+, and keep them on the SAME
# major: a range that says 4 over a lock that resolves 3 would let `npm ci` - the
# command both CI and the fuzz test actually run - install the abandoned line
# while the manifest reads as current.
my ($declared_fast_check) = $package_json =~ m{"fast-check"\s*:\s*"[^\d]*(\d+)};
ok( defined $declared_fast_check, 'package.json fast-check range states a major version' )
  or diag('no numeric major found in the package.json fast-check range');
cmp_ok( $declared_fast_check // 0,
    '>=', 4, 'package.json floors fast-check on the maintained 4.x line, not the abandoned 3.x line' );

my ($locked_fast_check) =
  $package_lock =~ m{"node_modules/fast-check"\s*:\s*\{[^{}]*?"version"\s*:\s*"(\d+)};
ok( defined $locked_fast_check, 'package-lock.json records a resolved fast-check version' )
  or diag('no resolved version found for the node_modules/fast-check lock entry');
is( $locked_fast_check, $declared_fast_check,
    'package-lock.json resolves fast-check on the same major the manifest declares' );

# DD-449. Every pin in this repository is an immutable 40-hex SHA, and the
# node24-line floors above (docker/login-action, attest-build-provenance) are
# asserted FROM THE `# vX.Y.Z` COMMENT beside that SHA. That made the comment
# load-bearing while nothing ever verified it against the SHA it annotates, and
# three pins turned out to carry comments written from INTENT rather than
# resolved from the tag:
#
#   actions/checkout              said `# v5.2.2` - a tag that has never existed
#                                 upstream - over a SHA that is really v4.2.2
#   shogo82148/actions-setup-perl said `# v1.32.0` over a SHA that is v1.31.3
#                                 (and v1.32.0 is itself still node20)
#   actions/setup-node            carried no comment at all; it was v4.4.0
#
# All three declare node20. GitHub now force-runs node20 actions on node24;
# checkout survives that, actions-setup-perl v1.31.3 does not - it dies with
# "Error: unable to get latest version". So `Setup Perl` failed on every CI run
# for ten days, skipping the suite, the coverage gate AND both dependency
# audits, while this file certified the node24 migration as complete.
#
# Two lessons are encoded below. First, a floor read off a comment cannot catch
# a comment that lies - the checkout floor would have passed on `# v5.2.2`
# either way - so the authoritative check resolves each SHA against the upstream
# API and lives in script/audit-action-pins, and what is asserted here is that
# CI actually runs it. Second, the floors are still worth stating, because they
# do catch a careless pin, and they must name the version where each action
# really became node24-native rather than the major that merely sounds current:
# checkout v5.0.0, setup-node v5.0.0, and actions-setup-perl v1.37.0 (v1.36.0 is
# still node20 - verified against each action.yml's runs.using, not assumed).
my %NODE24_PIN_FLOOR = (
    'actions/checkout'              => [ 5, 0, 0 ],
    'actions/setup-node'            => [ 5, 0, 0 ],
    'shogo82148/actions-setup-perl' => [ 1, 37, 0 ],
);

my @ALL_WORKFLOWS = qw(
  .github/workflows/test.yml
  .github/workflows/release-cpan.yml
  .github/workflows/codeql.yml
  .github/workflows/package-ghcr.yml
  .github/workflows/fuzz-js.yml
  .github/workflows/release-github.yml
);

# Collect every SHA pin across the workflow set, with the version comment beside
# it when one is present, so the assertions below can reason about the pin set as
# a whole rather than one file at a time.
my %pin_labels;    # "action\@sha" => { label => [workflows...] }
for my $workflow (@ALL_WORKFLOWS) {
    my $text = _slurp($workflow);
    while ( $text =~ m{uses:\s*(\S+?)\@([0-9a-f]{40})(?:[^\S\n]+\#[^\S\n]*(v\d+(?:\.\d+){2}))?}g ) {
        my ( $action, $sha, $label ) = ( $1, $2, $3 );
        push @{ $pin_labels{"$action\@$sha"}{ $label // '(none)' } }, $workflow;
    }
}
ok( scalar keys %pin_labels, 'the workflow set pins actions by full SHA' );

# One action@sha must not be labelled two different ways across the workflows.
# checkout is pinned in five files and actions-setup-perl in four, so a partial
# edit that relabels some copies and not others is the most likely way for the
# comments to start disagreeing with each other again.
for my $pin ( sort keys %pin_labels ) {
    my @labels = sort keys %{ $pin_labels{$pin} };
    is( scalar @labels, 1, "$pin carries one consistent version comment across every workflow that pins it" )
      or diag( "conflicting comments for $pin: " . join( ', ', @labels ) );
}

# The node24 floors, read from the comment. These cannot catch a false comment -
# that is script/audit-action-pins' job - but they do catch a pin moved
# backwards onto a node20 line by hand.
for my $action ( sort keys %NODE24_PIN_FLOOR ) {
    my ($pin) = grep { m{\A\Q$action\E\@} } sort keys %pin_labels;
    ok( defined $pin, "$action is pinned by full SHA somewhere in the workflow set" )
      or next;
    my ($label) = sort keys %{ $pin_labels{$pin} };
    isnt( $label, '(none)', "$action pin carries an auditable vX.Y.Z comment beside its SHA" )
      or next;
    my @have  = ( $label =~ m{\Av(\d+)\.(\d+)\.(\d+)\z} );
    my @floor = @{ $NODE24_PIN_FLOOR{$action} };
    my $ok    = 0;
    for my $i ( 0 .. 2 ) {
        next if $have[$i] == $floor[$i];
        $ok = $have[$i] > $floor[$i];
        last;
    }
    $ok = 1 if !$ok && "@have" eq "@floor";
    ok( $ok, "$action is pinned on the node24-native $label line (floor v" . join( '.', @floor ) . ')' )
      or diag("$action is pinned at $label, below the release where it became node24-native");
}

# The authoritative half: the comment is only trustworthy because something
# resolves it against the SHA on every push. Assert the gate is wired into CI,
# not merely present in script/. It runs after the dependency install because it
# needs the project's own LWP::UserAgent and JSON::XS.
my $pin_audit_gate = 'script/audit-action-pins';
ok( -f File::Spec->catfile( $ROOT, split m{/}, $pin_audit_gate ), 'the action-pin provenance audit exists' );
ok( _git_tracks($pin_audit_gate), 'the action-pin provenance audit is tracked in git' );
my $test_workflow = _slurp('.github/workflows/test.yml');
like( $test_workflow, qr/\Q$pin_audit_gate\E/,
    'CI resolves every action pin against its upstream tag, so a version comment cannot stay false' );

for my $workflow (@ALL_WORKFLOWS) {
    my $text = _slurp($workflow);
    like( $text, qr/^permissions:\s*$/m, "$workflow declares an explicit permissions block" );
    like( $text, qr/^concurrency:\s*$/m, "$workflow declares an explicit concurrency block" );
    like( $text, qr/^\s*timeout-minutes:\s*\d+\s*$/m, "$workflow sets an explicit timeout to avoid hung jobs" );
    unlike( $text, qr/uses:\s*[^@\s]+\@[Vv]?\d+(?:\.\d+)*(?:\s|$)/, "$workflow does not use floating action tags" );
    unlike( $text, qr/curl\s+-L\s+https:\/\/cpanmin\.us\s*\|\s*perl/, "$workflow does not install cpanm via curl pipe" );
}

my $release_cpan_workflow = _slurp('.github/workflows/release-cpan.yml');
like( $release_cpan_workflow, qr/Developer-Dashboard-\*\.tar\.gz/, 'PAUSE release workflow locates dzil tarballs from the repo root instead of a nonexistent .build tree' );
unlike( $release_cpan_workflow, qr/\.build\/\*\.tar\.gz/, 'PAUSE release workflow no longer looks for tarballs under a nonexistent .build directory' );
like(
    $release_cpan_workflow,
    qr/script\/coverage-gate/,
    'PAUSE release workflow enforces the same all-metric lib coverage gate as the main CI workflow',
);

for my $coverage_workflow (
    qw(
    .github/workflows/test.yml
    .github/workflows/release-cpan.yml
    .github/workflows/release-github.yml
    )
  )
{
    my $text = _slurp($coverage_workflow);
    like(
        $text,
        qr/perl script\/coverage-gate/,
        "$coverage_workflow runs the canonical coverage-gate entrypoint",
    );
    unlike(
        $text,
        qr/cover -delete/,
        "$coverage_workflow does not open-code a coverage chain whose environment could be split",
    );
    unlike(
        $text,
        qr/grep [-A-Za-z]+ ['"]\^?Total/,
        "$coverage_workflow does not gate coverage on a brittle Total-line grep",
    );
}

# The metric set moved out of the workflows and into the one entrypoint they all
# call, so the guarantee has to be re-pinned where it now lives: relocating a
# gate must not be a way to quietly weaken it.
{
    my $entrypoint = _slurp('script/coverage-gate');
    for my $metric (qw(statement branch condition subroutine)) {
        like( $entrypoint, qr/'\Q$metric\E'/, "the canonical coverage entrypoint collects $metric coverage" );
    }
    like( $entrypoint, qr/\^lib\//,                   'the canonical coverage entrypoint restricts the report to lib/' );
    like( $entrypoint, qr/check-all-metric-coverage/, 'the canonical coverage entrypoint enforces the report through the fail-closed checker' );
}

my $blank_env_dockerfile = _slurp('integration/blank-env/Dockerfile');
like(
    $blank_env_dockerfile,
    qr/\AFROM\s+perl:5\.44-bookworm\@sha256:[0-9a-f]{64}\b/,
    'blank-env Dockerfile pins the Debian perl:5.44-bookworm base image by digest for dependency hygiene',
);

done_testing;

sub _git_tracks {
    my ($path) = @_;
    my ( $stdout, $stderr, $exit ) = capture {
        system( 'git', '-C', $ROOT, 'ls-files', '--error-unmatch', $path );
    };
    return $exit == 0;
}

sub _slurp {
    my ($relative_path) = @_;
    my $path = File::Spec->catfile( $ROOT, split m{/}, $relative_path );
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

__END__

=pod

=head1 NAME

t/34-scorecard-guardrails.t - enforce repository-side Scorecard guardrails

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the repository-side Scorecard and workflow guardrails. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because the repository-side Scorecard and workflow guardrails has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing the repository-side Scorecard and workflow guardrails, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/34-scorecard-guardrails.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/34-scorecard-guardrails.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/34-scorecard-guardrails.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
