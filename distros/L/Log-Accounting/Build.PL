use Module::Build;
my $build = Module::Build->new
   (
      module_name => 'Log::Accounting',
     license => 'perl',
     PL_FILES => {},
    );
$build->create_build_script;
