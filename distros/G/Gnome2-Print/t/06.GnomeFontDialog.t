#########################
# GnomePrint2 Tests
#       - ebb
#########################

#########################

use Test::More tests => 9;
BEGIN { use_ok('Gnome2::Print') };

#########################

ok( $font = Gnome2::Print::Font->find_closest("Sans Regular", 12.0) );
ok( $font->get_name );

ok( $weight = Gnome2::Print::Font->bold );

use_ok('Gnome2::Print::Font::Constants');
ok( $weight = Gnome2::Print::Font::GNOME_FONT_BOLD );

ok( Gnome2::Print::Font->list );
ok( @family_list = Gnome2::Print::Font->family_list );
ok( Gnome2::Print::Font->style_list($family_list[0]) );
