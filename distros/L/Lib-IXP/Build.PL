#
# $Id: Build.PL 21 2015-01-20 18:26:46Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Lib::IXP',
   license => 'artistic',
   dist_author => 'GomoR <gomor_at_cpan.org>',
   dist_version_from => 'lib/Lib/IXP.pm',
   requires => {
      'perl' => '5.6.1',
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
