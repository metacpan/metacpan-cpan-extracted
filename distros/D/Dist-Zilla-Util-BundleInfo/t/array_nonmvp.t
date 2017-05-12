
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
    root => ['./'],
  },
);

my $out;
unlike( warning { $out = $plugin->to_dist_ini }, qr/is not an MVP multi-value/, "No warning from single array" );
my @roots = grep { $_ =~ /root\s+=\s+/ } split qq/\n/, $out;

is( scalar @roots, 1, "Exactly one root= statement" );

note $out;

done_testing;

