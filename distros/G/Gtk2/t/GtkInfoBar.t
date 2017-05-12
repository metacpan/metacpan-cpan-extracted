#!/usr/bin/perl
# vim: set syntax=perl :
#
# $Id$
#
# GtkInfoBar Tests

use Gtk2::TestHelper tests => 15, at_least_version=> [2,18,0];

ok( my $win = Gtk2::Window->new('toplevel') );

my $infobar=Gtk2::InfoBar->new;
isa_ok ($infobar, 'Gtk2::InfoBar', 'new');
$win->add($infobar);

isa_ok ($infobar->get_action_area, 'Gtk2::Widget','get_action_area');
isa_ok ($infobar->get_content_area, 'Gtk2::Widget','get_content_area');

isa_ok( $infobar->add_button(test3=>3), 'Gtk2::Widget', 'add_button');
is( button_count($infobar), 1, 'add_button count');
$infobar->add_buttons(test4=>4,test5=>5);
is( button_count($infobar), 3, 'add_buttons');

my $button=Gtk2::Button->new("action_widget");
$infobar->add_action_widget($button, 6);
is( button_count($infobar), 4, 'add_action_widget');

my $infobar2=Gtk2::InfoBar->new(
	'gtk-ok' => 'ok', 'test2' => 2,
);
isa_ok ($infobar2, 'Gtk2::InfoBar', 'new_with_buttons');
is( button_count($infobar2), 2, 'new_with_buttons buttons count');

$infobar->set_response_sensitive(6,FALSE);
is( $button->is_sensitive, FALSE, 'set_response_sensitive');

$infobar->set_message_type('error');
is( $infobar->get_message_type, 'error', '[gs]et_message_type');

$infobar->set_default_response(4);
ok( 1,'set_default_response');

$infobar->signal_connect( response => sub {
		my ($infobar,$response)=@_;
		my $expected=$infobar->{expected_response};
		ok( $response eq $expected, "response '$expected'" );
		1;
	});
$infobar->response( $infobar->{expected_response}=5 );
$infobar->response( $infobar->{expected_response}='ok' );


sub button_count
{	my @b=$_[0]->get_action_area->get_children;
	return scalar @b;
}

__END__

Copyright (C) 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
