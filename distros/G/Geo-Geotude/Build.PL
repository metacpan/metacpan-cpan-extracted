# $Id: Build.PL,v 1.1 2007/07/12 05:17:22 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Geo::Geotude',
			       # dist_author
			       dist_abstract => 'foo',
			       dist_version_from => 'lib/Geo/Geotude.pm',
			       license           => 'perl',
			       requires => {
                                            'Memoize' => '0',
                                            'POSIX'   => '0',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
