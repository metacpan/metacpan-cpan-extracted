#!/usr/bin/perl
use Module::Build;
my $mbld = Module::Build->new(
# 'module_name'                   => 'Math::BaseCnv',
  'dist_name'                     => 'Math-BaseCnv',
# 'dist_version_from'             => 'BaseCnv.pm',
  'dist_version'                  => '1.14',
  'dist_abstract'                 => 'basic functions to CoNVert between number Bases',
  'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
# 'create_readme'                 => '1',
# 'create_makefile_pl'            => '1', # 'traditional',
  'license'                       => 'gpl_3',
  'script_files'                  => {
    'bin/cnv'                       => '1',
  },
  'pm_files'                      => {
    'BaseCnv.pm'                    => 'lib/Math/BaseCnv.pm',
  },
  'requires'                      => {
    'Test'                          => '0',
    'Test::More'                    => '0',
    'Test::Pod'                     => '0',
    'Test::Pod::Coverage'           => '0',
    'Math::BigInt'                  => '0',
    'Memoize'                       => '0',
    'Carp'                          => '0',
  },
);
$mbld->create_build_script();
