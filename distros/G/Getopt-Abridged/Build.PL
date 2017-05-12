
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Getopt::Abridged',
  license             => 'perl',
  dist_version_from   => 'lib/Getopt/Abridged.pm',
  requires => {
    'Getopt::Base' => 'v0.0.2',
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Getopt-Abridged-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Getopt-Abridged',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Getopt-Abridged/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
