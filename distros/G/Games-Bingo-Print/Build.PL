# $Id$

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new( 
	dist_author       => 'Jonas B. Nielsen, <jonasbn@cpan.org>',
	dist_name         => 'Games-Bingo-Print',
	dist_version_from => 'lib/Games/Bingo/Print.pm',
    distribution_type => 'module',
    license           => 'artistic',
    recursive_test_files => 1,
    scripts => {
        'bin/bingo_print.pl' => 'bin/bingo_print.pl',
    },
	requires => { 
		'POSIX'         => 0,
		'Test::Harness' => 0,
		'Test::More'    => 0,
		'Test::Pod'     => '0.95',
		'Data::Dumper'  => 0,
		'PDFLib'		=> '0.12',
		'Games::Bingo'  => '0.09', #actually G::B::Card 0.02
		'Getopt::Long'  => 0,
	},
    no_index => {
        directory => [ 't', 'examples' ],
    },
	create_makefile_pl => 'traditional',
);

$build->create_build_script;