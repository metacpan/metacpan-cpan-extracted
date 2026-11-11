
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Conformance.pm',
    'lib/Dist/Conformance/Check.pm',
    'lib/Dist/Conformance/Check/ClaudeMd.pm',
    'lib/Dist/Conformance/Check/ClaudeSettings.pm',
    'lib/Dist/Conformance/Check/CriticProfile.pm',
    'lib/Dist/Conformance/Check/DataSchema.pm',
    'lib/Dist/Conformance/Check/DistFiles.pm',
    'lib/Dist/Conformance/Check/GitHooks.pm',
    'lib/Dist/Conformance/Check/RefusedIniKeys.pm',
    'lib/Dist/Conformance/Check/SystemPackages.pm',
    'lib/Dist/Conformance/Check/ToolConfiguration.pm',
    'lib/Dist/Conformance/Check/Workflows.pm',
    'lib/Dist/Conformance/Config.pm',
    'lib/Dist/Conformance/Flavor.pm',
    'lib/Dist/Conformance/Schema.pm',
    'lib/Dist/Conformance/Snapshot.pm',
    'lib/Dist/Conformance/Snapshot/Directory.pm',
    'lib/Dist/Conformance/Snapshot/Tree.pm',
    'lib/Dist/Conformance/Source.pm',
    'lib/Dist/Conformance/Source/Directory.pm',
    'lib/Dist/Conformance/Source/Git.pm',
    'lib/Dist/Conformance/Update.pm',
    'script/conformance',
    't/00-compile.t',
    't/Dist-Conformance-Check-ClaudeMd.t',
    't/Dist-Conformance-Check-ClaudeSettings.t',
    't/Dist-Conformance-Check-CriticProfile.t',
    't/Dist-Conformance-Check-DataSchema.t',
    't/Dist-Conformance-Check-DistFiles.t',
    't/Dist-Conformance-Check-GitHooks.t',
    't/Dist-Conformance-Check-RefusedIniKeys.t',
    't/Dist-Conformance-Check-SystemPackages.t',
    't/Dist-Conformance-Check-ToolConfiguration.t',
    't/Dist-Conformance-Check-Workflows.t',
    't/Dist-Conformance-Check.t',
    't/Dist-Conformance-Config.t',
    't/Dist-Conformance-Flavor.t',
    't/Dist-Conformance-Schema.t',
    't/Dist-Conformance-Snapshot-Directory.t',
    't/Dist-Conformance-Snapshot-Tree.t',
    't/Dist-Conformance-Snapshot.t',
    't/Dist-Conformance-Source-Directory.t',
    't/Dist-Conformance-Source-Git.t',
    't/Dist-Conformance-Source.t',
    't/Dist-Conformance-Update.t',
    't/Dist-Conformance.t',
    't/author-critic.t',
    't/author-distmeta.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-syntax.t',
    't/author-synopsis.t',
    't/author-test-version.t',
    't/conformance.t',
    't/data/standards/conformance/github-ci.yml',
    't/data/standards/conformance/troglodyne-5.040.yml',
    't/data/standards/conformance/troglodyne-compat.yml',
    't/data/standards/conformance/troglodyne-service.yml',
    't/data/standards/conformance/troglodyne.yml',
    't/data/standards/templates/CLAUDE.md',
    't/data/standards/templates/Changes',
    't/data/standards/templates/perlcriticrc',
    't/data/standards/templates/perlcriticrc.compat',
    't/data/standards/templates/perltidyrc',
    't/data/standards/templates/pod_stopwords',
    't/data/standards/templates/post-commit',
    't/data/standards/templates/pre-commit',
    't/data/standards/templates/preferred_modules.ini',
    't/data/standards/templates/prereqs.yml',
    't/data/standards/templates/tests-covering-map',
    't/data/standards/templates/weaver.ini',
    't/data/standards/templates/workflows/ci.yml',
    't/lib/Fixture.pm',
    't/release-cpan-changes.t',
    't/release-dist-manifest.t',
    't/release-kwalitee.t',
    't/release-meta-json.t',
    't/release-unused-vars.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
