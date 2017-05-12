
use strict;
use warnings;
use Module::Build;
my $build_class = 'Module::Build';

my $builder = $build_class->new(
  module_name         => 'Math::Geometry::Planar::Offset',
  license             => 'perl',
  dist_version_from   => 'lib/Math/Geometry/Planar/Offset.pm',
  requires => {
    'Test::More'    => 0,
    'YAML'          => 0,
  },
  meta_merge => {
    resources => {
      homepage =>
        'http://scratchcomputing.com/',
      bugtracker =>
        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Geometry-Planar-Offset',
      #MailingList => 'mailto:...',
      repository =>
        'http://scratchcomputing.com/svn/Math-Geometry-Planar-Offset/trunk',
    }
  },
  add_to_cleanup      => [ qw(Math-Geometry-Planar-Offset-* META.yml)],
  create_makefile_pl  => 'passthrough',
);

$builder->create_build_script();
# vi:syntax=perl:ts=2:sw=2:et:sta
