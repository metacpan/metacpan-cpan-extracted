# $Id: Build.PL,v 1.5 2008/01/20 23:36:27 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'Flickr::Upload::Dopplr',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/Flickr/Upload/Dopplr.pm',
			       license           => 'perl',
			       requires => {
                                            'Flickr::Upload' => '>= 1.25',
                                            'Net::Dopplr' => '>= 0.2',
                                            'Image::Info' => '0',
                                            'Error' => 0,
                                            'LWP::Simple' => 0,
                                            'XML::XPath' => 0,
			       },
			       build_requires => {
				   'Test::Simple'              => '>= 0.47',
			       },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
