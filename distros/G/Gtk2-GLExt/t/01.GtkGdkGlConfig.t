#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/t/01.GtkGdkGlConfig.t,v 1.1 2003/11/16 19:56:40 rwmcfa1 Exp $
#

#########################

use Test::More;
use Gtk2;
use Gtk2::GLExt;

#########################

if( Gtk2->init_check )
{
	plan tests => 13;
}
else
{
	plan skip_all =>
		'Gtk2->init_check failed, probably unable to open DISPLAY';
}

ok( my $glconfig = Gtk2::Gdk::GLExt::Config->new_by_mode( 
	[ qw/rgb depth/ ]
) );


is( $glconfig->get_attrib('depth-size'), $glconfig->get_depth );

is( $glconfig->get_attrib('rgba'), $glconfig->is_rgba );

is( ref $glconfig->get_colormap, 'Gtk2::Gdk::Colormap' );

is( ref $glconfig->get_visual, 'Gtk2::Gdk::Visual' );

ok( defined($glconfig->get_layer_plane) );

ok( defined($glconfig->get_n_aux_buffers) );

ok( defined($glconfig->get_n_sample_buffers) );

ok( defined($glconfig->is_stereo) );

ok( defined($glconfig->has_alpha) );

ok( defined($glconfig->has_depth_buffer) );

ok( defined($glconfig->has_stencil_buffer) );

ok( defined($glconfig->has_accum_buffer) );

