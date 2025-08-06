
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
    'lib/Dist/Zilla/Plugin/UsefulReadme.pm',
    'lib/Pod/Weaver/Section/InstallationInstructions.pm',
    'lib/Pod/Weaver/Section/RecentChanges.pm',
    'lib/Pod/Weaver/Section/Requirements.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-default.t',
    't/02-parser_class.t',
    't/03-markdown.t',
    't/04-gfm.t',
    't/05-section.t',
    't/06-version.t',
    't/07-blank-changes.t',
    't/08-utf8.t',
    't/09-pod.t',
    't/10-stopwords.t',
    't/11-pod-weaver-plugins.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-mixed-unicode-scripts.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-linkcheck.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/etc/perlcritic.rc',
    't/release-dist-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
