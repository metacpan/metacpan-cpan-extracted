#!/usr/bin/perl
use strict;

use Test::More tests => 7;

use Linux::Bootloader::Detect;

ok ( Linux::Bootloader::Detect::detect_architecture(), "Detecting Architecture" );
ok ( Linux::Bootloader::Detect::detect_architecture("linux"), "Force 'linux' architecture check" );
ok ( Linux::Bootloader::Detect::detect_architecture("gentoo"), "Force 'gentoo' architecture check" );
ok ( Linux::Bootloader::Detect::detect_architecture("foo"), "Force default architecture check" );

my @bootloaders = Linux::Bootloader::Detect::detect_bootloader_from_conf();
ok ( @bootloaders, "Detecting Bootloader: checking for a config file");
ok ( Linux::Bootloader::Detect::detect_bootloader_from_mbr(), "Detecting Bootloader: scaning MBR");
ok ( Linux::Bootloader::Detect::detect_bootloader(), "Detecting Bootloader: check for either the config file or scan the MBR" );
