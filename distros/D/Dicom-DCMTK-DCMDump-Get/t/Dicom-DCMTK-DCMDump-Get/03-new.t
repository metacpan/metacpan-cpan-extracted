# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::DCMTK::DCMDump::Get;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
eval {
	Dicom::DCMTK::DCMDump::Get->new('');
};
is($EVAL_ERROR, "Unknown parameter ''.\n", 'Bad \'\' parameter.');
clean();

# Test.
eval {
	Dicom::DCMTK::DCMDump::Get->new(
		'something' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'something'.\n",
	'Bad \'something\' parameter.');
clean();

# Test.
my $obj = Dicom::DCMTK::DCMDump::Get->new;
isa_ok($obj, 'Dicom::DCMTK::DCMDump::Get');
