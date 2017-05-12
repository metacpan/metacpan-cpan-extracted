use ExtUtils::MakeMaker;
use Config;

unless ( $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/ ) {
	warn "The module won't work on this perl, need PERL_IMPLICIT_SYS enabled\n";
	exit 0;
}

require 5.010_000;
WriteMakefile(
	NAME		=> 'File::Redirect',
	VERSION_FROM	=> 'lib/File/Redirect.pm',
	META_MERGE        => {
		resources => {
			repository => 'http://github.com/dk/File-Redirect',
		},
	},
	PREREQ_PM          => {
		'Archive::Zip'	=> 0,
	},
);
