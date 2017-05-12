use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME				=> 'Lazy::Utils',
	VERSION_FROM		=> 'lib/Lazy/Utils.pm',
	MIN_PERL_VERSION	=> '5.010001',
	PREREQ_PM			=> {
		'JSON'			=> '2.90',
		'Pod::Simple::Text'	=> '3.26',
		'Term::ReadKey'	=> '2.33',
	},
	EXE_FILES			=> [qw(
	)],
	AUTHOR				=> 'Orkun Karaduman <orkunkaraduman@gmail.com>',
	ABSTRACT			=> 'Utility functions',
	LICENSE				=> 'gpl_3',
	META_MERGE			=> {
		'meta-spec'		=> {
			version		=> 2,
		},
		resources		=> {
			homepage	=> 'https://metacpan.org/release/Lazy-Utils',
			license		=> 'https://www.gnu.org/licenses/gpl-3.0.html',
			repository	=> {
				type	=> 'git',
				url		=> 'git://git@github.com:orkunkaraduman/Lazy-Utils.git',
				web		=> 'https://github.com/orkunkaraduman/Lazy-Utils',
			},
			bugtracker => {
				web    => 'https://github.com/orkunkaraduman/Lazy-Utils/issues',
				mailto => 'bug-Lazy-Utils@rt.cpan.org',
			},
		},
	},
);
