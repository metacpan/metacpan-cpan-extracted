use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::Orthonormalize',
   dist_author => 'Steffen Mueller <orthonormalize-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Math::Symbolic' => '0.128',
                'Parse::RecDescent' => '1.8',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
#   conflicts => {},
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
   sign => 1,
  );

$b->create_build_script;

