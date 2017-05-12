use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $serial_module;
if ($Config{'osname'} eq "MSWin32")
{
	$serial_module = "Win32::SerialPort";
}
else
{
	$serial_module = "Device::SerialPort";
}

WriteMakefile(
	'NAME'		=> 'Device::TNC',
	'VERSION_FROM'	=> 'lib/Device/TNC.pm',
	'AUTHOR'	=> 'R Bernard Davison (bdavison@asri.org.org)',
	'ABSTRACT'	=> "A generic interface to Terminal Node Controllers (TNC's) and KISS mode TNC's",
	'PREREQ_PM'	=> {
		$serial_module		=> 0.01,
		'Data::Translate'	=> 0.2,
		'FileHandle' 		=> 2.0,
		},
);
