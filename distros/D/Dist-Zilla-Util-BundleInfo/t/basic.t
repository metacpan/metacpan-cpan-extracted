
use strict;
use warnings;

use Test::More;
use Dist::Zilla::Util::BundleInfo;
require Dist::Zilla::PluginBundle::Basic;

my $bundle = Dist::Zilla::Util::BundleInfo->new(
  bundle_name    => '@Basic',
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
      GatherDir PruneCruft ManifestSkip MetaYAML License Readme ExtraTests ExecDir ShareDir
      MakeMaker Manifest TestRelease ConfirmRelease UploadToCPAN
      )
  ],
  "short names from \@Basic match expected list"
);

done_testing;
