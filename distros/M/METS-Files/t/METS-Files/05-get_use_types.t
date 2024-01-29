use strict;
use warnings;

use File::Object;
use METS::Files;
use Perl6::Slurp qw(slurp);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Data directory.
my $data = File::Object->new->up->dir('data');

# Test.
my $mets_data = slurp($data->file('ex1.mets')->s);
my $obj = METS::Files->new(
	'mets_data' => $mets_data,
);
my @ret = $obj->get_use_types;
is_deeply(
	\@ret,
	[
		'Images',
		'PDF',
	],
	"Get types from 'ex1.mets'.",
);

# Test.
$mets_data = slurp($data->file('ex2.mets')->s);
$obj = METS::Files->new(
	'mets_data' => $mets_data,
);
@ret = $obj->get_use_types('Images');
is_deeply(
	\@ret,
	[
		'Images',
		'PDF',
	],
	"Get types from 'ex2.mets'.",
);
