#!/usr/bin/perl
use strict;
use warnings;

use Module::Build;

Module::Build->new
    ( module_name => 'HTTP::Server::Simple::Static',
      dist_author => 'Stephen Quinney <sjq-perl@jadevine.org.uk>',
      license     => 'perl',
      create_makefile_pl => 'traditional',
      requires    => {
          'Cwd'                   => 0,
	  'CGI'                   => '3.46',
          'Exporter'              => 0,
          'File::LibMagic'        => 0,
          'File::Spec::Functions' => 0,
          'HTTP::Date'            => 0,
          'HTTP::Server::Simple'  => 0.01 ,
          'IO::File'              => 0,
          'URI::Escape'           => 0,
      },
      configure_requires => {
          'Module::Build' => '0.40'
      }, 
    )->create_build_script;
