use strict;
use warnings;
use Test::More tests => 1;
use File::Temp;
use File::Tail::Inotify2;

my $temp    = File::Temp->new;
my $watcher = new_ok 'File::Tail::Inotify2', [
    file    => $temp->filename,
    on_read => sub {}
];
