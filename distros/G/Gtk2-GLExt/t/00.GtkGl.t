#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2-GLExt/t/00.GtkGl.t,v 1.1 2003/11/16 19:56:40 rwmcfa1 Exp $
#

#########################

use Test::More;
use Gtk2;

#########################

if( Gtk2->init_check )
{
	plan tests => 4;
	require_ok('Gtk2::GLExt');
}
else
{
	plan skip_all =>
		'Gtk2->init_check failed, probably unable to open DISPLAY';
}

ok( Gtk2::GLExt->parse_args );

ok( Gtk2::GLExt->init_check );

ok( Gtk2::GLExt->init );
