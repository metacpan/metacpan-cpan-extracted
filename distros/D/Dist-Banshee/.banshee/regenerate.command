#! perl
use strict;
use warnings;

use Dist::Banshee::Core qw/source write_file bump_version/;
use Dist::Banshee::Git qw/commit_files/;
use Dist::Banshee::MakeMaker::Simple 'makemaker_simple';
use Getopt::Long;

GetOptions(bump => \my $bump);

my @updated;
if ($bump) {
	push @updated, bump_version();
}

my $meta = source('gather-metadata');

my $files = source('gather-files');
write_file('Makefile.PL', makemaker_simple($meta, $files));
push @updated, 'Makefile.PL';

if ($bump) {
	commit_files('Bump to version ' . $meta->version, @updated);
}

0;
