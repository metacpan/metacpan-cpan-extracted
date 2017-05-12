
package Gnome;

=pod

=head1 NAME

Gnome - Perl module for the Gnome libraries

=head1 SYNOPSIS

	use Gnome;
	Gnome->init('myapp');
	my $app = new Gnome::App("myapp", "myapp window title");
	$app->create_menus({type => 'subtree', label => '_File', 
		subtree => [
		['item', '_Quit', undef, sub {exit}, 'stock', 'Quit'],
	]});
	my $canvas = new Gnome::Canvas;
	$canvas->set_scroll_region(0, 0, 300, 300);
	$canvas->set_usize(300, 300);
	$canvas->root->new($canvas->root, 'Rect', 
		x1 => 10, y1 => 10, x2 => 150, y2 => 250, 
		fill_color => '#0f0ef2', outline_color => 'black');
	$app->set_contents($canvas);
	$app->show_all;
	Gtk->main;
	
=head1 DESCRIPTION

The Gtk module allows Perl access to the widgets and other facilities in the Gnome
libraries. You can find more information about Gnome on http://www.gnome.org.
The Perl binding tries to follow the C interface as much as possible,
providing at the same time a fully object oriented interface and
Perl-style calling conventions.

You will find the reference documentation for the Gnome module in the
C<Gnome::reference> manpage. More information can be found on 
http://gtkperl.org.

=head1 AUTHOR

Kenneth Albanowski, Paolo Molaro

=head1 SEE ALSO

perl(1), Gtk(3pm), Gtk::reference(3pm), Gnome::reference(3pm)

=cut

require Gtk;
require Gtk::Gdk::ImlibImage;
require Exporter;
require DynaLoader;

use Carp;

$VERSION = "0.7010";

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
        
);
# Other items we are prepared to export if requested
@EXPORT_OK = qw(
);

sub dl_load_flags {Gtk::dl_load_flags()}

bootstrap Gnome $VERSION;

if ($Gnome::lazy) {
	require Gnome::TypesLazy;
} else {
	require Gnome::Types;
	&Gnome::_boot_all();
}

sub getopt_options {
	my $dummy;
	return (
		Gtk->getopt_options,
		"disable-sound"	=> \$dummy,
		"enable-sound"	=> \$dummy,
		"espeaker=s"	=> \$dummy,
		"version"	=> \$dummy,
		"usage"	=> \$dummy,
		"help|?"	=> \$dummy,
		"sm-client-id=s"	=> \$dummy,
		"sm-config-prefix=s"	=> \$dummy,
		"sm-disable" => \$dummy,
		"disable-crash-dialog" => \$dummy,
		);
}

# Autoload methods go after __END__, and are processed by the autosplit program.

1;
__END__
