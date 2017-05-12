use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::Symbolic::Custom::Contains',
   dist_author => 'Steffen Mueller <smueller@cpan.org>',
   license => 'perl',
   requires => {
       Math::Symbolic => '0.129',
               },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   conflicts => {},
#   script_files => [],
  );

$b->create_build_script;

