use strict;
use warnings;

use Dicom::DCMTK::DCMQRSCP::Config;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Dicom::DCMTK::DCMQRSCP::Config->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Dicom::DCMTK::DCMQRSCP::Config->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Dicom::DCMTK::DCMQRSCP::Config->new;
isa_ok($obj, 'Dicom::DCMTK::DCMQRSCP::Config');

