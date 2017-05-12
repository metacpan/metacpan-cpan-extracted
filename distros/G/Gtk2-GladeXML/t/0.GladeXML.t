#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Glade/t/0.GladeXML.t,v 1.6 2004/09/15 03:31:05 muppetman Exp $
#

#########################
# GladeXML Tests
# 	- rm
#########################

use Test::More;
use Gtk2;

if( Gtk2->init_check )
{
	plan tests => 3;
	require_ok('Gtk2::GladeXML');
}
else
{
	plan skip_all =>
		'Gtk2->init_check failed, probably unable to open DISPLAY';
}

#########################

sub gtk_main_quit
{
	Gtk2->main_quit;
}

sub gtk_true
{
	print STDERR "gtk_true: ".Dumper( @_ );
}

sub gtk_widget_hide
{
	$_[1]->hide;
}

sub gtk_widget_show
{
	$_[1]->show;
}


ok( $gld = Gtk2::GladeXML->new('t/example.glade') );

$gld->signal_autoconnect_from_package('main');

Glib::Idle->add( sub {
	ok( $btn = $gld->get_widget("Quit") );
	$btn->activate;
	0;
});

Gtk2->main;
