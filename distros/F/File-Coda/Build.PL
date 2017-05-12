#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $b = new Module::Build
  (
   module_name => 'File::Coda',
   license => 'gpl',
   dist_author => 'Jim Meyering <jim@meyering.net>',
   dist_abstract => 'a global destructor to close stdout carefully',

   # No point in putting Coda.pm two levels down in the tree.
   pm_files => { 'Coda.pm' => 'lib/File/Coda.pm' },
   # But once we've done that, we have to tell this tool where to find the
   # VERSION number.  You'd think it could guess, given the mapping in pm_files.
   dist_version_from => 'Coda.pm',

   sign => 1,
   build_requires => {
      'Test::Pod' => 0,
      'Test::Pod::Coverage' => 0,
   },
  );
$b->create_build_script;
