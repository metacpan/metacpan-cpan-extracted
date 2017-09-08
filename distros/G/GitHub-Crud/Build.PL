use v5.8.0;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'GitHub::Crud',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Create, Read, Update, Delete files on GitHub',
  license       => 'perl',
  requires      =>
   {Carp        =>0,
    Data::Dump  =>0,
    Data::Table::Text=>'20170902',
    Digest::SHA1=>0,
    Test::More  =>0,
    Test2::API  =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.8.0',
 );

$b->create_build_script();
