
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Getopt::AsDocumented',
  license             => 'perl',
  dist_version_from   => 'lib/Getopt/AsDocumented.pm',
  requires => {
    'Getopt::Base' => 'v0.0.3',
    'YAML'         => 0,
    'Pod::Parser'  => 0,
  },
  build_requires => {
    'Module::Build' => 0.4005,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Getopt-AsDocumented-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://enobacon.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Getopt-AsDocumented',
      #MailingList => 'mailto:...',
      repository =>
        'git://git.enobacon.com/Getopt-AsDocumented.pm.git',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
