#!/usr/bin/perl -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DataTableText/lib/
use Module::Build;

my $b = Module::Build->new(

  configure_requires => { "Module::Build" => 0.4224 },
  create_readme      => 0,
  dist_abstract      => "Implementation of the Please Change Dita Language",
  license            => "perl",
  module_name        => "Dita::PCD",
  requires           => {
                          "Carp" => 0,
                          "Cwd" => 0,
                          "Data::Dump" => 0,
                          'Data::Edit::Xml'                => 20201030,
                          'Data::Table::Text'              => 20201029,
                          "Exporter" => 0,
                          "perl" => bless({ original => "v5.26.1", qv => 1, version => [5, 26, 1] }, "version"),
                          "Test2::API" => 0,
                          "Test::More" => 0,
                        },
  meta_merge =>
   {resources =>
     {repository => 'https://github.com/philiprbrenan/DitaPCD',
      bugtracker => 'https://github.com/philiprbrenan/DitaPCD/issues'
     }
   },

 );

$b->create_build_script();
