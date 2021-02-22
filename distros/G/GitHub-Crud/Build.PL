#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/

use Module::Build;

my $b = Module::Build->new
 (module_name   => 'GitHub::Crud',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Create, Read, Update, Delete files, commits, issues, and web hooks on GitHub.',
  license       => 'perl',
  requires      => {
    perl        => '5.26.1',
    Carp        =>0,
    Data::Dump  =>0,
    'Data::Table::Text'              => 20201029,
    Date::Manip =>0,
    Digest::SHA1=>0,
    Scalar::Util=>0,
    Storable    =>0,
    Test::More  =>0,
    Test2::API  =>0,
    Time::HiRes =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/GitHubCrud',
      bugtracker => 'https://github.com/philiprbrenan/GitHubCrud/issues'
     }
   },
 );

$b->create_build_script();
