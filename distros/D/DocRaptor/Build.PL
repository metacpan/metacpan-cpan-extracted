use 5.018002;

use Module::Build;

my $builder = Module::Build
  ->new(   module_name        => 'DocRaptor'
         , dist_abstract      => 'A Doc Creation API Wrapper for DocRaptor'
         , author             => ['DocRaptor <support@docraptor.com>']
         , description        => 'DocRaptor (https://docraptor.com) is a service that converts HTML to PDFs and Excel files, and this is a wrapper around that HTTP interface.'
         , dynamic_config     => 0
         , release_status     => 'stable'
         , license            => 'mit'
         , requires           => {
               'perl'                  => '5.18.2'
             , 'Path::Class'           => '0.35'
             , 'Moose'                 => '2.1405'
             , 'HTTP::Request::Common' => '6.10'
             , 'LWP::UserAgent'        => '6.13'
             , 'LWP::Protocol::https'  => '6.06'
           }
         , create_makefile_pl => 'traditional'
         , dist_version       => '0.002001'
       );
$builder->create_build_script;
