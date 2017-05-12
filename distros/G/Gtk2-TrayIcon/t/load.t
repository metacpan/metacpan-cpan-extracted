
use Gtk2::TestHelper tests => 3;

BEGIN {
	use_ok( "Gtk2::TrayIcon" );
}

Gtk2->init;

my $trayicon= Gtk2::TrayIcon->new("test");
isa_ok( $trayicon, "Gtk2::TrayIcon", '$trayicon' );
isa_ok( $trayicon, "Gtk2::Plug", '$trayicon' );

