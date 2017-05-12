
use Gtk2::TestHelper tests => 3;

BEGIN {
	use_ok( "Gtk2::TrayManager" );
}

Gtk2->init;

my $traymanager= Gtk2::TrayManager->new;
isa_ok( $traymanager, "Glib::Object", '$traymanager' );
isa_ok( $traymanager, "Gtk2::TrayManager", '$traymanager' );

exit;
