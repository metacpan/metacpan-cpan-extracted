
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Graph::ChainBuilder',
  license             => 'perl',
  dist_version_from   => 'lib/Graph/ChainBuilder.pm',
  requires => {
    'Class::Accessor::Classy' => 'v0.9.0',
  },
  build_requires => {
    'Module::Build' => 0.26,
    'Test::More'    => 0,
  },
  add_to_cleanup      => [ qw(Graph-ChainBuilder-* META.yml)],
  # create_makefile_pl => 'passthrough',
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Graph-ChainBuilder',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/Graph-ChainBuilder/trunk',
    }
  },
);

$builder->create_build_script();

# vi:syntax=perl:ts=2:sw=2:et:sta
