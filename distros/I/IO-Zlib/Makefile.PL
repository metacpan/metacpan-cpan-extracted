use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'IO::Zlib',
	VERSION_FROM => 'Zlib.pm',
        PREREQ_PM    => { 'Compress::Zlib' => 2.000 },
        SIGN         => 1,
        INSTALLDIRS  => $] >= 5.00903 ? 'perl' : 'site',
	dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
