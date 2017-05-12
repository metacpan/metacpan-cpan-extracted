use strict;
use warnings;

use Test::More;
use Dist::Zilla::Util::BundleInfo;

{
  package Dist::Zilla::Plugin::_Test;
  use Moose qw( with );
  BEGIN { $INC{'Dist/Zilla/Plugin/_Test.pm'} = __FILE__ }
  with 'Dist::Zilla::Role::Plugin';

  1;
}
{

  package Dist::Zilla::PluginBundle::_Test;

  use Moose qw( with );
  BEGIN { $INC{'Dist/Zilla/PluginBundle/_Test.pm'} = __FILE__ }
  with 'Dist::Zilla::Role::PluginBundle';
  sub mvp_multivalue_args { return qw( auto_prereqs_skip copyfiles ) }

  sub mvp_aliases {
    return {
      'bumpversions' => 'bump_versions',
      'srcreadme'    => 'src_readme',
    };
  }

  sub bundle_config {
    my ( $class, $section ) = @_;
    die "No payload" unless defined( my $payload = $section->{'payload'} );
    return ( [ '_Test', 'Dist::Zilla::Plugin::_Test', $payload ] );
  }
}

my $bundle = Dist::Zilla::Util::BundleInfo->new(
  bundle_name    => '@_Test',
  bundle_payload => [
    bumpversions => '1',
    srcreadme    => 'mkdn',
  ],
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
      _Test
      )
  ],
  "_Test exported by test bundle"
);
is_deeply(
  [ $bundle->plugins ]->[0]->payload,
  {
    'src_readme'    => 'mkdn',
    'bump_versions' => 1,
  },
  "_Test bundles payload is munged correctly"
);

done_testing;
