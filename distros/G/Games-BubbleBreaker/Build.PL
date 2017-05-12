use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
  module_name          => 'Games::BubbleBreaker',
  all_from             => 'lib/Games/BubbleBreaker.pm',
  dist_author          => 'Tobias Leich <froggs@cpan.org>',
  license              => 'perl',
  requires             => {
    'File::ShareDir'   => '0',
    'File::HomeDir'    => '0',
    'File::Spec'       => '0',
    'Time::HiRes'      => '0',
    'SDL'              => '2.532',
  },
  build_requires => {
    'Capture::Tiny'     => '0',
  },
  configure_requires   => {
    'Module::Build'    => '0.38',
  },
  meta_merge => {
    resources  => {
      repository => 'http://github.com/FROGGS/Games-BubbleBreaker'
    }
  },
  create_readme => 1,
  share_dir => 'share',
)->create_build_script();
