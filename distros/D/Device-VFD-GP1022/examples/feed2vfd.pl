use strict;
use warnings;
use lib 'lib';
use utf8;

use Device::VFD::GP1022;
use Device::VFD::GP1022::Message;
use XML::Feed;
use URI;


my $vfd = Device::VFD::GP1022->new('/dev/ttyUSB0');

sub scroll_wait {
    while ($vfd->is_scroll) {}
}

my $feed;
while (1) {
    my $feed_get = eval {
        XML::Feed->parse(URI->new($ARGV[0]))  or die XML::Feed->errstr;
    };
    $feed = $feed_get unless $@;
    while (1) {
        scroll_wait;
        $vfd->message($feed->title);
        for my $entry ($feed->entries) {
            scroll_wait;
            $vfd->message($entry->title);
        }
    }
}

