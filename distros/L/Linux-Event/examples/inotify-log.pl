use v5.36;
use strict;
use warnings;

use Linux::Event::Kernel::Inotify;
use Linux::Event::Loop;

my $path = shift // 'log.txt';

my $loop = Linux::Event::Loop->new;
my $inotify = Linux::Event::Kernel::Inotify->new;

my $watch = $inotify->watch(
    $path,

    on_modify => sub ($event) {
        say $event->path . ' changed';
    },

    on_close_write => sub ($event) {
        say $event->path . ' finished being written';
    },

    on_delete_self => sub ($event) {
        say $event->path . ' was deleted';
    },

    on_event => sub ($event) {
        say 'mask=' . $event->mask;
    },
);

$loop->add($inotify);
$loop->run;
