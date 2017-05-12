
use strict;
use warnings;

use Test::More tests => 5;

# ABSTRACT: A basic test

use Test::DZil qw( simple_ini Builder );
use Test::Differences;

my $files = {
  'source/.dotfile' => q[adotfile],
  'source/bad1'     => q[abadfile],
  'source/bad2'     => q[abadfile],
  'source/good'     => q[agoodfile],
  'source/dist.ini' => simple_ini(
    ['MetaConfig'],
    [
      'if' => {
        dz_plugin => 'GatherDir',
        dz_plugin_arguments =>
          [ 'include_dotfiles = 1', 'exclude_filename = bad1', 'exclude_filename = bad2', 'exclude_filename = bad 3', ]
      }
    ]
  )
};

my $zilla = Builder->from_config( { dist_root => 'invalid' }, { add_files => $files } );
$zilla->chrome->logger->set_debug(1);
$zilla->build;

is_deeply(
  [
    map { $_->{class} } grep { $_->{class} ne 'Dist::Zilla::Plugin::FinderCode' } @{ $zilla->distmeta->{x_Dist_Zilla}->{plugins} }
  ],
  [ 'Dist::Zilla::Plugin::MetaConfig', 'Dist::Zilla::Plugin::GatherDir', 'Dist::Zilla::Plugin::if', ],
  "Expected plugins",
);
my $plugin = $zilla->plugin_named('GatherDir');

eq_or_diff( $plugin->exclude_filename, [ 'bad1', 'bad2', 'bad 3' ] );
ok( -e ( $zilla->tempdir . q[/build/dist.ini] ), 'dist.ini created' );
ok( -e ( $zilla->tempdir . q[/build/.dotfile] ), '.dotfile created' );
ok( -e ( $zilla->tempdir . q[/build/good] ),     'good created' );
