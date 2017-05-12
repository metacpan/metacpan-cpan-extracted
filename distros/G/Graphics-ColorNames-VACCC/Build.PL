use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Graphics::ColorNames::VACCC',
     license => 'perl',
     requires => {
       'perl'                       => '5.6.0',
       'Graphics::ColorNames'       => 1.01,
     },
     recommends => {
     },
     build_requires => {
       'Test'                       => 0,
     },
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
