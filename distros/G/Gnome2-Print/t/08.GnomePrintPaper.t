#########################
# GnomePrint2 Tests
#       - ebb
#########################

#########################

use Test::More tests => 3;
BEGIN { use_ok('Gnome2::Print') };

#########################

use Data::Dumper;

ok( Gnome2::Print::Paper->get_default );
isa_ok( Gnome2::Print::Paper->get_by_name ('A4'), 'Gnome2::Print::Paper' );
