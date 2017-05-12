use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/File/ChangeNotify.pm',
    'lib/File/ChangeNotify/Event.pm',
    'lib/File/ChangeNotify/Watcher.pm',
    'lib/File/ChangeNotify/Watcher/Default.pm',
    'lib/File/ChangeNotify/Watcher/Inotify.pm',
    'lib/File/ChangeNotify/Watcher/KQueue.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all.t',
    't/excluded-dirs.t',
    't/instantiate-twice.t',
    't/lib/File/ChangeNotify/TestHelper.pm'
);

notabs_ok($_) foreach @files;
done_testing;
