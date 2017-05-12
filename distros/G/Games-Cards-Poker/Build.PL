#!/usr/bin/perl
  use Module::Build;
      Module::Build->new(
  # 'module_name'                   => 'Games::Cards::Poker',
    'dist_name'                     => 'Games-Cards-Poker',
  # 'dist_version_from'             => 'Poker.pm',
    'dist_version'                  => '1.2.565CHh5',
    'dist_abstract'                 => 'Pure Perl Poker functions',
    'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
  # 'create_readme'                 => '1',
  # 'create_makefile_pl'            => '1',
    'license'                       => 'gpl',
    'script_files'                  => {
  },
  'pm_files'                      => {
    'Poker.pm'                      => 'lib/Games/Cards/Poker.pm',
  },
  'requires'                      => {
    'Math::BaseCnv'                 => '0',
    'Algorithm::ChooseSubsets'      => '0',
  },
  )->create_build_script();