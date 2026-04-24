use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/FastGlob.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/base.t',
    't/bracket-negation.t',
    't/dotfile-hiding.t',
    't/export_ok.t',
    't/exported_glob.t',
    't/glob-comparison.t',
    't/metachar-in-filenames.t',
    't/multi-component.t',
    't/opendir-warning.t',
    't/perf-push-vs-unshift.t',
    't/recursive-glob.t',
    't/tilde-fallthrough.t',
    't/wildcard-detection.t',
    't/windows-rootpat.t'
);

notabs_ok($_) foreach @files;
done_testing;
