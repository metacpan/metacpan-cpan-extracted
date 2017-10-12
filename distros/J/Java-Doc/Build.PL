use v5.16;
use Module::Build;

my $b = Module::Build->new
 (module_name   => 'Java::Doc',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Extract documentation from Java source code.',
  license       => 'perl',
  requires      =>
   {'Carp'             =>0,
    'Data::Dump'       =>0,
    'Data::Table::Text'=>20171004,
    'POSIX'            =>0,
    'Test2::API'       =>0,
    'Test::More'       =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
