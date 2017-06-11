#!/usr/bin/perl
use Module::Build;
my $mbld = Module::Build->new(
# 'module_name'                   => 'Games::Cards::Poker',
  'dist_name'                     => 'Games-Cards-Poker',
# 'dist_version_from'             => 'Poker.pm',
  'dist_version'                  => '1.4',
  'dist_abstract'                 => 'Pure Perl Poker functions',
  'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
# 'create_readme'                 => '1',
# 'create_makefile_pl'            => '1', # 'traditional',
  'license'                       => 'gpl_3',
  'script_files'                  => {
  },
  'pm_files'                      => {
    'Poker.pm'                       => 'lib/Games/Cards/Poker.pm',
  },
  'requires'                      => {
    'Test'                          => '0',
    'Test::More'                    => '0',
    'Test::Pod'                     => '0',
    'Test::Pod::Coverage'           => '0',
    'Algorithm::ChooseSubsets'      => '0',
  },
);
$mbld->create_build_script();
