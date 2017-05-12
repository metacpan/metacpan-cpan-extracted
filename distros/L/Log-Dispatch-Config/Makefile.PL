use ExtUtils::MakeMaker;

$LAST_API_CHANGE = 0.12;
eval q{require Log::Dispatch::Config};
unless ($@) {
    print <<WARN if ${Log::Dispatch::Config::VERSION} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

WARN
    ;
}

WriteMakefile(
    'NAME'      => 'Log::Dispatch::Config',
    'VERSION_FROM' => 'lib/Log/Dispatch/Config.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Log::Dispatch => 2.00,
	AppConfig => 1.52,
	IO::Scalar => 0,
	File::Temp => 0.12,
    },
);
