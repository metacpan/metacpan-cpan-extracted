# $Id: Build.PL,v 1.2 2004/03/05 14:59:31 nik Exp $

use Module::Build;
my $build = new Module::Build
(
  module_name        => 'List::PowerSet',
  license            => 'perl',
  create_makefile_pl => 'traditional',
);
$build->create_build_script;
