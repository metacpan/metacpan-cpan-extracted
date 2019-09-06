#! perl
use strict;
use warnings;

use Dist::Banshee::Core qw/source write_file bump_version/;
use Dist::Banshee::Git qw/commit_files/;
use Dist::Banshee::MakeMaker::Simple 'makemaker_simple';
use Getopt::Long;
use File::Slurper 'read_binary';
use JSON::PP 'decode_json';

GetOptions(bump => \my $bump);

my @updated;
if ($bump) {
	push @updated, bump_version();
}

my $meta = source('gather-metadata');

my $files = source('gather-files');
my $config_file = catfile('.banshee', 'makemaker.json');
my $config = -f $config_file ? decode_json(read_binary($config_file)) : {};
write_file('Makefile.PL', makemaker_simple($meta, $files, $config));
push @updated, 'Makefile.PL';

if ($bump) {
	commit_files('Bump to version ' . $meta->version, @updated);
}

0;
