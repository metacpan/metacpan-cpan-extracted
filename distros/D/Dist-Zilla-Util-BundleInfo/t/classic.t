
use strict;
use warnings;

use Test::More;
use Dist::Zilla::Util::BundleInfo;
require Dist::Zilla::PluginBundle::Classic;

my $bundle = Dist::Zilla::Util::BundleInfo->new(
  bundle_name    => '@Classic',
  bundle_payload => {}
);

my @modules;

for my $plugin ( $bundle->plugins ) {
  push @modules, $plugin->short_module;
  next;
}

is_deeply(
  \@modules,
  [
    qw(
      GatherDir PruneCruft ManifestSkip MetaYAML License Readme PkgVersion PodVersion
      PodCoverageTests PodSyntaxTests ExtraTests ExecDir ShareDir MakeMaker Manifest
      ConfirmRelease UploadToCPAN
      )
  ],
  "short names from \@Classic match expected list"
);

done_testing;
