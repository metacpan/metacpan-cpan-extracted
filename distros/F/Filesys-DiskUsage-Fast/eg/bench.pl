#!/usr/bin/perl --

use strict;
use warnings;
use Benchmark;
use File::HomeDir;

use Filesys::DiskUsage;
use Filesys::DiskUsage::Fast;
local $Filesys::DiskUsage::Fast::ShowWarnings = 0;

my $dir = shift @ARGV // File::HomeDir->my_music;
printf "dir: %s\n", $dir;

Benchmark::cmpthese -5, {
	pp => sub {
		my $total = Filesys::DiskUsage::du( { dereference => 1, "show-warnings" => 0 }, $dir );
	},
	xs => sub {
		my $total = Filesys::DiskUsage::Fast::du( $dir );
	},
};

__END__
