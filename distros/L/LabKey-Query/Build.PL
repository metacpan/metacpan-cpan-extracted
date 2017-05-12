use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( 
    module_name     => 'LabKey::Query',	
	#dist_author => 'Ben Bimber',
	requires => {
                 'LWP::UserAgent' => 0,
                 'HTTP::Request' => 0,
                 'Data::Dumper' => 0,
                 'JSON' => 2,
                 'File::Spec' => 0,
                 'File::HomeDir' => 0,
                 'FileHandle' => 0,
                 'URI' => 0,
                 'Carp' => 0,
                 'IO::Socket::SSL' => 0
               },	
	dist_abstract => 'For interacting with data in LabKey Server',
    )->create_build_script;
