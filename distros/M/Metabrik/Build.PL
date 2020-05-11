#
# $Id$
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabrik',
   license => 'bsd',
   dist_author => 'GomoR <gomor_at_metabrik.org>',
   dist_version_from => 'lib/Metabrik.pm',
   requires => {
      'perl' => '5.6.1',
      'Class::Gomor' => 0,
      'Cwd' => 0,
      'Data::Dump' => 0,
      'File::Find' => 0,
      'File::HomeDir' => 0,
      'File::Path' => 0,
      'IO::All' => 0,
      'Lexical::Persistence' => 0,
      'Module::Reload' => 0,
      'PPI' => 0,
      'Term::ANSIColor' => 0,
      'Term::ReadLine::Gnu' => 0,
      'Term::Shell' => 0,
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
