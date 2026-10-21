use ExtUtils::MakeMaker;

WriteMakefile(
	'VERSION_FROM' => 'lib/File/Slurp/Remote.pm',
	'NAME' => 'File::Slurp::Remote',
	'ABSTRACT' => 'Easy read/write of remote files',
	'AUTHOR'   => [
		'David Muir Sharnoff <muir@idiom.org>',
		'Nigel Horne <nhorne@nigelhorne.com>',
	],
	'LICENSE' => 'gpl_2',
	'MIN_PERL_VERSION' => '5.008',
	clean		=> { FILES => 'File-Slurp-Remote-*' },
	'dist' => { COMPRESS=>'gzip', SUFFIX=>'gz' },
	PREREQ_PM => {
		'Carp'			=> 0,
		'Exporter'		=> 0,
		'File::Slurp'		=> 0,
		'POSIX'			=> 0,
		'Socket'		=> 0,
		'Sys::Hostname::FQDN'	=> 0,
		'Tie::Hash'		=> 0,
	},
	TEST_REQUIRES => {
		'File::Temp'		=> 0,
		'FindBin'		=> 0,
		'Test::More'		=> '0.88',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		license => [ 'gpl_2' ],
		resources => {
			license => [
				'https://www.perlfoundation.org/artistic-license-20.html',
				'https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html',
			],
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/File-Slurp-Remote.git',
				web => 'https://github.com/nigelhorne/File-Slurp-Remote',
			}, bugtracker => {
				web => 'https://github.com/nigelhorne/File-Slurp-Remote/issues',
			},
		},
	},
);
