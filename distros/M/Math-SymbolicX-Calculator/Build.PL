use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::SymbolicX::Calculator',
   dist_author => 'Steffen Mueller <smueller@cpan.org>',
   license => 'perl',
   requires => {
       'Math::Symbolic' => '0.501',
       'Math::Symbolic::Custom::Transformation' => '1.24',
       'Params::Util' => '0',
       'Carp' => '0',
               },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
  );

$b->create_build_script;

