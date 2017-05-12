
use strict;
use warnings;

#use Test::More;
use Dist::Zilla::Util::BundleInfo;
my $bundle = Dist::Zilla::Util::BundleInfo->new(
  bundle_name    => '@Author::KENTNL',
  bundle_payload => [
    git_versions     => 1,
    mantissa         => 6,
    normal_form      => 'numify',
    toolkit          => 'eumm',
    toolkit_hardness => 'soft',
    bumpversions     => 1,
  ]
);

for my $plugin ( $bundle->plugins ) {
  print $plugin->to_dist_ini;
  next;
}

