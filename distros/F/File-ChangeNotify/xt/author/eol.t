use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
