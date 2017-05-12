#########################
# GnomePrint2 Tests
#       - ebb
#########################

#########################

use Test::More tests => 2;
use_ok('Gnome2::Print');

#########################

my @version = Gnome2::Print->GET_VERSION_INFO;
is( @version, 3, 'version is three items long' );
