#########################
# GnomePrint2 Tests
#       - ebb
#########################

#########################

use Test::More tests => 5;
BEGIN { use_ok('Gnome2::Print') };

#########################

ok( $config = Gnome2::Print::Config->default );
ok( Gnome2::Print::Config->key_paper_size );
ok( $config->get(Gnome2::Print::Config->key_paper_size) );

# Warning, Warning, Will Robinson! Horrid Hack Ahead!
# Gnome2::Print::Config::set returns true only when the change did occur
# so we must change to a value which is quite unusual for anyone and then
# switch back.  I choose the 'A0' format which should be unusual enough;
# at least, if you aren't testing Gnome2::Print in a typography, that is.
$old_size = $config->get(Gnome2::Print::Config->key_paper_size);
$config->set(Gnome2::Print::Config->key_paper_size, "A0");
is( $config->set(Gnome2::Print::Config->key_paper_size, $old_size), 1 );
