use strict;

use Module::Build;

Module::Build->new
    ( module_name => 'Maypole::HTTPD',
      license     => 'perl',
      create_makefile_pl => 'passthrough',
      requires    => { 'Maypole' => '2.06',
		       'HTTP::Server::Simple'=>'0.02',
		       'HTTP::Server::Simple::Static'=>'0.01'},
    )->create_build_script;
