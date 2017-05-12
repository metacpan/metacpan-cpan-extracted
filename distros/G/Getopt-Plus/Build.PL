use Module::Build qw( );

my $build = Module::Build->new
  (module_name   => 'Getopt::Plus',
   dist_version  => '0.99',
   license       => 'perl',
   requires      => {
                     Class::MethodMaker => '1.04',
                     IPC::Run           => '0.44',
                     List::Util         => '1.06',
                     Log::Info          => '1.13',
                     Pod::Usage         => '1.12',
                    },
   build_requires=> {
                     IPC::Run => '0.44',
                    },
  );

$build->create_build_script;
