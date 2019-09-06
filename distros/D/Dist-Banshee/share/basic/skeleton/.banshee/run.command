#! perl

use strict;
use warnings;

use Dist::Banshee::Core qw/source write_files in_tempdir/;

my $files = source('gather-files');

in_tempdir {
	write_files($files);

	system $^X, 'Makefile.PL';
	system 'make';

	system @ARGV;
};

0;
