use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
  module_name          => 'Games::PangZero',
  all_from             => 'lib/Games/PangZero.pm',
  dist_abstract        => 'a fast-paced action game about popping balloons with a harpoon',
  dist_author          => [
    'UPi <upi@sourceforge.net>',
    'SAdam <sadam@apocalypse.rulez.org>',
    'DaniGM <danigm@gmail.com>',
    'Elio Blanca <eblanca76@users.sourceforge.net>',
  ],
  license              => 'gpl',
  requires             => {
    'File::ShareDir'   => '0',
    'File::Spec'       => '0',
    'Time::HiRes'      => '0',
    'SDL'              => '2.536',
  },
  configure_requires   => {
    'Module::Build'    => '0.38',
  },
  meta_merge => {
    resources  => {
        bugtracker => 'http://github.com/kthakore/pangzero/issues',
        repository => 'http://github.com/kthakore/pangzero'
    }
  },
  share_dir => 'data',
)->create_build_script();
