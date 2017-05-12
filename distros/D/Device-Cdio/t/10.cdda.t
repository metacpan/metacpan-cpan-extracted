#!/usr/bin/env perl
##Test functioning CD-DA

use strict;
use warnings;

BEGIN {
    chdir 't' if -d 't';
}
use lib '../lib';
use blib;

use Device::Cdio::Device;
use Test::More tests => 10;
note('Test functioning CD-DA');

my $cuefile = '../data/cdda.cue';
my $device = Device::Cdio::Device->new(-source=>$cuefile);
$device->open($cuefile);
my $result = $device->get_disc_mode();
ok(defined($result) && $result eq 'CD-DA', 'get_disc_mode');
ok($device->get_mcn() eq '0000010271955', 'get_mcn');
my $drc = $device->get_last_session();
# self.assertRaises(IOError, $device->get_joliet_level)
$result = $device->get_num_tracks();
ok($result == 1, 'get_num_tracks');
my $disc_last_lsn = $device->get_disc_last_lsn();
ok($disc_last_lsn == 302, 'get_disc_last_lsn');
my $t=$device->get_last_track();
ok(defined($t) && $t->{track} == 1, 'get_last_track');
ok(defined($t) && $t->get_last_lsn() == 301, '(track) get_last_lsn');
ok($device->get_track_for_lsn($t->get_last_lsn())->{track} == $t->{track},
   'get_track_for_lsn');
$t=$device->get_first_track();
ok($t->{track} == 1, 'get_first_track');
ok($t->get_format() eq 'audio', 'get_track_format');
ok($t->get_msf() eq "00:02:00", "get_msf");
$device->close();
