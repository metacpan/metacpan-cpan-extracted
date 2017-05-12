
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'HTTP::Server::Simple::Er',
  license             => 'perl',
  dist_version_from   => 'lib/HTTP/Server/Simple/Er.pm',
  requires => {
    'HTTP::Server::Simple'    => 0.27,
    'Class::Accessor::Classy' => 'v0.9.0',
    'URI::Escape'             => 0,
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(HTTP-Server-Simple-Er-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Server-Simple-Er',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/HTTP-Server-Simple-Er/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
