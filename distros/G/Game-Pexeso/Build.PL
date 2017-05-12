#!/usr/bin/perl

use strict;
use warnings;

use inc::MyBuilder;
use File::Spec::Functions;


my %requires = (
	perl => '5.6.1',

	'Pod::Usage'            => 0,
	'Getopt::Long'          => 0,
	'Glib'                  => 0,
	'Clutter'               => '1.000',
	'Gtk2'                  => 0,
	'XML::LibXML'           => 0,
	'URI'                   => 0,
	'Class::Accessor::Fast' => 0,
	'File::Spec'            => 0,
	'FindBin'               => 0,
	'Carp'                  => 0,
	'Data::Dumper'          => 0,
	'AnyEvent::HTTP'        => 0,
	'List::Util'            => 0,
	'Math::Trig'            => 0,
);

my %configure_requires = (
	'File::Spec::Functions' => 0,
);

my $build = inc::MyBuilder->new(
	module_name       => 'Game::Pexeso',
	license           => 'perl',
	dist_author       => 'Emmanuel Rodriguez <potyl@cpan.org>',
	dist_version_from => catfile('lib', 'Game', 'Pexeso.pm'),

	# Installation files
	script_file => [ catfile('bin', 'pexeso') ],

	# Dependencies
	requires => \%requires,

	configure_requires => \%configure_requires,

	build_requires => {
		%configure_requires,
	},

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/potyl/pexeso',
			bugtracker => 'http://github.com/potyl/pexeso/issues',
			repository => 'http://github.com/potyl/pexeso',
		},
	},
);


$build->create_build_script();

