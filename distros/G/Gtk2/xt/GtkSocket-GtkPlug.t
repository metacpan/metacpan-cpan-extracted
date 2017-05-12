#!/usr/bin/perl
#
# $Id$
#

# ...despite patches that have been around for a long time, no win32
use Gtk2::TestHelper tests => 12, nowin32 => 1;

SKIP: {

skip "blib can't be found", 6
	unless -d "blib";

ok( my $win = Gtk2::Window->new );

ok( my $socket = Gtk2::Socket->new );
$win->add($socket);

ok( my $id = $socket->get_id );

SKIP: {
	skip 'new 2.14 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	is( $socket->get_plug_window, undef );
	$socket->signal_connect (plug_added => sub {
		isa_ok( $socket->get_plug_window, 'Gtk2::Gdk::Window' );
	});
}

my $pid = fork;

skip 'fork failed', 2 unless defined $pid && $pid >= 0;

if( $pid == 0 )
{
	exec("$^X -Mblib -e 'my \$id = $id;\n\n" . <<EOL);
use Gtk2;

Gtk2->init;

my \$plug = Gtk2::Plug->new($id);

my \$btn = Gtk2::Button->new("gtk-quit");
\$btn->signal_connect("clicked" => sub { Gtk2->main_quit; 1; });
\$plug->add(\$btn);

\$plug->show_all;

Glib::Idle->add(sub { \$btn->clicked; 0; });

Gtk2->main;'
EOL
	exit 0;
}
else
{
	$socket->signal_connect('plug-removed' => sub {
		Gtk2->main_quit;
		1;
	});
	$win->show_all;
	Gtk2->main;
	ok( waitpid($pid, 0) );
}

}

# Standalone GtkPlug tests.
SKIP: {
	my $id = 23;
	my $display = Gtk2::Gdk::Display->get_default;

	# Backwards compatibility tests
	my $plug = Gtk2::Plug->new($id);
	isa_ok( $plug, 'Gtk2::Plug' );

	$plug->construct($id);
	$plug->construct_for_display($display, $id);

	ok( defined $plug->get_id );

	skip 'new 2.14 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 14, 0);

	is( $plug->get_embedded, FALSE );
	is( $plug->get_socket_window, undef );
}

# Backwards compatibility tests.
{
	my $id = 23;
	my $display = Gtk2::Gdk::Display->get_default;

	isa_ok( Gtk2::Plug::new_for_display($display, $id),
		'Gtk2::Plug' );

	isa_ok( Gtk2::Plug->new_for_display($display, $id),
		'Gtk2::Plug' );
}

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
