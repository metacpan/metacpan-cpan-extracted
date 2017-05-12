use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::Symbolic::Custom::Pattern',
   dist_author => 'Steffen Mueller <symbolic-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Math::Symbolic' => '0.510',
                'Clone'          => '0',
               },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   sign => 1,
#   conflicts => {},
#   script_files => [],
  );

$b->create_build_script;

