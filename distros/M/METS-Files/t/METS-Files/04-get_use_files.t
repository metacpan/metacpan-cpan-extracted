use strict;
use warnings;

use File::Object;
use METS::Files;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $mets_data = slurp($data->file('ex1.mets')->s);
my $obj = METS::Files->new(
	'mets_data' => $mets_data,
);
my @ret = $obj->get_use_files('Images');
is_deeply(
	\@ret,
	[
		'file://./003855/003855r.tif',
		'file://./003855/003855v.tif',
	],
	"Get files from 'ex1.mets' (Images).",
);
@ret = $obj->get_use_files('PDF');
is_deeply(
	\@ret,
	[
		'file://./003855/003855r.pdf',
		'file://./003855/003855v.pdf',
	],
	"Get files from 'ex1.mets' (PDF).",
);

# Test.
$mets_data = slurp($data->file('ex2.mets')->s);
$obj = METS::Files->new(
	'mets_data' => $mets_data,
);
@ret = $obj->get_use_files('Images');
is_deeply(
	\@ret,
	[
		'file://./003855/003855r.tif',
		'file://./003855/003855v.tif',
	],
	"Get files from 'ex2.mets' (Images).",
);
@ret = $obj->get_use_files('PDF');
is_deeply(
	\@ret,
	[
		'file://./003855/003855r.pdf',
		'file://./003855/003855v.pdf',
	],
	"Get files from 'ex2.mets' (PDF).",
);
