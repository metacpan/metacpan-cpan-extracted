#
# $Id$
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
