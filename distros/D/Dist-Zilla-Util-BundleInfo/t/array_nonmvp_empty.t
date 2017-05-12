
use strict;
use warnings;

use Test::More;

# FILENAME: array_nonmvp.t
# CREATED: 10/17/14 10:44:31 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test a non-mvp attribute being passed an array

use Dist::Zilla::Util::BundleInfo::Plugin;
use Dist::Zilla::Plugin::GatherDir;
use Test::Warnings qw( warning );

my $plugin = Dist::Zilla::Util::BundleInfo::Plugin->new(
  name    => 'GatherDir',
  module  => 'Dist::Zilla::Plugin::GatherDir',
  payload => {
    root => [],
  },
);

my $out;
like( warning { $out = $plugin->to_dist_ini }, qr/empty array attribute/, 'Warns about empty array' );
unlike( $out, qr/^root\s*=/, 'No entry emitted' );
note $out;

done_testing;

