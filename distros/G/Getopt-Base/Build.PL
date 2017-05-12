
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Getopt::Base',
  license             => 'perl',
  dist_version_from   => 'lib/Getopt/Base.pm',
  requires => {
    perl => '5.008000', # because I don't want to rewrite the tests
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  configure_requires => {'Module::Build' => 0.31},
  add_to_cleanup      => [ qw(Getopt-Base-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Getopt-Base',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Getopt-Base/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
