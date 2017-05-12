#!/usr/bin/perl
use Config; # before strict...
use strict;
use warnings;

use Module::Build;

my %yml_files = map { $_ => "lcfgbuild/$_" }
    qw(lcfg_config.yml mapping_config.yml);

my %tmpl_files = map { $_ => "lcfgbuild/$_" }
    ( glob('templates/*.tt'), glob('templates/*.tmpl') );

my $lcfgbuild_dir;
if ( $Config{osname} eq 'darwin' ) {
  $lcfgbuild_dir = '/usr/local/share/lcfgbuild';

  # Use a different MacOSX specific version of the lcfg config
  delete $yml_files{"lcfg_config.yml"};
  $yml_files{"lcfg_config_osx.yml"} = "lcfgbuild/lcfg_config.yml";
} else {
  $lcfgbuild_dir = '/usr/share/lcfgbuild';
}

my $build = Module::Build->new(
    module_name   => 'LCFG::Build::Tools',
    dist_abstract => 'LCFG build system tools',
    dist_author   => 'Stephen Quinney <squinney@inf.ed.ac.uk>',
    dist_version  => '0.6.6',
    license => 'gpl',
    requires => {
        'perl'                 => '5.6.1',
        'Archive::Tar'         => '0',
        'DateTime'             => '0',
        'File::HomeDir'        => '0.58',
        'File::Find::Rule'     => '0',
        'IO::Zlib'             => '0',
        'LCFG::Build::PkgSpec' => '0.1.0',
        'LCFG::Build::VCS'     => '0.0.19',
        'Module::Pluggable'    => '3.10',
        'Moose'                => '0.57',
        'MooseX::App::Cmd'     => '0.06',
        'Template'             => '2.14',
        'Readonly'             => '0',
        'UNIVERSAL::require'   => '0',
        'YAML::Syck'           => '0.98',
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
    },
    configure_requires => { 'Module::Build' => 0.38 },
    add_to_cleanup => [ 'LCFG-Build-Tools-*', 'MANIFEST.bak', 'Changes.bak' ],
    create_makefile_pl => 'traditional',
    yml_files    => \%yml_files,
    tmpl_files   => \%tmpl_files,
    install_path => { lcfgbuild => $lcfgbuild_dir },
);
$build->add_build_element('yml');
$build->add_build_element('tmpl');
$build->create_build_script;
