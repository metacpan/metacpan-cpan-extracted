use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::Symbolic',
   dist_author => 'Steffen Mueller <smueller@cpan.org>',
   license => 'perl',
   requires => {
	   			Memoize => '1.01',
				'Parse::RecDescent' => '0',
				'Data::Dumper' => '0',
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

