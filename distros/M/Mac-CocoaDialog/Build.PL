use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
   module_name       => 'Mac::CocoaDialog',
   license           => 'perl',
   dist_author       => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   dist_version_from => 'lib/Mac/CocoaDialog.pm',
   requires          => {
      'Test::More'      => 0,
      'Test::Exception' => 0,
      'version'         => 0,
   },
   add_to_cleanup => ['Mac-CocoaDialog-*'],
);

$builder->create_build_script();
