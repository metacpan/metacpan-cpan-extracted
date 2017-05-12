#
# $Id: Build.PL,v ecface00b50a 2016/01/02 17:50:23 gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabrik::Repository',
   license => 'bsd',
   dist_author => 'GomoR <gomor_at_metabrik.org>',
   dist_version_from => 'lib/Metabrik/Repository.pm',
   requires => {
      'perl' => '5.6.1',
      'Metabrik' => '1.20',
      'Cwd' => 0,
      'IPC::Run3' => 0,
      'File::Copy' => 0,
      'File::Path' => 0,
      'File::Spec' => 0,
      'POSIX' => 0,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
