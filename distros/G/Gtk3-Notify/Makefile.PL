use strict;
use warnings;

use ExtUtils::MakeMaker;

use File::Spec;
use Data::Dumper;


sub main {
	# Create the Makefile
	my @args = (
		AUTHOR        => 'Thierry Vignaud <tvignaud@cpan.org>',
		NAME          => 'Gtk3::Notify',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk3', 'Notify.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk3', 'Notify.pm'),
		LICENSE       => 'lgpl',

		PREREQ_PM     => {
			'Glib::Object::Introspection' => 0,
			'Gtk3'                        => 0,
		},

		META_MERGE => {
			'meta-spec' => { version => 2 },
			resources => {
				homepage    => 'https://github.com/soig/Gtk3-Notify',
				bucktracker => 'https://github.com/soig/Gtk3-Notify/issues',
			},

			repository  => {
				type => 'git',
				url  => 'https://github.com/soig/Gtk3-Notify.git',
				web  => 'https://github.com/soig/Gtk3-Notify',
			},
			release_status => 'stable',
		},
	);
	WriteMakefile(@args);


	return 0;
}


exit main() unless caller;

