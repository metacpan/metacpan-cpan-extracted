use Module::Build;

my $b = Module::Build->new
 (module_name   => 'GitHub::Crud',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Create, Read, Update, Delete files on GitHub',
  license       => 'perl',
  requires      =>
   {Carp=>0,
    Data::Dump=>0,
    Data::Table::Text=>2017.505,
    Digest::SHA1=>0,
    JSON=>0,
    MIME::Base64=>0,
   },
  configure_requires => {'Module::Build' => 0.42},
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
