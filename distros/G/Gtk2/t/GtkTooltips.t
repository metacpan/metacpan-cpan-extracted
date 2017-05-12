#
# $Id$
#

#########################
# GtkTooltips Tests
# 	- rm
#########################

use Gtk2::TestHelper tests => 10;

ok( my $tips = Gtk2::Tooltips->new );

ok( my $btn = Gtk2::Button->new('Button 1') );
$tips->set_tip($btn, 'Tip 1', 'Vebose Tip 1');
ok(1);

ok( $btn = Gtk2::Button->new('Button 2') );
$tips->set_tip($btn, 'Tip 2', 'Vebose Tip 2');

is_deeply( Gtk2::Tooltips->data_get($btn),
           { tooltips => $tips,
             widget => $btn,
             tip_text => 'Tip 2',
             tip_private => 'Vebose Tip 2' } );

ok( $btn = Gtk2::Button->new('Button 3') );
$tips->set_tip($btn, 'This is a really long, really big tooltip which doesn\'t '
	.'tell you anything worth knowning. There\'s no private tip either',
	undef);
ok(1);

$tips->force_window;
ok(1);

$tips->disable;
ok(1);
$tips->enable;
ok(1);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
