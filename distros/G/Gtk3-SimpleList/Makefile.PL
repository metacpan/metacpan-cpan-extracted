use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::Spec;


sub main {
	# Create the Makefile
	my @args = (
		AUTHOR        => 'Thierry Vignaud <tvignaud@cpan.org>',
		NAME          => 'Gtk3::SimpleList',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk3', 'SimpleList.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk3', 'SimpleList.pm'),
		LICENSE       => 'lgpl',

		'CONFIGURE_REQUIRES' => {
			'ExtUtils::MakeMaker' => '6.64'
		},
		PREREQ_PM     => {
			'Gtk3'                        => 0,
		},

		META_MERGE => {
			'meta-spec' => { version => 2 },
			resources => {
				homepage    => 'https://github.com/soig/Gtk3-SimpleList',
				bucktracker => 'https://github.com/soig/Gtk3-SimpleList/issues',
			},
			repository  => {
				type => 'git',
				url => 'https://github.com/soig/Gtk3-SimpleList.git',
				web =>  'https://github.com/soig/Gtk3-SimpleList',
			},
			release_status => 'stable',
		},
	);
	WriteMakefile(@args);


	return 0;
}


exit main() unless caller;

