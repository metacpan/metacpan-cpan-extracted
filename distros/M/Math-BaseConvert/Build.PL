#!/usr/bin/perl
use Module::Build;
my $mbld = Module::Build->new(
# 'module_name'                   => 'Math::BaseConvert',
  'dist_name'                     => 'Math-BaseConvert',
  'dist_version_from'             => 'lib/BaseConvert.pm',
  'dist_version'                  => '1.8',
  'dist_abstract'                 => 'fast functions to CoNVert between number Bases',
  'dist_author'                   => 'Pip Stuart <Pip@CPAN.Org>',
# 'create_readme'                 => '1',
# 'create_makefile_pl'            => '1', # 'traditional',
  'license'                       => 'gpl',
  'script_files'                  => {
    'bin/cnv'                       => '1',
  },
  'requires'                      => {
    'Math::BigInt'                  => '0',
    'Memoize'                       => '0',
    'Test'                          => '0',
    'Test::Pod'                     => '0',
    'Test::Pod::Coverage'           => '0',
  },
);
$mbld->create_build_script();
