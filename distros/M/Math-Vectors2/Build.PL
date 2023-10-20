#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
use v5.16;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Math::Vectors2',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Vectors in two dimensions.',
  license       => 'perl',
  requires      =>
   {'Carp'             =>0,
    'Data::Table::Text'              => 20201029,
     perl              => '5.26.1',
    'Test2::API'       =>0,
    'Test::More'       =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.16.0',
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/MathVectors2',
      bugtracker => 'https://github.com/philiprbrenan/MathVectors2/issues'
     }
   },
 );

$b->create_build_script();
