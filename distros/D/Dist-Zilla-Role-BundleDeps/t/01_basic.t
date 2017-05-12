use strict;
use warnings;

use Test::More;

{

  package Example;
  use Moose;
  with "Dist::Zilla::Role::PluginBundle";
  with "Dist::Zilla::Role::BundleDeps";

  sub bundle_config {
    return (
      [ 'Alias',     'Dist::Zilla::Plugin::Prereqs',     { ':version' => '4.0' } ],
      [ 'Alias_Two', 'Dist::Zilla::Plugin::AutoPrereqs', {} ],
    );
  }
  __PACKAGE__->meta->make_immutable;
}

my (@config) = Example->bundle_config( {} );
is( scalar @config,                                         3,                              'Mangled config as extra items' );
is( $config[-1]->[0],                                       'Example/::Role::BundleDeps',   'Generated name is expected' );
is( $config[-1]->[1],                                       'Dist::Zilla::Plugin::Prereqs', 'Generated plugin is expected' );
is( ref $config[-1]->[2],                                   'HASH',                         'Config is a hash' );
is( $config[-1]->[2]->{-phase},                             'develop',                      '-phase is a develop' );
is( $config[-1]->[2]->{-relationship},                      'requires',                     '-relationship is requires' );
is( $config[-1]->[2]->{'Dist::Zilla::Plugin::Prereqs'},     '4.0',                          'DZP:Prereqs 4.0 required' );
is( $config[-1]->[2]->{'Dist::Zilla::Plugin::AutoPrereqs'}, '0',                            'DZP:AutoPrereqs 0 required' );

done_testing;
