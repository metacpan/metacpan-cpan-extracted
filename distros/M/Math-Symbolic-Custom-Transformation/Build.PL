use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::Symbolic::Custom::Transformation',
   dist_author => 'Steffen Mueller <symbolic-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Math::Symbolic' => '0.507',
                'Math::Symbolic::Custom::Pattern' => '1.20',
               },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
  );

$b->create_build_script;

