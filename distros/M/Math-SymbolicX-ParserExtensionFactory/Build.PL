use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::SymbolicX::ParserExtensionFactory',
   dist_author => 'Steffen Mueller <symbolic-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
                'Memoize' => '1.01',
                'Data::Dumper' => '0',
                'Math::Symbolic' => '0.603',
                'Parse::RecDescent' => '0',
                'Text::Balanced' => '0',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
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

