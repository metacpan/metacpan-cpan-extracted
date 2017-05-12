use ExtUtils::MakeMaker;
WriteMakefile(
    INSTALLDIRS => 'perl',
    NAME	=> 'Devel::tkdb',
    VERSION_FROM => 'tkdb.pm', # finds $VERSION
    PREREQ_PM => {
	'Tcl::Tk' => 1.03
    }
);
