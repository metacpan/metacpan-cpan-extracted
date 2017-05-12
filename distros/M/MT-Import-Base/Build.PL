# $Id: Build.PL,v 1.1 2005/12/01 05:33:26 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'MT::Import::Base',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/MT/Import/Base.pm',
			       license           => 'perl',
			       requires => {
                                            'Date::Parse'      => '',
                                            'Date::Format'     => '',
                                            'File::Path'       => '',
                                            'File::Spec'       => '',
                                            'Log::Dispatch'    => '',
                                           },
			       build_requires => {
                                                  'Test::Simple' => '>= 0.47',
                                                 },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
