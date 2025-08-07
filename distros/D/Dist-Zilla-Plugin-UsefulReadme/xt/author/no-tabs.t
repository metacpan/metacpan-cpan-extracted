use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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
    't/11-pod-weaver-plugins.t'
);

notabs_ok($_) foreach @files;
done_testing;
