use Module::Build;
my $build = Module::Build->new
(
     module_name => 'Log::Log4perl::Appender::Spread',
     license => 'perl',
     create_makefile_pl => 'traditional',
     requires => {
                  'perl'           => '5.6.1',
                  'Spread'         => '>= 3.17',
                 },
);

$build->create_build_script;
