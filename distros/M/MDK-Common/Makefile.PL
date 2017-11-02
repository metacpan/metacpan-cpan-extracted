use ExtUtils::MakeMaker;

if (-e 'lib/MDK/Common.pm.pl') {
    system("perl lib/MDK/Common.pm.pl > lib/MDK/Common.pm");
}

WriteMakefile(
    NAME          => 'MDK::Common',
    VERSION_FROM  => 'lib/MDK/Common.pm',
    ABSTRACT_FROM => 'lib/MDK/Common.pm',
    AUTHOR        => 'Thierry Vignaud <thierry.vignaud@gmail.com>',
    LICENSE	  => 'gpl_2',
    dist	  => { COMPRESS => "xz -f" },
    PREREQ_PM     => {
	    'File::Sync' => '0',
    },
    MIN_PERL_VERSION => '5.008001',
    META_MERGE => {
	'meta-spec' => { version => 2 },
        resources => {
            repository  => {
		type => 'git',
		url =>  'git://git.mageia.org/software/perl/perl-MDK-Common',
		web =>  'http://gitweb.mageia.org/software/perl/perl-MDK-Common/',
	    },
        },
	release_status => 'stable'
    },
    MIN_PERL_VERSION => '5.008001',
);
