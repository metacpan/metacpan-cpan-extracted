# Pragmas.
use strict;
use warnings;

# Modules.
use Dicom::File::Detect qw(dicom_detect_file);
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $ret = dicom_detect_file($data_dir->file('ex1.dcm')->s);
is($ret, 0, 'No DICOM file.');

# Test.
$ret = dicom_detect_file($data_dir->file('ex2.dcm')->s);
is($ret, 1, 'The smallest DICOM file.');

# Test.
eval {
	dicom_detect_file('Foo');
};
is($EVAL_ERROR, "Cannot open file 'Foo'.\n", "Cannot open file 'Foo'.");
clean();
