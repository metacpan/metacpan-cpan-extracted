use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Mail::Audit::Centipaid',
    'VERSION_FROM' => 'Centipaid.pm', # finds $VERSION
	'PREREQ_PM' => {
		'Mail::Audit' => 0,
		'IO::Socket' => 0,
		'Net::hostent' => 0
	}
);
