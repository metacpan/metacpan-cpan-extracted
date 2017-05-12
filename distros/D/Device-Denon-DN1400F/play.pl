#!/usr/bin/perl
use blib;
use strict;
use warnings;
use Data::Dumper;
use Device::Denon::DN1400F;

unlink("/tmp/dn1400f.lock");

my $player = new Device::Denon::DN1400F(
				Id			=> 0,
				SerialPort	=> '/dev/ttyS0',
					);

# $player->clear_changer_buffer;

$player->move_front; exit;
# $player->unload_discs; exit;
# $player->reset;
# $player->load_disc(0, 106);
# $player->debug;
# $player->unload_disc(0, 2);
# print join(", ", $player->changer_version), "\n";
# print join(", ", $player->loaded_discs), "\n";
# print Dumper($player->status);
# $player->drive_status(0);
# $player->drive_version(0);
# $player->drive_status_servo_onoff(0);
# print Dumper($player->drive_subcode_qchannel(0));
# $player->toc_data_long(0);
# $player->toc_data_short(0);
# $player->drive_pause(0, 1);
# $player->drive_stop(0);

# $player->drive_pause(0, 0);

# exit;

# $player->unload_discs ; sleep 22;
# $player->load_disc(0, 108); sleep 22;
$player->drive_play(0, 6);
