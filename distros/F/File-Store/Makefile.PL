use ExtUtils::MakeMaker;

WriteMakefile (
	NAME		=> 'File::Store',
	VERSION_FROM	=> 'lib/File/Store.pm',
	DISTNAME	=> "File-Store",
	dist		=> {COMPRESS => 'gzip', SUFFIX => 'gz'},
);

