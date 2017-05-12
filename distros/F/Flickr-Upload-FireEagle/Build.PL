# $Id: Build.PL,v 1.4 2008/04/22 07:03:40 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Flickr::Upload::FireEagle',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Flickr/Upload/FireEagle.pm',
			       license           => 'perl',
			       requires => {
                                            'Flickr::Upload' => '>= 1.25',
                                            'Net::FireEagle' => '>= 1.0',
                                            'Image::Info' => '0',
                                            'Error' => 0,
                                            'Date::Parse' => 0,
                                            'XML::XPath' => 0,
                                            'Readonly' => '0',
                                            'Geo::Coordinates::DecimalDegrees' => '0',
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
