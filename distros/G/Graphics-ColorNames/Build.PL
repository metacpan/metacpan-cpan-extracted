use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Graphics::ColorNames',
     license => 'perl',
     requires => {
       'perl'                       => '5.006',
       'base'                       => 0,
#        'AutoLoader'                 => 0,
       'Carp'                       => 0,
       'DirHandle'                  => 0,
       'Exporter'                   => 0,
       'File::Spec'                 => 0,
       'IO::File'                   => 0,
       'Module::Load'               => '0.10',
       'Module::Loaded'             => 0,
     },
     recommends => {
       'Color::Library'             => 0.02,
       'Tie::Sub'                   => 0,
       'Test::Pod::Coverage'        => 0,
       'Test::Pod'                  => 1.00,
       'Test::Portability::Files'   => 0,
       'Pod::Readme'                => 0.09,
     },
     build_requires => {
       'FileHandle'                 => 0,    # for testing
       'Test::Exception'            => 0,
       'Test::More'                 => 0,
     },
#       autosplit => [
#         'lib/Graphics/ColorNames.pm',
#       ],
     create_readme      => ($Module::Build::VERSION >= 0.2702),
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
     sign               => 0,
);

$build->create_build_script;
