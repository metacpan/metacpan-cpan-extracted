
use strict;
use warnings;

use Test::More;
use Path::Tiny qw( cwd path );
use constant _eg => cwd()->child('examples/inc-lib')->stringify;
use lib _eg;

# ABSTRACT: Test neomake example works

use Test::DZil qw( Builder );
my $tzil = Builder->from_config( { dist_root => _eg } );
$tzil->chrome->logger->set_debug(1);
$tzil->build;

pass("Built ok");
my $plugin;
ok( $plugin = $tzil->plugin_named("=Bundled::Plugin"), "inc/ loaded plugin in dzil" ) or do {
  diag "All plugins:";
  for my $plugin ( @{ $tzil->plugins } ) {
    diag "- $plugin => " . $plugin->plugin_name;
  }
};

$plugin and (
  is( $plugin->property, "foo", "inc/ loaded plugins have working attributes" ) or do {
    diag "All attributes";
    diag explain {
      map { $_ => '' . $plugin->{$_} } keys %{$plugin}
    };
  }
);

if ( $ENV{AUTOMATED_TESTING} || $ENV{TRAVIS} ) {
  diag $_ for @{ $tzil->log_messages };
}

done_testing;
