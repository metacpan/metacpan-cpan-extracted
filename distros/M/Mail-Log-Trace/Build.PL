use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Mail::Log::Trace',
      license         => 'perl',
      dist_author     => 'Daniel Staal - <DStaal@usa.net>',
      dist_abstract   => 'Traces a message through the mailsystem.',
      create_makefile_pl => 'passthrough',
      create_readme   => 1,
      dynamic_config  => 0,
      requires        =>    {
			    'perl'      => '5.6.1',
			    'Mail::Log::Exceptions' => 1.0100,
			    'Mail::Log::Parse::Postfix' => 1.04,
			    'Scalar::Util'  => 0,
			    },
      build_requires  =>    {
			    'Module::Build'     => 0,
			    'Test::Warn'        => 0,
			    'Test::Exception'   => 0,
			    'Test::Deep'        => 0,
			    'Time::Local'       => 0,
			    },
      recommends      =>    {
			    
			    },
      recursive_test_files  => 0,
    )->create_build_script;
