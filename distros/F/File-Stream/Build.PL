use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'File::Stream',
   dist_author => 'Steffen Mueller <stream-module at steffen-mueller dot net>',
   license => 'perl',
   requires => {
	   			'Carp' => '0',
				'YAPE::Regex' => '4.00',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
   sign => 1,
#   conflicts => {},
#   script_files => [],
  );

$b->create_build_script;

