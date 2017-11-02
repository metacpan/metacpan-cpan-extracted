#!/usr/bin/env perl
# Unit test for cdtext.
use Test::More 'no_plan';

use strict;
use warnings;

use lib '../lib';
use blib;

use File::Basename;
use Device::Cdio::Device;
use perlcdio;

if ($perlcdio::VERSION_NUM <= 83) {
    no warnings;
    is("PERFORMER", perlcdio::cdtext_field2str($perlcdio::CDTEXT_PERFORMER),
       "Getting CD-Text performer field");
}  else {
    no warnings;
    is(perlcdio::cdtext_field2str($perlcdio::CDTEXT_FIELD_PERFORMER),
       "PERFORMER");
}
 
# Test getting CD-Text
my $tocpath = File::Spec->catfile(dirname(__FILE__), 'cdtext.toc');
my $device = Device::Cdio::Device->new($tocpath, $perlcdio::DRIVER_CDRDAO);
ok($device, "Able to find CDRDAO driver for cdtext.toc");

if ($perlcdio::VERSION_NUM <= 83) {
    my $disctext = $device->get_track(0);
    ok($disctext, "Able to get disc CD-Text track");
    # is($disctext->get_cdtext($perlcdio::CDTEXT_PERFORMER), 'Performer');
    # is($disctext->get_cdtext($perlcdio::CDTEXT_TITLE), 'CD Title');
    # is($disctext->get_cdtext($perlcdio::CDTEXT_DISCID), 'XY12345');

    # my $track1text = $device->get_track(1)->get_cdtext();
    # is($track1text->get_cdtext($perlcdio::CDTEXT_PERFORMER), 'Performer');
    # is($track1text->get_cdtext($perlcdio::CDTEXT_TITLE), 'Track Title');
} else {
    my $text = $device->get_track_cdtext(0);
    is($text->{PERFORMER}, 'Performer');
    is($text->{TITLE}, 'CD Title');
    # is($text->get_cdtext($perlcdio::CDTEXT_FIELD_DISCID), 'XY12345');

    $text = $device->get_track_cdtext(1);
    is($text->{PERFORMER}, 'Performer');
    is($text->{TITLE}, 'Track Title');
}


