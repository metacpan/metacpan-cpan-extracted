#!/usr/bin/perl
require v5.26;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'MakeWithPerl',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Make with Perl',
  license       => 'perl',
  requires      =>
   {'Carp'                =>0,
    'Data::Dump'          =>0,
    'feature'             =>0,
    'Data::Table::Text'   =>20210519,
    'Getopt::Long'        =>0,
    'Test2::API'          =>0,
    'Test::Most'          =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/MakeWithPerl',
      bugtracker => 'https://github.com/philiprbrenan/MakeWithPerl/issues'
     }
   },
  create_readme =>  0,
  perl          => '5.26.0',
 );

$b->create_build_script();
