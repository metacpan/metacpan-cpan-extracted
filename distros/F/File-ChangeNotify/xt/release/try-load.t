use strict;
use warnings;

use Test::More;

use File::ChangeNotify;

## no critic (Subroutines::ProtectPrivateSubs)
ok(
    File::ChangeNotify::_try_load('File::ChangeNotify::Watcher::Default'),
    'can load Default watcher'
);

ok(
    File::ChangeNotify::_try_load('File::ChangeNotify::Watcher::Inotify'),
    'can load Inotify watcher'
);

ok(
    !File::ChangeNotify::_try_load('File::ChangeNotify::Watcher::KQueue'),
    'cannot load KQueue watcher'
);

done_testing();
