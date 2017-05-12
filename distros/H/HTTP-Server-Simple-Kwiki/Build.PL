use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'HTTP::Server::Simple::Kwiki',
  requires           => {
    'Test::More'                     => '0',
    'HTTP::Server::Simple::CGI'      => '0',
    'HTTP::Server::Simple::Static'   => '0',
    'Kwiki'                          => '0',
    'IO::Capture::Stdout'            => '0',
  },
);
$build->create_build_script;
