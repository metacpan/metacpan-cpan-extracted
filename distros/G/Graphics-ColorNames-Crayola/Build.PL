use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Graphics::ColorNames::Crayola',
     license => 'unrestricted',
     requires => {
       'perl'                       => '5.6.0',
       'Graphics::ColorNames'       => '2.10',
     },
     recommends => {
     },
     build_requires => {
       'Test::More'                 => 0,
     },
     create_readme      => 1,
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
