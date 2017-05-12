use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Env::Path',
    'VERSION_FROM'	=> 'Path.pm', # finds $VERSION
    'EXE_FILES'		=> [ 'envpath' ],
    'PREREQ_PM'		=> {},
    'dist'		=> {
	COMPRESS => 'gzip --force --best',
	TAR	 => 'gtar',
	TARFLAGS => '--mode=u+w -cvf',
    },
);
