use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::Ownership::Unix',
    AUTHOR              => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
    VERSION_FROM        => 'lib/File/Ownership/Unix.pm',
    ABSTRACT_FROM       => 'lib/File/Ownership/Unix.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
	 ? ('LICENSE'=> 'perl')
	 : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Error::Helper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Ownership-Unix-*' },
	);
