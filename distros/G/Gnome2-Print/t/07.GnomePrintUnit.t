#########################
# GnomePrint2 Tests
#       - ebb
#########################

#########################

use Test::More tests => 5;
BEGIN { use_ok('Gnome2::Print') };

#########################

ok( $default_unit = Gnome2::Print::Unit->get_default );
ok( Gnome2::Print::Unit->get_by_name("Inch") );
ok( Gnome2::Print::Unit->get_by_abbreviation("pt") );

ok( Gnome2::Print::Unit->get_identity ($default_unit->base) );
