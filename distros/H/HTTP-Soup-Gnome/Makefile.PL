use strict;
use warnings;

use ExtUtils::MakeMaker;

use Cwd;
use File::Spec;
use Data::Dumper;


sub main {
	# Create the Makefile
	my @args = (
		AUTHOR        => 'Emmanuel Rodriguez <potyl@cpan.org>',
		NAME          => 'HTTP::Soup::Gnome',
		VERSION_FROM  => File::Spec->catfile('lib', 'HTTP', 'Soup', 'Gnome.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'HTTP', 'Soup', 'Gnome.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => {
			'Glib::Object::Introspection' => 0,
		},

		META_MERGE => {
			resources => {
				homepage    => 'https://github.com/potyl/perl-HTTP-Soup-Gnome',
				bucktracker => 'https://github.com/potyl/perl-HTTP-Soup-Gnome/issues',
				repository  => 'https://github.com/potyl/perl-HTTP-Soup-Gnome',
			},
		},
	);
	WriteMakefile(@args);


	return 0;
}


exit main() unless caller;

