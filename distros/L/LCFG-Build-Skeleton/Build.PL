use Module::Build; # -*-cperl-*-

my %ttfiles = map { $_ => $_ } glob 'templates/*.tt';

my $build = Module::Build->new(
    module_name   => 'LCFG::Build::Skeleton',
    dist_abstract => 'Tools for generating new LCFG projects',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '0.5.0',
    license => 'gpl',
    requires => {
        'perl'                 => '5.6.1',
        'LCFG::Build::PkgSpec' => '0.0.23',
        'LCFG::Build::VCS'     => '0.0.20',
        'List::MoreUtils'      => '0',
        'Moose'                => '0.57',
        'MooseX::Getopt'       => '0.13',
        'Template'             => '2.14',
        'UNIVERSAL::require'   => '0',
        'YAML::Syck'           => '0.98',
    },
    build_requires => {
        'Test::More'        => 0,
    },
    add_to_cleanup => [ 'LCFG-Build-Skeleton-*', 'MANIFEST.bak', 'Changes.bak' ],
    create_makefile_pl => 'traditional',
    tt_files => \%ttfiles,
    install_path => { templates => '/usr/share/lcfgbuild/templates' },
);
$build->add_build_element('tt');
$build->create_build_script;
