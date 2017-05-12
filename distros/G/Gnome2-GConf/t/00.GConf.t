#########################
# Gnome2::GConf Tests
#       - ebb
#########################

#########################

use strict;
use Gnome2::GConf;

use constant SKIP_1 => 7;
use constant SKIP_2 => 1;
use Test::More tests => SKIP_1 + SKIP_2 + 3;

my @version = Gnome2::GConf->GET_VERSION_INFO;
is( @version, 3, 'version is three items long' );

our $app_dir = '/apps/basic-gconf-app';
our $key_foo = 'foo';
my $foo_path = Gnome2::GConf->concat_dir_and_key($app_dir, $key_foo);
is( $foo_path, '/apps/basic-gconf-app/foo', 'valid foo key');
my $is_valid = Gnome2::GConf->valid_key($foo_path);
ok( $is_valid );

my $c = Gnome2::GConf::Client->get_default;

SKIP: {
  skip("Couldn't connect to the GConf default client.", SKIP_1)
    unless ($c);

  skip("basic-gconf-app directory not found in GConf.", SKIP_1)
    unless ($c->dir_exists('/apps/basic-gconf-app'));

  our $client = Gnome2::GConf::Client->get_default;
  isa_ok( $client, 'Gnome2::GConf::Client' );
  
  $client->add_dir($app_dir, 'preload-recursive');
  ok( 1 );
  
  is( $client->get($foo_path)->{'type'}, 'string' );
  
  ok( $client->get_string($foo_path) );
  
  our $id = $client->notify_add($foo_path, sub { warn @_; });
  ok( $id );
  
  ok( $client->set_string($foo_path, 'test') );

  $client->notify_remove($id);
  ok( 1 );
}

my $e = Gnome2::GConf::Engine->get_default;

SKIP: {
  skip("Couldn't connect to the GConf default engine.", SKIP_2)
    unless ($e);

  # we can not use an engine with a client attached - so we just test the
  # ::get_default method.
  our $engine = Gnome2::GConf::Engine->get_default;
  isa_ok( $engine, 'Gnome2::GConf::Engine' );
}

#########################
