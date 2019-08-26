#! perl

use strict;
use warnings;

use CPAN::Upload::Tiny 0.009;
use Dist::Banshee::Core qw/source dist_test write_tarball y_n/;

my $files = source('gather-files');

# checkchanges

dist_test($files);

if (y_n('Do you want to continue the release process?', 'n')) {
	my $meta = source('gather-metadata');

	my $trial = $meta->release_status eq 'testing' && $meta->version !~ /_/;
	my $file = write_tarball($files, $meta, $trial);

	my $uploader = CPAN::Upload::Tiny->new_from_config_or_stdin;
	$uploader->upload_file($file);

	print "Successfully uploaded $file\n";
}

0;
