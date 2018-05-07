use v5.16;
use Module::Build;

BEGIN                                                                           # Check environment
 {if ($^O eq 'MSWin32')
   {print "OS Unsupported\n";
    exit 1;
   }
 }

my $b = Module::Build->new
 (module_name   => 'Image::Find::Loops',
  dist_author   => 'philiprbrenan@gmail.com',
  dist_abstract => 'Find loops in an image.',
  license       => 'perl',
  requires      =>
   {'Carp'             =>0,
    'Data::Dump'       =>0,
    'Data::Table::Text'=>20180328,
    'Test2::API'       =>0,
    'Test::More'       =>0,
   },
  configure_requires => {'Module::Build' => 0.4224},
  create_readme =>  0,
  perl          => '5.16.0',
 );

$b->create_build_script();
