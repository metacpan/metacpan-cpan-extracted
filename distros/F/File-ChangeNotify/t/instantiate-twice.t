use strict;
use warnings;

use Test::Requires {
    'Test::Without::Module' => 0,
};

use Test::More;
use Test::Without::Module qw( Linux::Inotify2 );

use File::ChangeNotify;

my $watcher1 = File::ChangeNotify->instantiate_watcher( directories => 't' );
my $watcher2 = File::ChangeNotify->instantiate_watcher( directories => 't' );

ok(
    $watcher1->does('File::ChangeNotify::Watcher'),
    'first watcher does the File::ChangeNotify::Watcher role'
);

ok(
    $watcher2->does('File::ChangeNotify::Watcher'),
    'second watcher does the File::ChangeNotify::Watcher role'
);

done_testing();
