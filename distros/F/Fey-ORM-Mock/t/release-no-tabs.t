
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Fey/ORM/Mock.pm',
    'lib/Fey/ORM/Mock/Action.pm',
    'lib/Fey/ORM/Mock/Action/Delete.pm',
    'lib/Fey/ORM/Mock/Action/Insert.pm',
    'lib/Fey/ORM/Mock/Action/Update.pm',
    'lib/Fey/ORM/Mock/Recorder.pm',
    'lib/Fey/ORM/Mock/Seeder.pm',
    'lib/Fey/Object/Mock/Schema.pm',
    'lib/Fey/Object/Mock/Table.pm'
);

notabs_ok($_) foreach @files;
done_testing;
