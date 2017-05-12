use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Log::Dispatch::DBI',
    'VERSION_FROM' => 'lib/Log/Dispatch/DBI.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	DBI => 0,
	Log::Dispatch => 2.0,
	DBD::CSV => 0,		# for testing
	File::Temp => 0.12,
    },
);
