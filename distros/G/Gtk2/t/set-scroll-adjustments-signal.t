#!/usr/bin/perl -w
# vim: set ft=perl :

use Gtk2::TestHelper tests => 9;
use strict;

my $thing = ICanScroll->new;
isa_ok ($thing, 'ICanScroll');

my $scroller = Gtk2::ScrolledWindow->new;
# this will call gtk_widget_set_scroll_adjustments() and attempt to emit
# the set_scroll_adjustments signal.
# this isn't a signal you're supposed to connect to, but we're cheating
# so we can test it.
my $id = $thing->signal_connect (set_scroll_adjustments => sub {
	my ($self, $hadj, $vadj) = @_;
	isa_ok ($thing, 'ICanScroll');
	is ($hadj, $scroller->get_hadjustment, 'got scroller\'s hadj');
	is ($vadj, $scroller->get_vadjustment, 'got scroller\'s vadj');
});
$scroller->add ($thing);

$thing->signal_handler_disconnect ($id);

# this will call gtk_widget_set_scroll_adjustments() again, this time
# with undef for both adjustments.
$thing->signal_connect (set_scroll_adjustments => sub {
	my ($self, $hadj, $vadj) = @_;
	isa_ok ($thing, 'ICanScroll');
	is ($hadj, undef, 'got undef for hadj');
	is ($vadj, undef, 'got undef for vadj');
});
$scroller->destroy;
$scroller = undef;

package ICanScroll;

use strict;
use Test::More;
use Gtk2;
use Glib::Object::Subclass
    Gtk2::HBox::,
    signals => {
	set_scroll_adjustments => {
		param_types => [qw(Gtk2::Adjustment Gtk2::Adjustment)],
		class_closure => sub { ok(1) },
	},
    },
    ;

