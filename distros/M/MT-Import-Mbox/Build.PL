# $Id: Build.PL,v 1.5 2005/12/03 19:12:19 asc Exp $

use strict;
use Module::Build;

my $build = Module::Build->new(module_name => 'MT::Import::Mbox',
			       # dist_author
			       # dist_abstract
			       dist_version_from => 'lib/MT/Import/Mbox.pm',
			       license           => 'perl',
			       requires => {
                                            'MT::Import::Base' => '>= 1.01',
                                            'Digest::MD5'      => '',
                                            'Email::Folder'    => '',
                                            'Email::Find'      => '',
                                            'Email::MIME'      => '',
                                            'File::Find::Rule' => '',
                                            'File::Temp'       => '',
                                           },
			       build_requires => {
                                                  'Test::Simple' => '>= 0.47',
                                                 },
			       create_readme      => 1,
			       create_makefile_pl => 'passthrough');

$build->create_build_script();
