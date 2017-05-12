use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'File::Find::Duplicates',
	AUTHOR        => 'Tony Bowden <kasei@tmtm.com>',
	VERSION_FROM  => 'lib/File/Find/Duplicates.pm',
	ABSTRACT_FROM => 'lib/File/Find/Duplicates.pm',
	PREREQ_PM     => {
		'File::Temp'  => 0.12,
		'Digest::MD5' => 2.0,
		'Test::More'  => 0.02,
	},
);
