use ExtUtils::MakeMaker;
WriteMakefile(
    INSTALLDIRS => 'perl',
    NAME	=> 'Devel::tcltkdb',
    VERSION_FROM => 'tcltkdb.pm', # finds $VERSION
    PREREQ_PM => {
	'Tcl::Tk' => 1.03
    }
);
