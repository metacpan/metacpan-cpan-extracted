#!/usr/bin/env perl
# Unit test for cdtext.
use Test::More; # 'no_plan';

use strict;
use warnings;

use lib '../lib';
use blib;

use File::Basename;
use Device::Cdio::Device;
use perlcdio;

no warnings;
is(perlcdio::cdtext_field2str($perlcdio::CDTEXT_FIELD_PERFORMER),
   "PERFORMER");

# Test getting CD-Text
my $tocpath = File::Spec->catfile(dirname(__FILE__), '..', 'data', 'cdtext-test.toc');
my $device = Device::Cdio::Device->new($tocpath, $perlcdio::DRIVER_CDRDAO);
ok($device, "Able to find CDRDAO driver for cdtext.toc");

my $langs =  $device->cdtext_list_languages ();
is(scalar(@$langs), 4, "Retrieving CD-Text languages");
is($langs->[0], $perlcdio::CDTEXT_LANGUAGE_ENGLISH, "First Language is English");

my $text = $device->get_disc_cdtext();
is($text->{$perlcdio::CDTEXT_FIELD_PERFORMER}, 'Performer');
is($text->{$perlcdio::CDTEXT_FIELD_DISCID}, 'XY12345');
$text = $device->cdtext_field_for_track($perlcdio::CDTEXT_FIELD_TITLE, 1);
is($text, 'Track Title');
my $text = $device->cdtext_field_for_disc($perlcdio::CDTEXT_FIELD_TITLE);
is($text, 'CD Title');

$device->close();
done_testing();
