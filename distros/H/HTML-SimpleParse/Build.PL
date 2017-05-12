use Module::Build;

my $b = new Module::Build
  (
   module_name => 'HTML::SimpleParse',
   license => 'perl',
  );

$b->create_build_script;
