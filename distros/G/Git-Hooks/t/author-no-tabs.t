
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
    'lib/Git/Hooks.pm',
    'lib/Git/Hooks/CheckAcls.pm',
    'lib/Git/Hooks/CheckCommit.pm',
    'lib/Git/Hooks/CheckFile.pm',
    'lib/Git/Hooks/CheckJira.pm',
    'lib/Git/Hooks/CheckLog.pm',
    'lib/Git/Hooks/CheckReference.pm',
    'lib/Git/Hooks/CheckRewrite.pm',
    'lib/Git/Hooks/CheckWhitespace.pm',
    'lib/Git/Hooks/GerritChangeId.pm',
    'lib/Git/Hooks/Notify.pm',
    'lib/Git/Hooks/PrepareLog.pm',
    'lib/Git/Hooks/Test.pm',
    'lib/Git/Hooks/Tutorial.pod',
    'lib/Git/Message.pm',
    'lib/Git/Repository/Plugin/GitHooks.pm',
    't/00-load.t',
    't/01-setup.t',
    't/02-check-acls.t',
    't/02-check-commit.t',
    't/02-check-file.t',
    't/02-check-jira.t',
    't/02-check-log.t',
    't/02-check-reference.t',
    't/02-check-rewrite.t',
    't/02-check-whitespace.t',
    't/02-externals.t',
    't/02-gerrit-change-id.t',
    't/02-noplugin.t',
    't/02-notify.t',
    't/02-prepare-log.t',
    't/author-critic.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/make-debug-environment.sh',
    't/release-kwalitee.t',
    't/release-unused-vars.t',
    't/setup-vagrant-environment.sh'
);

notabs_ok($_) foreach @files;
done_testing;
