use 5.006001;
use ExtUtils::MakeMaker;


my %prereq = ( );

$prereq{'Win32::SerialPort'} = 0 if $^O eq 'MSWin32';

# If not windows assume Device::SerialPort will work

$prereq{'Device::SerialPort'} = 0 if $^O ne 'MSWin32';

WriteMakefile(
	NAME		=> "Hardware::PortScanner",
	VERSION_FROM	=> 'PortScanner.pm',
	PM => {'PortScanner.pm' => '$(INST_LIBDIR)/PortScanner.pm'},
	'dist'		=> {
			     COMPRESS	=> 'gzip -9f',
	      		     SUFFIX	=> 'gz',
	      		     DIST_DEFAULT => 'all tardist',
			   },
	MAN3PODS	=> {},

    PREREQ_PM       => { %prereq },
	LICENSE => 'perl',
    ABSTRACT_FROM   => "PortScanner.pm",
    AUTHOR          => 'John Dennis <jdennis30064@galileotech.com>',

);
