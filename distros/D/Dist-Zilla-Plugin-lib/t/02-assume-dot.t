
use strict;
use warnings;

use Test::More;
use Path::Tiny qw( cwd path );
use constant _eg => cwd()->child('examples/dot-inc')->stringify;
use lib _eg;

# ABSTRACT: Test neomake example works

use Test::DZil qw( Builder );
my $tzil = Builder->from_config( { dist_root => _eg } );
$tzil->chrome->logger->set_debug(1);
$tzil->build;

pass("Built ok");
my $plugin;
ok( $plugin = $tzil->plugin_named("=inc::Bundled::Plugin"), "inc/ loaded plugin in dzil" ) or do {
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

$plugin and isnt( $INC[0], '.', "Path injected in \@INC should not be a literal q[.]" ) or do {
  diag "All \@INC + is_absolute state";
  diag $_ for map { "- $_ => " . ( ref $_ ? 'ref' : path($_)->is_absolute ? 'abs' : 'rel' ) } @INC;
};

$plugin and is( path( $INC[0] )->basename, path(_eg)->basename, "Injected \@INC should be a project root" ) or do {
  diag "All \@INC + is_absolute state";
  diag $_ for map { "- $_ => " . ( ref $_ ? 'ref' : path($_)->is_absolute ? 'abs' : 'rel' ) } @INC;
  diag "Project Root: ", $tzil->root;
};

if ( $ENV{AUTOMATED_TESTING} || $ENV{TRAVIS} ) {
  diag $_ for @{ $tzil->log_messages };
}

done_testing;
