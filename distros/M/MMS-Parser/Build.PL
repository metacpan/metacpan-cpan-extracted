use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
   module_name       => 'MMS::Parser',
   license           => 'perl',
   dist_author       => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   dist_version_from => 'lib/MMS/Parser.pm',
   requires          => {
      'perl'              => '5.6.2',
      'version'           => 0,
      'Test::More'        => 0,
      'Path::Class'       => 0,
      'File::Slurp'       => 0,
      'Parse::RecDescent' => 0,
   },
   add_to_cleanup => ['MMS-Parser-*', 'lib/MMS/Parser/WorkHorse.pm'],
   PL_files => {'lib/MMS/Parser/WorkHorse.pm.PL' => ' ',},
);

$builder->add_build_element('prd');
$builder->add_build_element('pl');
$builder->add_build_element('.pm.PL');
$builder->create_build_script();
