#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/t/02.GtkGlWidget.t,v 1.2 2003/11/25 03:08:08 rwmcfa1 Exp $
#

#########################

use Test::More;
use Gtk2;
use Gtk2::GLExt;

#########################

if( Gtk2->init_check )
{
	plan tests => 11;
}
else
{
	plan skip_all =>
		'Gtk2->init_check failed, probably unable to open DISPLAY';
}

my $win = Gtk2::Window->new;

my $glconfig = Gtk2::Gdk::GLExt::Config->new_by_mode ([ qw/rgb depth/ ]);

my $darea = Gtk2::DrawingArea->new;
is( $darea->is_gl_capable, '' );
ok( $darea->set_gl_capability ($glconfig, undef, 1, 'rgba-type') );
is( $darea->is_gl_capable, 1 );

$darea->signal_connect (realize => sub {
		my $widget = shift;
		ok( my $context = $widget->get_gl_context );
		ok( my $window = $widget->get_gl_window );
		ok( my $drawable = $widget->get_gl_drawable );
		
		is( ref $context, 'Gtk2::Gdk::GLExt::Context' );

		ok( $darea->create_gl_context (undef, 1, 'rgba-type') );

		# make sure that we can get to the drawable child methods
		ok( $drawable->gl_begin($context) );

		is( ref $window->get_window, 'Gtk2::Gdk::Window');
		
		$drawable->gl_end;
		ok(1);
	});

Glib::Idle->add( sub {
		Gtk2->main_quit;
	});

$win->add ($darea);
$win->show_all;
Gtk2->main;
