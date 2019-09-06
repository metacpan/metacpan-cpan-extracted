#! perl
use strict;
use warnings;

use Dist::Banshee::Mint qw/transact_update update_script update_patch keep_patches keep_config/;
use File::Spec::Functions 'catfile';
use File::Slurper 'read_binary';
use Getopt::Long;
use JSON::PP 'decode_json';

GetOptions('patches' => \my $patches);

my $data = decode_json(read_binary(catfile('.banshee', 'update.json')));
die "No update data" if not $data;

if ($patches) {
	for my $skeleton (keys %{ $data }) {
		for my $script (@{ $data->{$skeleton} }) {
			update_patch($skeleton, $script);
		}
	}
}
else {
	transact_update {
		for my $skeleton (keys %{ $data }) {
			for my $script (@{ $data->{$skeleton} }) {
				update_script($skeleton, $script);
			}
		}
		keep_patches;
		keep_config;
	};
}

0;
