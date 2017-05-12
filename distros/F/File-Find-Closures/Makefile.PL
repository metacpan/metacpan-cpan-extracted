use ExtUtils::MakeMaker 6.48;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'File::Find::Closures',
	'ABSTRACT'     => 'functions you can use with File::Find',

	'VERSION_FROM' => 'lib/File/Find/Closures.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',


	'PREREQ_PM'    => {
		'File::Find'            => '0',
		'File::Spec::Functions' => '3.33',
		},

	'META_MERGE' => {
        'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:briandfoy/file-find-closures.git',
				web  => 'https://github.com/briandfoy/file-find-closures',
				},
			},
		},

	clean  => { FILES    => q|File-Find-Closures-*| },
	);
