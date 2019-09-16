
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/File/ByLine.pm',
    'lib/File/ByLine/Object.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-Basic.t',
    't/02-Parallel.t',
    't/03-construction.t',
    't/04-attributes.t',
    't/05-write-file.t',
    't/06-append-file.t',
    't/20-github-0005.t',
    't/99-bug-zero-length-parallel.t',
    't/author-critic.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/data/1line.txt',
    't/data/3lines-with-header.txt',
    't/data/3lines.txt',
    't/data/longer-text.txt',
    't/data/perlcriticrc',
    't/data/zero.txt',
    't/release-changes_has_content.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
