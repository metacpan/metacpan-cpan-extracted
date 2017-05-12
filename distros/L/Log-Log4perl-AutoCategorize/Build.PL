use Module::Build;

my $build = new Module::Build
    (
     module_name => 'Log::Log4perl::AutoCategorize',
     license => 'perl',
     requires => {
	 perl		=> '5.8.0',
         B::Generate	=> 0, # defined on behalf of optimizer, which forgot to do so
         optimizer	=> 0,
     },
     recommends => {
       Devel::Size => 0,
     },
     );
$build->create_build_script;
