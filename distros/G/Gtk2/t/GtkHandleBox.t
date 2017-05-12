#
# $Id$
#

#########################
# GtkHandleBox Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 8, noinit => 1;

ok( my $hb = Gtk2::HandleBox->new );

$hb->add( Gtk2::Label->new('Just a test label') );

$hb->set_shadow_type('none');
ok( $hb->get_shadow_type eq 'none' );
$hb->set_shadow_type('etched-in');
ok( $hb->get_shadow_type eq 'etched-in' );

$hb->set_snap_edge('top');
ok( $hb->get_snap_edge eq 'top' );
$hb->set_snap_edge('left');
ok( $hb->get_snap_edge eq 'left' );

$hb->set_handle_position('left');
ok( $hb->get_handle_position eq 'left' );
$hb->set_handle_position('top');
ok( $hb->get_handle_position eq 'top' );

ok( ! $hb->get_child_detached );

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
