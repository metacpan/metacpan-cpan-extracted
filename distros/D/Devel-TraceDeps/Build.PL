
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Devel::TraceDeps',
  license             => 'perl',
  dist_version_from   => 'lib/Devel/TraceDeps.pm',
  requires => {
    'Class::Accessor::Classy' => 'v0.9.0',
    'Getopt::AsDocumented'    => 0,
    'File::Fu'                => 'v0.0.6',
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  configure_requires => { 'Module::Build' => 0.31 },
  add_to_cleanup      => [ qw(Devel-TraceDeps-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-TraceDeps',
      #MailingList => 'mailto:...',
      repository =>
        'http://svn.scratchcomputing.com/Devel-TraceDeps/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
