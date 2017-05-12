use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::SymbolicX::Inline',
   dist_author => 'Steffen Mueller <smueller@cpan.org>',
   license => 'perl',
   requires => {
        Math::Symbolic => 0.129,
        Math::Symbolic::Custom::Contains => 0.10,
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   conflicts => {},
#   script_files => [],
  );

$b->create_build_script;

