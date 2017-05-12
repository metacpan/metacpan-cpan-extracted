# Pragmas.
use strict;
use warnings;

# Modules.
use File::Find::Rule;
use File::Find::Rule::Dicom;
use File::Object;
use Test::NoWarnings;
use Test::More 'tests' => 2;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my @ret = File::Find::Rule->dicom_file->relative->in($data_dir->s);
is_deeply(
	\@ret,
	['ex2.dcm'],
	'Get DICOM files in data directory.',
);
