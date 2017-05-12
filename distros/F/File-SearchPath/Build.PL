#!perl

use strict;
use warnings;
use Module::Build;
use File::Spec;

# Copyright (C) 2010 Science and Technology Facilities Council.
# All Rights Reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA 02111-1307,
# USA

my $file = File::Spec->catfile(File::Spec->curdir, "lib", "File",
			       "SearchPath.pm");

# Set it up.
my $build = Module::Build->new
  (
   module_name => 'File::SearchPath',
   abstract_from => $file,
   license  => 'gpl2',
   author => [
              'Tim Jenness <tjenness@cpan.org>',
             ],
   dist_version_from => $file,
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/timj/perl-File-SearchPath.git",
                             },
                 },
   configure_requires => {
                          "Module::Build" => 0.36,
                         },
   requires => {
                'File::Spec' => 0.8,
               },
   recommends => {
                  'Env::Path' => 0,
                  },
   build_requires => {
                      'Test::More' => 0,
                     },
  );

$build->create_build_script;
