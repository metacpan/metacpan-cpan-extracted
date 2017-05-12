use Module::Build;
# See perldoc Module::Build for details of how this works

my $build = Module::Build->new
    ( module_name     => 'FSSM::SOAPClient',
      license         => 'perl',
      dist_author     => 'Mark A. Jensen',
      dist_abstract   => 'Access the Fortinbras FSSM web service',
      requires        => {
	                  perl                 => 5.008,
			  'SOAP::Lite'         => 0.69
      },
      build_requires  => {
	                 'Module::Build'       => 0,
			 'Test::Exception'     => 0,
			 'SOAP::Lite'          => 0.69
      },
      create_makefile_pl => 'passthrough'
    );
$build->notes( network => $build->y_n("Should I run network tests?", 'y'));
$build->create_build_script;
